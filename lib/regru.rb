module Regru
  require 'domain'
  require 'reg_api2'
  require 'socket'
  
  RegApi2.username = 'Exod'
  RegApi2.password = '1qaz@WSX3edc'
  RegApi2.lang     = 'ru'

  def reg_domain_reg_ru(data)
    zone = data[:domain].split('.').last
    profile_name = 'Exod'
    ru_zones = ['ru','kz', 'рф', 'com.ua']
    if ru_zones.include?(zone) 
      profile_type = 'RU.ORG'
    else
      profile_type = 'GTLD'
    end
  	reg_ru = RegApi2.domain.create(
      enduser_ip: local_ip,
			phone:"+7 777 2828967",
			birth_date:"11.10.1991",
			country:"UK",
			descr:"Push to start",
			domain_name:data[:domain],
      profile_name: profile_name,
      profile_type: profile_type,
			e_mail:"info@exod.co.uk",
			ns0:"ns1.reg.ru",
			ns1:"ns2.reg.ru",
			output_content_type:"plain",
		)
  end

  def set_records(data)
  	action_list = []
	records_list = []
	
	subdomain = '@'
	if !data[:subdomain].nil?
		subdomain = data[:subdomain]
		records_list << {:action=>'add_cname',:type=>'CNAME',:cname=>subdomain, :subdomain=>'@'}
		records_list << {:action=>'add_mx',:type=>'MX',:server=>'mx.yandex.net.', :priority=>'10', :subdomain=>subdomain}
	end
  	records_list << {:action=>'add_cname',:type=>'CNAME',:cname=>data[:cname], :subdomain=>subdomain}
  	records_list << {:action=>'add_mx',:type=>'MX',:server=>'mx.yandex.net.', :priority=>'10', :subdomain=>subdomain}
	
  	records_list.each do |record|
      if record[:type] == 'MX'
  	   action_list << { action: record[:action],
  	  				          record_type: record[:type],
  	  				          priority: record[:priority],
  	  				          content: record[:server],
                        subdomain: record[:subdomain]
  	  				        }
      elsif record[:type] == 'CNAME'
        action_list << { action: record[:action],
                         subdomain: record[:cname],
                         canonical_name: 'mail.yandex.ru.'
                       }
      end

  	end
  	mx_answer = RegApi2.zone.update_records(
  	  domain_name: data[:domain], action_list: action_list
  	)
  end

  def renew_product_reg_ru(data)
    reg_ru = RegApi2.service.renew(
      domain_name: data[:domain],
      period: 1,
    )
  end

  def update_nss_reg_ru(data)
    reg_ru = RegApi2.domain.update_nss(
      dname: data[:domain],
      ns0: data[:ns0],
      ns0ip: data[:ns0ip],
      ns1: data[:ns1],
      ns1ip: data[:ns1ip],
    )
  end

  def ns_zone_clear(data)
    reg_ru = RegApi2.zone.clear(
        domain_name: data[:domain]
    )
  end

  def self.get_domain_prices()
    reg_ru = RegApi2.domain.get_prices(
        currency: 'USD'
    )
  end

  def local_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end

end