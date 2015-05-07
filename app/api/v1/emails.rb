module V1
  class Emails < Grape::API
  #include ActionController::Live
    resource :email do

  	desc 'GET /api/v1/emails/info'
  	params do
  	  requires :input_data, type: String
  		optional :token, type:String
  		optional :email, type:String
  	end
    get '/get_info' do
      params = parse_params(@params)
      authorize(params["token"])
      email = current_user.email_accounts.where('email = ?', params["email"]).first
      raise ApiError.new("email not available", "CHECK_EMAIL_FAILED", {"message" => 'no such email'}) if email.nil?
      info = email.info(current_user.id)
      {"result" => "success", "data" => info}
    end

    desc 'GET /api/v1/emails/get_password'
    params do
      requires :input_data, type: String
      optional :token, type:String
      optional :email, type:String
    end
    get '/get_password' do
      params = parse_params(@params)
      authorize(params["token"])
      email = current_user.email_accounts.where('email = ?', params["email"]).first
      raise ApiError.new("email not available", "CHECK_EMAIL_FAILED", {"message" => 'no such email'}) if email.nil?
       
      info = EmailAccount.split_email(params['email']) 
      pdd = init_pdd
      password = Array.new(10){[*"A".."Z", *"0".."9"].sample}.join
      pdd.email_password(info['domain'], info['email_name'], password)
      if current_user.send_sms("#{params["email"]} password: #{password}")
        {"result" => "success", "data" => {"message" => "SMS successfully sended"}}
      end
    end

                #YANDEX
              #pdd = init_pdd
              #password = Array.new(10){[*"A".."Z", *"0".."9"].sample}.join
              #pdd.email_create(domain['domain'], info['email_name'], password)
            #YANDEX

            #SEND INVITE



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
      params = parse_params(@params)
      authorize(params["token"])
      EmailAccount.transaction do
        current_user.check_balance(PsConfig.email_price)
        info = EmailAccount.split_email(params['mail'])
        domain = current_user.domains.where('domain = ?', info['domain']).first
        email = EmailAccount.create_email(current_user, domain['id'], info['email_name'], 'user', params['name'])
        data = {'user_id'   =>current_user['id'], 
      	 		    'cellphone' => params['invite_cellphone'], 
      			    'domain_id' => domain['id'], 
      			    'email_id'  => email['id'], 
      			    'name' => params['name']}
        Invite.create_invite(data)
      	interval = params['interval'].nil? ? 1 : params['interval'].to_i
        current_user.pay_email(domain.id, interval)
      	{"result" => "success", "data" => email.as_json(only: [:id, :email])}
      end
    end

    desc 'GET /api/v1/emails/delete'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		end
    get '/delete' do
      params = parse_params(@params)
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
        {"result" => "success", "data" => {"message" => "email successfully delete"}}
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
      params = parse_params(@params)
  		authorize(params["token"])
      email = EmailAccount.where("email = ?", params['email'].downcase).first
      if !email
  	    {"result" => "success", "data" => {"message" => "Email available"}}
      else
        info = EmailAccount.split_email(params['email'].downcase)
        data = {:firstname => params["firstname"], :phone => params["cellphone"], :domain => info["domain"], :email => info["email_name"]}
        emails = EmailAccount.generate_email(data)
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
      params = parse_params(@params)
		  authorize(params["token"])
      email = EmailAccount.where('email = ?', params["email"]).first
	    domain = current_user.domains.where('id =?', email.domain_id).first
      raise ApiError.new("email not available", "CHECK_EMAIL_FAILED", {"message" => emails}) if domain.nil?
     
	    if email.update_attributes(:user_id => current_user.id)
		    {"result" => "success", "data" => {"message" => "Ok"}}
	    end
    end

    desc 'GET /api/v1/emails/enable'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		end
    get '/enable' do
      params = parse_params(@params)
  		authorize(params["token"])
      email = current_user.email_accounts.where(["email = ?", params['email']]).first
      raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", "no such email") if email.nil?
      if email.update_attributes(is_enabled: true)
  	  {"result" => "success", "data" => {"message" => "email successfully enabled"}}
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
  	  params = parse_params(@params)
  		authorize(params["token"])
      email = current_user.email_accounts.where(["email = ?", params['email']]).first
      raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", "no such email") if email.nil?
      if email.update_attributes(is_enabled: false)
  	  {"result" => "success", "data" => {"message" => "email successfully disabled"}}
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
		  params = parse_params(@params)
			authorize(params["token"])
      password = "#{SecureRandom.urlsafe_base64}"
  		email = current_user.email_accounts.where(["email = ?", params['email']]).first
      filename = EmailAccount.generate_mobileconfig(email.email, password)
      {"result" => "success", "data" => {"filename" => filename}}
  		#raise ApiError.new("change password failed", "CHANGE_PASSWORD_FAILED", "no such email") if email.nil?
  		#if Yandex.updatepassword
  		  #{"result" => "success", "data" => {"message" => "password successfully changed"}}
  		#else
  		  #raise ApiError.new("change password failed", "CHANGE_PASSWORD_FAILED", email.errors)
  		#end
	  end

    desc 'GET /api/v1/emails/get_email_price'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
    get '/get_email_price' do
    	params = parse_params(@params)
    	authorize(params["token"])
      {"result" => "success", "data" => {'per_day' => EmailAccount.amount_per_day, 'full_month' => PsConfig.email_price}}
		end
   end
  end
end
