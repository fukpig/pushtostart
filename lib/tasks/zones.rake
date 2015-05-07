namespace :zones do
  desc "Rake task to get events data"
  task :fetch_reg_ru => :environment do
    require 'reg_api2'
  require 'socket'

  RegApi2.username = 'Exod'
  RegApi2.password = '1qaz@WSX3edc'
  RegApi2.lang     = 'ru'   


  PsConfigZones.where.not(name: 'pushtostart.ru').delete_all
	zones = reg_ru = RegApi2.domain.get_prices(
      currency: 'USD'
       )
  option = PsConfig.where('name = ?', 'domain_price').first

	zones.prices.keys.each do |zone|
    ps_price = orig_price.to_f + ((orig_price.to_f / 100)*option.value.to_f)
		zone = PsConfigZones.new(name: zone, orig_price: zones.prices[zone].reg_price, ps_price: ps_price, years: zones.prices[zone].reg_min_period)
		zone.save
	end
	
	puts "#{Time.now} - Success!"
  end
end