# == Schema Information
#
# Table name: shortened_urls
#
#  id        :bigint           not null, primary key
#  long_url  :string           not null
#  short_url :string           not null
#  user_id   :bigint           not null
#
class ShortenedUrl < ApplicationRecord
    validates :short_url, presence: true, uniqueness: true
    validates :user_id, presence: true
    validates :long_url, presence: true

    def self.random_code
        code = SecureRandom.urlsafe_base64

        until !ShortenedUrl.exists?(short_url:code)
            code = SecureRandom.urlsafe_base64
        end

        return code
    end

    after_initialize do
        if self.new_record?
            self.generate_short_url
        end
    end

    private

    def generate_short_url
        self.short_url ||= ShortenedUrl.random_code
    end
end
