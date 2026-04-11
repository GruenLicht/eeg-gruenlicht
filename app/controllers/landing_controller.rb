class LandingController < ApplicationController
  def start
    @contact_request = ContactRequest.new
  end

  def create_kontakt
      @contact_request = ContactRequest.new(contact_request_params)

      if @contact_request.honeypot.present?
          Rails.logger.warn "ContactRequest spam blocked (honeypot): #{request.remote_ip}"

          render turbo_stream: turbo_stream.replace(
              "kontaktformular",
              partial: "landing/kontaktformular",
              locals: {
                  contact_request: ContactRequest.new,
                  flash_message: "Vielen Dank. Ihre Nachricht wurde übermittelt."
              }
          )
          return
      end

      subject   = "[EEG Website Kontakt] #{@contact_request.name}"
      text_body = <<~TEXT
          Name: #{@contact_request.name}
          E-Mail: #{@contact_request.email}

          Nachricht:
          #{@contact_request.message}
      TEXT

      mail = Mail.new
      mail.from    = ENV["NO_REPLY_EMAIL"] || "office@eeg-gruenlicht.at"
      mail.to      = ENV["CONTACT_EMAIL"] || "office@eeg-gruenlicht.at"
      mail.subject = subject
      mail.text_part = Mail::Part.new do
          content_type "text/plain; charset=UTF-8"
          body text_body
      end

      method   = ActionMailer::Base.delivery_method
      settings = ActionMailer::Base.public_send("#{method}_settings")
      mail.delivery_method(method, settings)
      mail.deliver!

      render turbo_stream: turbo_stream.replace(
          "kontaktformular",
          partial: "landing/kontaktformular",
          locals: {
              contact_request: ContactRequest.new,
              flash_message: "Vielen Dank. Ihre Nachricht wurde erfolgreich gesendet."
          }
      )
  end
  def unterstuetzer
  end

  def impressum
  end

  def datenschutz
  end

  private

  def contact_request_params
      params.require(:contact_request).permit(:name, :email, :message, :honeypot)
  end
end
