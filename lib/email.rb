require 'mail'
Mail.defaults do
  retriever_method :imap, :address    => "imap.yandex.ru",
                          :port       => 993,
                          :user_name  => 'rinat@convapp.com',
                          :password   => '1qaz2wsx3edc',
                          :enable_ssl => true
end

mails = Mail.all

mails.each do |mail|
  uri =  mail.body.decoded.scan(/<a[^>]* href="http:\/\/([^"]*)"/)
  if !uri.first.nil?
   if Email.where('message_id = ?', mail.message_id).nil?
    uri = 'http' +  uri.first.first
      if open(uri) 
	Email.create(message_id: mail.message_id)
      end
   end
  end
end