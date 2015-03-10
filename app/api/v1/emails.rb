module V1
  class Emails < Grape::API
  require 'yandex'
  #include ActionController::Live
    resource :email do
	
	 desc 'GET /api/v1/emails/info'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domains_id, type:Integer
		  optional :email_id, type:Integer
		end
      get '/info' do
    params = parse_params(params)
		authorize(params["token"])
	domain = current_user.domains.where(["id = ?", params['domain_id']]).first
    raise ApiError.new("find email failed", "SHOW_EMAIL_FAILED", "domain not found") if domain.nil?
    if EmailAccount.where(["id = ?", params['email_id']]).present?
      email = EmailAccount.find( params['email_id'])
	  {"result" => "success", "message" => email.as_json(only: [:id, :email])}
    else
      raise ApiError.new("find email failed", "SHOW_EMAIL_FAILED", "no such email")
    end
  end

   desc 'GET /api/v1/emails/create'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :mail, type:String
		  optional :name, type:String
		  optional :invite_cellphone, type:String
		  optional :interval, type:Integer
		end
      get '/create' do
    params = parse_params(params)
		authorize(params["token"])
    EmailAccount.transaction do
      current_user.check_balance(5)
      info = EmailAccount.split_email(params['mail'])
      domain = current_user.domains.where('domain = ?', info['domain']).first
      email = EmailAccount.create_email(current_user, domain['id'], info['email_name'], 'user', params['name'])
      #YANDEX
        #pdd = init_pdd
        #password = Array.new(10){[*"A".."Z", *"0".."9"].sample}.join
        #pdd.email_create(domain['domain'], info['email_name'], password)
      #YANDEX

      #SEND INVITE

       data = {'user_id'   =>current_user['id'], 
			   'cellphone' => params['invite_cellphone'], 
			   'domain_id' => domain['id'], 
			   'email_id'  => email['id'], 
			   'name' => params['name']}
       Invite.create_invite(data)
		
      #SEND INVITE

      interval = 1
      interval = params['interval'].to_i unless params['interval'].nil?
      current_user.pay_email(domain.id, interval)
	  {"result" => "success", "message" => email.as_json(only: [:id, :email])}
    end
  end

  desc 'GET /api/v1/emails/delete'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		end
      get '/delete' do
    params = parse_params(params)
		authorize(params["token"])
    email = EmailAccount.where(["email = ?", params['email']]).first
    raise ApiError.new("Delete email failed", "DEL_EMAIL_FAILED", "no such email") if email.nil?
    
	email.destroy
    if email.destroyed?
         #YANDEX
         data = EmailAccount.split_email(params['email'])
         #pdd = init_pdd()
         #pdd.email_delete(data['domain'], data['email_name'])
         #YANDEX
      {"result" => "success", "message" => "email successfully delete"}
    else
      raise ApiError.new("Delete email failed", "DEL_EMAIL_FAILED", email.errors)
    end

  end

    desc 'GET /api/v1/emails/check'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		  optional :firstname, type:String
		  optional :cellphone, type:String
		end
      get '/check' do
   params = parse_params(params)
		authorize(params["token"])
    email = EmailAccount.where("email = ?", params['email'].downcase).first
    if !email
	  {"result" => "success", "message" => "Email available"}
    else
      info = EmailAccount.split_email(params['email'].downcase)
      data = {:firstname => params["firstname"], :phone => params["cellphone"], :domain => info["domain"], :email => info["email_name"]}
      emails = generate_email(data)
      raise ApiError.new("email not available", "CHECK_EMAIL_FAILED", {"message" => emails})
    end
  end

      desc 'GET /api/v1/emails/hold_to_admin'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		end
      get '/hold_to_admin' do
     params = parse_params(params)
		authorize(params["token"])
     email = EmailAccount.where('email = ?', params["email"]).first
	 domain = current_user.domains.where('id =?', email.domain_id).first
     raise ApiError.new("email not available", "CHECK_EMAIL_FAILED", {"message" => emails}) if domain.nil?
     
	 if email.update_attribute(user_id: current_user.id)
		{"result" => "success", "message" => "Ok"}
	 end
  end

        desc 'GET /api/v1/emails/enable'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		end
      get '/enable' do
    params = parse_params(params)
		authorize(params["token"])
    email = current_user.email_accounts.where(["email = ?", params['email']]).first
    raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", "no such email") if email.nil?
    if email.update_attributes(is_enabled: true)
	  {"result" => "success", "message" => "email successfully enabled"}
    else
      raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", email.errors)
    end
  end

    desc 'GET /api/v1/emails/disable'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		end
      get '/disable' do
	  params = parse_params(params)
		authorize(params["token"])
    email = current_user.email_accounts.where(["email = ?", params['email']]).first
    raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", "no such email") if email.nil?
    if email.update_attributes(is_enabled: false)
	  {"result" => "success", "message" => "email successfully disabled"}
    else
      raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", email.errors)
    end
  end

     desc 'GET /api/v1/emails/change_password'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		end
      get '/change_password' do
		  params = parse_params(params)
			authorize(params["token"])
		email = current_user.email_accounts.where(["email = ?", params['email']]).first
		raise ApiError.new("change password failed", "CHANGE_PASSWORD_FAILED", "no such email") if email.nil?
		if Yandex.updatepassword
		  {"result" => "success", "message" => "password successfully changed"}
		else
		  raise ApiError.new("change password failed", "CHANGE_PASSWORD_FAILED", email.errors)
		end
	end
  
  
       desc 'GET /api/v1/emails/get_email_price'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
      get '/get_email_price' do
		params = parse_params(params)
		authorize(params["token"])
		{"result" => "success", "message" => {'per_day' => EmailAccount.amount_per_day, 'full_month' => 5}}
		end
   end
  end
end
