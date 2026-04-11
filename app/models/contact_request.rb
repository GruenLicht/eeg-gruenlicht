class ContactRequest
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :email, :string
    attribute :message, :string
    attribute :honeypot, :string

    validates :name, presence: true
    validates :email, presence: true
    validates :message, presence: true
end