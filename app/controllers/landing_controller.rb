class LandingController < ApplicationController
  def start
    @contact_request = ContactRequest.new
  end

  def create_kontakt
      @contact_request = ContactRequest.new(contact_request_params)

      if @contact_request.honeypot.present?
          Rails.logger.warn "ContactRequest spam blocked (honeypot): #{request.remote_ip}"
          render_kontaktformular(
              contact_request: ContactRequest.new,
              flash_message: "Vielen Dank. Ihre Nachricht wurde übermittelt."
          )
          return
      end

      unless @contact_request.valid?
          render_kontaktformular(contact_request: @contact_request)
          return
      end

      begin
          deliver_contact_mail(@contact_request)
      rescue StandardError => e
          Rails.logger.error "ContactRequest delivery failed: #{e.class}: #{e.message.to_s.strip}"
          render_kontaktformular(
              contact_request: @contact_request,
              error_message: "Ihre Nachricht konnte leider nicht gesendet werden. " \
                             "Bitte versuchen Sie es später noch einmal oder schreiben Sie uns direkt an " \
                             "#{contact_email}."
          )
          return
      end

      render_kontaktformular(
          contact_request: ContactRequest.new,
          flash_message: "Vielen Dank. Ihre Nachricht wurde erfolgreich gesendet."
      )
  end
  
  def preise; end
  
  def unterstuetzer; end

  def impressum; end

  def datenschutz; end

  def datenloeschung; end

  def sitemap; end

  private

  def render_kontaktformular(contact_request:, flash_message: nil, error_message: nil)
      render turbo_stream: turbo_stream.replace(
          "kontaktformular",
          partial: "landing/kontaktformular",
          locals: {
              contact_request: contact_request,
              flash_message: flash_message,
              error_message: error_message
          }
      )
  end

  def contact_email
      ENV["CONTACT_EMAIL"].presence || "office@eeg-gruenlicht.at"
  end

  def deliver_contact_mail(contact_request)
      text_body = <<~TEXT
          Name: #{contact_request.name}
          E-Mail: #{contact_request.email}

          Zustimmung Datenschutz:
          Ja, die Datenschutzerklärung wurde akzeptiert.

          Nachricht:
          #{contact_request.message}
      TEXT

      mail = Mail.new
      mail.from    = ENV["NO_REPLY_EMAIL"].presence || "office@eeg-gruenlicht.at"
      mail.to      = contact_email
      mail.subject = "[EEG Website Kontakt] #{contact_request.name.to_s.squish}"
      reply_to = reply_to_address(contact_request)
      mail.reply_to = reply_to if reply_to
      mail.text_part = Mail::Part.new do
          content_type "text/plain; charset=UTF-8"
          body text_body
      end

      method   = ActionMailer::Base.delivery_method
      settings = ActionMailer::Base.public_send("#{method}_settings")
      mail.delivery_method(method, settings)
      mail.deliver!
  end

  def reply_to_address(contact_request)
      email = contact_request.email.to_s.strip
      return nil unless email.match?(URI::MailTo::EMAIL_REGEXP)

      address = Mail::Address.new(email)
      address.display_name = contact_request.name.to_s.squish.presence
      address.format
  rescue Mail::Field::ParseError
      nil
  end

  def contact_request_params
      params.require(:contact_request).permit(
          :name,
          :email,
          :message,
          :privacy_consent,
          :honeypot
      )
  end
end