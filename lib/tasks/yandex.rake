namespace :yandex do
  desc "Rake task to get events data"
  task :cron => :environment do
    	require 'yandex'
      pdd = Yandex::PDD::new
    	crons = YandexCron.all
    	crons.each do |cron|
        begin
          email = EmailAccount.where('email = ?', cron['email'])
          password = Array.new(10){[*"A".."Z", *"0".."9"].sample}.join
      	  result = pdd.email_create(cron['domain'], cron['email'], password)
       	  if result["success"] == "ok"
             pdd.email_verify(cron['domain'], email.email)
             email.activate_yandex(password)
             cron.destroy! 
             puts "#{cron['email']}@#{cron['domain']} succefully created"
          end
        rescue => e
          puts "#{cron['email']}@#{cron['domain']} not yet delegated"
          next
        end
    	end

	
	puts "#{Time.now} - Success!"
  end
end