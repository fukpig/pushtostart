module V1
  class Domains < Grape::API
  require 'yandex'
  #include ActionController::Live
  resource :domain do

	  desc 'GET /api/v1/domain/list'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
    get '/list' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  {"result" => "success", "data" => Domain.list(current_user)}
	  end

	  desc 'GET /api/v1/domain/get_zones_list'
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
		  {"result" => "success", "data" => info.as_json(only: [ :name])}
	  end
	  
	  desc 'GET /api/v1/domain/info'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domain_id, type:Integer
	  end
    get '/info' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  domain = current_user.domains.find( params['domain_id'])
		  {"result" => "success", "data" => domain.as_json(only: [:id, :domain, :registration_date, :expiry_date, :status])}
	  end


	  desc 'GET /api/v1/domain/create'
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
			  {"result" => "success", "data" => domain.as_json(only: [:id, :domain, :registration_date, :expiry_date, :status, :ns_list])}
		  else 
		    raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", 'errors')
		  end
	  end

	  desc 'GET /api/v1/domain/delegate'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :cellphone, type:String
		  optional :domain, type:String
	  end
    get '/delegate' do
		  params = parse_params(@params)
		  authorize(params["token"])

		  domain = current_user.domains.where('domain = ?', params['domain']).first
			raise ApiError.new("Delegate failed", "CREATE_DELEGATE_FAILED", {"message" => 'no such domain'}) if domain.nil?
			delegate = DelegatedDomain.where('cellphone = ? and domain_id = ?', params['cellphone'], domain.id).first
			raise ApiError.new("Delegate failed", "CREATE_DELEGATE_FAILED", {"message" => 'invite exist'}) if !delegate.nil?		

			user = User.where('cellphone = ?', params['cellphone']).first

			data = {'user_id'=>current_user['id'], 'cellphone' => params['cellphone'], 'domain_id' => domain['id']}
			result = DelegatedDomain.delegate(data)
			{"result" => "success", "data" => result}
	  end

	  desc 'GET /api/v1/domain/delegated_domains_list'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
	  end
    get '/delegated_domains_list' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  list = Domain.get_invite_domains(current_user, 'domains')
		  {"result" => "success", "data" => list}
	  end

	  desc 'GET /api/v1/domain/delegate_accept'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :id, type:String
	  end
    get '/delegate_accept' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  delegate = DelegatedDomain.get_delegate_invite(current_user.cellphone, params["id"])
		
		  if delegate.accept
			  domain = Domain.find(delegate.domain_id)
			  domain.change_owner(current_user.id)
			  EmailAccount.change_owner(domain.id)
			  {"result" => "success", "data" => { "message" => "Delegate successfully accept"}}
		  else 
  			raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", delegate.errors)
		  end
	  end

    desc 'GET /api/v1/domain/delegate_reject'
    params do
	    requires :input_data, type: String
		  optional :token, type:String
		  optional :id, type:String
	  end
    get '/delegate_reject' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  delegate = DelegatedDomain.get_delegate_invite(current_user.cellphone, params["id"])
		  delegate.destroy!
		  if delegate.destroyed?
  		  {"result" => "success", "data" => { "message" => "Delegate successfully reject"}}
		  else 
  		  raise ApiError.new("Reject invite failed", "REJECT_INVITE_FAILED", delegate.errors)
		  end
	  end

    desc 'GET /api/v1/domain/check_available'
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
				  																	use_hyphen: "1")
				{"result" => "success", "data" => {"available"=>result.available?, "choice" => reg_ru}}
			else 
		    {"result" => "success", "data" => {"available"=>result.available?}}
			end
	  end
	  
	  desc 'GET /api/v1/domain/get_register_price'
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
			if !price.nil?
			  {"result" => "success", "data" => price}
			else
			  raise ApiError.new("reg.ru variants", "reg.ru variants", {"message" => Domain.get_variants(domain)})
			end
	  end
	  end
	end
end
