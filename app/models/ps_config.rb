class PsConfig < ActiveRecord::Base
  def self.email_price
    config = PsConfig.where('name = ?', 'email_price').first
     email_price = config.value.to_f
  end
end
