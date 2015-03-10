module V1
  class Domains < Grape::API
  require 'yandex'
  #include ActionController::Live
    resource :domain do
	
	  desc 'GET /api/v1/domains/list'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
      get '/list' do
		params = parse_params(@params)
		authorize(params["token"])
		show_response(Domain.list(current_user))
		{"result" => "success", "message" => Domain.list(current_user)}
	  end

	  desc 'GET /api/v1/domains/get_zones_list'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
	  end
      get '/get_zones_list' do
		params = parse_params(@params)
		authorize(params["token"])
		zones = [ "ru", "kz", "com", "net", "info", "su", "org", "com.ua"]
		info = Array.new
		info << {:name => "pushtostart.ru"}
		PsConfigZones.all.each do |zone|
		  info << zone if zones.include?(zone.name)
		end
		{"result" => "success", "message" => info.as_json(only: [ :name])}
	  end
	  
	  desc 'GET /api/v1/domains/info'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domain_id, type:Integer
	  end
      get '/info' do
		params = parse_params(@params)
		authorize(params["token"])
		#TO-DO
		domain = current_user.domains.find( params['domain_id'])
		{"result" => "success", "message" => domain.as_json(only: [:id, :domain, :registration_date, :expiry_date, :status])}
	  end


	   desc 'GET /api/v1/domains/create'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domain, type:String
		  optional :cellphone, type:String
	  end
      get '/create' do
		 params = parse_params(@params)
		 authorize(params["token"])
		 info = EmailAccount.split_email(params['domain'])
		  current_user.set_recovery_cellphone(params['cellphone'])
		  domain = Domain.register(current_user, info)
		  if !domain.nil?
			{"result" => "success", "message" => domain.as_json(only: [:id, :domain, :registration_date, :expiry_date, :status, :ns_list])}
		  else 
		  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", 'errors')
		  end
	  end

	  #def delete
		# params = parse_params(@params)
		#authorize(params["token"])
		#check_owner
		
		#domain = Domain.find(params['domain_id'])
		#domain.destroy
		#if domain.destroyed?
			 # show_response({"message"=>"domain successfully delete"})
		#else
		  #raise ApiError.new("Delete domain failed", "DEL_DOMAIN_FAILED", domain.errors)
		#end
	  #end


	  desc 'GET /api/v1/domains/delegate'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :to, type:String
	  end
      get '/delegate' do
		 params = parse_params(@params)
		authorize(params["token"])
		#check_owner(params["domain_id"])
		
		data = {'domain_id'=>current_user['id'], 'from' => current_user["id"], 'to' => params['to']}
		result = DelegatedDomain.delegate(data)
		show_response(result)
	  end

	  desc 'GET /api/v1/domains/delegated_domain_to_me'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
	  end
      get '/delegated_domain_to_me' do
		 params = parse_params(@params)
		authorize(params["token"])
		list = Domain.get_invite_domains(current_user, 'domains')
		{"result" => "success", "message" => list}
	  end

	  desc 'GET /api/v1/domains/accept'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domain, type:String
	  end
      get '/accept' do
		params = parse_params(@params)
		authorize(params["token"])
		delegate = DelegatedDomain.get_delegate_invite(user_id, params["domain"])
		
		if delegate.accept
			domain = Domain.find(delegate.domain_id)
			domain.change_owner(current_user.id)
			EmailAccount.change_owner(domain.id)
			{"result" => "success", "message" => "successfully added to company"}
		else 
			raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", delegate.errors)
		end
	  end

	   desc 'GET /api/v1/domains/reject'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domain, type:String
	  end
      get '/reject' do
		params = parse_params(@params)
		authorize(params["token"])
		delegate = DelegatedDomain.get_delegate_invite(user_id, params["domain"])
		if delegate.destroyed?
		  {"result" => "success", "message" => "Delegate successfully reject"}
		else 
		  raise ApiError.new("Reject invite failed", "REJECT_INVITE_FAILED", delegate.errors)
		end
	  end


	  	   desc 'GET /api/v1/domains/check_available'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domain, type:String
	  end
      get '/check_available' do
	     params = parse_params(@params)
		authorize(params["token"])
		result = Domain.whois(params['domain'])
		if result.available? == false
			info = Domain.parse_domain(params['domain'])
			reg_ru = RegApi2.domain.get_suggest(word: info['domain_word'],
				use_hyphen: "1"
			)
			{"result" => "success", "message" => {"available"=>result.available?, "choice" => reg_ru}}
		else 
		    {"result" => "success", "message" => {"available"=>result.available?}}
		end
	  end
	  
	   desc 'GET /api/v1/domains/get_register_price'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domain, type:String
	  end
      get '/get_register_price' do
		params = parse_params(@params)
		authorize(params["token"])
		
		domain = SimpleIDN.to_ascii(params['domain'])
		price = Domain.get_price(domain)
		if !price["domain_price"].nil?
		{"result" => "success", "message" => price}
		else 
		  raise ApiError.new("domain is not available", "CHECK_DOMAIN_FAILED", {"message" => Domain.get_variants(domain)})
		end
	  end

	  end
	end
end
