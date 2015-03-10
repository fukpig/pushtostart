ActiveAdmin.register PsConfigZones do
  menu :parent => "Настройки", :label => "Настройки доменных зон"
  
  config.filters = false
  config.paginate = false
  config.sort_order = "name_asc"
  
  permit_params do
    params = [:name, :orig_price, :ps_price, :years]
    params
  end
 
 action_item do
   link_to "Get data from REG.RU", '#', :class => "reg_ru"
 end 
 
  index do  
    column "Доменная зона",:name
    column "Цена у reg.ru", :orig_price
    column "Цена в PS", :ps_price
    column "Минимальное количество лет регистрации",:years
  end
  
  collection_action :reg_ru, :method => :get do
	  @zones = get_domain_prices
      render "zones_list", :layout => false
  end
  
  collection_action :save_zones, :method => :post do
	if !params["zones"].nil?
		PsConfigZones.delete_all
		params["zones"].each do |zone|
			zone = PsConfigZones.new(name: zone[0].tr("'", ""), orig_price: zone[1]["regru_price"], ps_price: zone[1]["ps_price"], years: zone[1]["year"].to_i)
			zone.save
		end
	end
	redirect_to admin_ps_config_zones_path
  end
end
