module V1
  class Users < Grape::API
	require 'digest/sha1'
	
    resource :user do
  
  
	  desc 'GET /api/v1/users/list'
	  
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
      get '/list' do
	    params = parse_params(@params)
		authorize(params["token"])
		domain_ids = current_user.domain_ids
		email_list = EmailAccount.list(domain_ids)
		{"result" => "success", "message" => email_list}
	  end
	  
	  desc 'GET /api/v1/users/recover'
	  	  params do
		  requires :input_data, type: String
		  optional :device_token, type:String
		  optional :recovery_cellphone, type:String
		end
      get '/recover' do
	    params = parse_params(@params)
		recovery_hash = generate_user_hash
		device_token = ''
		device_token = params['device_token'] unless !params['device_token'].nil?

		#if params['cellphone'] == params['recovery_cellphone']
		  #raise ApiError.new("Recover user failed", "RECOVER_USER_FAILED", {'message' => 'Recovery cellphone and cellphone are similar'})
		#end

		#user = User.where('cellphone = ?', params['cellphone']).first
		#if user 
		  #raise ApiError.new("Recover user failed", "RECOVER_USER_FAILED", {'message' => 'Cellphone is already used'})
		  #user.update_attributes( :recovery_cellphone => params['recovery_cellphone'], :confirmation_hash => Digest::SHA1.hexdigest(recovery_hash), :action => 'recover', :temp_device_token => params['device_token']) 
		#else 
		  #user = User.create(cellphone: params['cellphone'].strip, recovery_cellphone: params['recovery_cellphone'], confirmation_hash: Digest::SHA1.hexdigest(recovery_hash), device_token: device_token, internal_credit: 5000, action: 'recover')
		#end
		#if send_reg_sms(params['recovery_cellphone'], recovery_hash)
			#show_response({"message" =>  "SMS successfully sended"})
		#end
	  end
	  
	  
	  desc 'GET /api/v1/users/belong_to'
	   params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
      get '/belong_to' do
		params = parse_params(@params)
		authorize(params["token"])
		roles = UserToCompanyRole.where('user_id = ? and role_id = ?', current_user["id"], 2)
		data = User.get_belongs(roles)
		{"result" => "success", "message" => data}
	  end


	  desc 'GET /api/v1/users/info'
	  	params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
      get '/info' do
		params = parse_params(@params)
		authorize(params["token"])
		info = current_user.as_json(only: [:id, :name, :cellphone, :email, :user_credential_id, :device_token])
		{"result" => "success", "message" => info}
	  end

	  desc 'GET /api/v1/users/update_info'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :name, type:String
	  end
      get '/update_info' do
		params = parse_params(@params)
		authorize(params["token"])
		if current_user.update_attributes(:name => params['name']) && !params['name'].nil?
		  EmailAccount.where('user_id = ?', current_user.id).update_all(name: params['name'])
		  {"result" => "success", "message" => "User successfully updated"}
		else
		  raise ApiError.new("update user info failed", "UPDATE_USER_FAILED", "user dont exist or name param is empty")  
		end
	  end

	  desc 'GET /api/v1/users/register'
	  
	  format :json

		params do
		  requires :input_data, type: String
		  optional :device_token, type:String
		  optional :cellphone, type:String
		end
	  
	  
      get '/register' do
	    params = parse_params(@params)
		confirmation_hash = generate_user_hash
		device_token = ''
		device_token = params['device_token'] unless !params['device_token'].nil?
		user = User.where('cellphone = ?', params['cellphone']).first_or_create(:cellphone => params['cellphone'].strip, :aasm_state => 'register', :device_token => device_token, :internal_credit => 5000)
		if user.send_sms(confirmation_hash)
			{"result" => "success", "message" => "SMS successfully sended"}
		else 
		  raise ApiError.new("register user failed", "REG_USER_FAILED", user.errors)
		end
	  end

	desc 'GET /api/v1/users/test_cellphone'
      get '/test_cellphone' do
		 params = parse_params(@params)
		authorize(params["token"])
		params = parse_params(@params)
		current_user.set_recovery_cellphone("77789334097")
	  end

	  desc 'GET /api/v1/users/get_recovery_cellphone'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
	  end
      get '/get_recovery_cellphone' do
		 params = parse_params(@params)
		authorize(params["token"])
		params = parse_params(@params)
		if current_user.domains.count > 0 
		  {"result" => "success", "message" => current_user.recovery_cellphone}
		else 
		  raise ApiError.new("Find recovery cellphone failed", "FIND_REC_CELLPHONE_FAILED", "recovery_cellphone not found")
		end
	  end

	  desc 'GET /api/v1/users/confirm'
	  params do
		  requires :input_data, type: String
		  optional :cellphone, type:String
		  optional :confirm_code, type:String
	  end
      get '/confirm' do
	    params = parse_params(@params)
		user = User.where("cellphone = ?", params['cellphone']).first
		raise ApiError.new("Confirm user failed", "USER_CONFIRM_FAILED", "user not exist or already activated") if !user
		user.check_code(params['confirm_code'])
		{"result" => "success", "access_token" => user.authentication_token}
	  end

	  desc 'GET /api/v1/users/update_device'
	  params do
		  requires :input_data, type: String
		  optional :cellphone, type:String
		  optional :confirm_code, type:String
	  end
      get '/update_device' do
		 params = parse_params(@params)
		authorize(params["token"])
		if current_user.update_attribute( :device_token, params['device_token'] ) 
		  {"result" => "success", "message" => "device token updated"}
		else
		  raise ApiError.new("Update device token failed", "UPDATE_DEVICE_TOKEN_FAILED", user.errors)
		end
	  end
	  
	  desc 'GET /api/v1/users/resend_code'
	  	  params do
		  requires :input_data, type: String
		  optional :cellphone, type:String
	  end
      get '/resend_code' do
	    params = parse_params(@params)
		user = User.where("cellphone = ?", params['cellphone']).first
		if user && user.activated? == false
		  confirmation_hash = generate_user_hash
		  if user.send_sms(confirmation_hash)
			{"result" => "success", "message" => "SMS successfully sended"}
		  else 
			raise ApiError.new("register user failed", "REG_USER_FAILED", user.errors)
		  end
		end
	  end
	  
	  #TODO DESTROY IN PRODUCTION
	  desc 'GET /api/v1/users/delete_by_phone'
	  params do
		  requires :input_data, type: String
		  optional :cellphone, type:String
	  end
      get '/delete_by_phone' do
	      user = User.where("cellphone = ?", @params['cellphone']).first
		   user.destroy
		   if user.destroyed?
			 {"result" => "success", "message"=>"User successfully delete"}
		   else
			 raise ApiError.new("Delete user failed", "DEL_DOMAIN_FAILED", user.errors)
		   end
	  end

	  desc 'GET /api/v1/users/to_balance'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :amount, type:String
	  end
      get '/to_balance' do
	    params = parse_params(@params)
		authorize(params["token"])
		current_user.to_credit(params['amount'].to_f)
		{"result" => "success", "message" => "Balance successfully added"}
	  end

	  desc 'GET /api/v1/users/balance'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
	  end
      get '/balance' do
	    params = parse_params(@params)
		authorize(params["token"])
		authorize! :update, @info
		show_response(current_user.internal_credit)
		{"result" => "success", "message" => "Balance successfully added"}
	  end

	  desc 'GET /api/v1/users/get_subscriptions'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
	  end
      get '/get_subscriptions' do
	    authorize
	    params = parse_params(@params)
		{"result" => "success", "message" => current_user.billing_subscriptions.as_json(only: [:id, :type_of, :subscription_date, :previous_billing_date, :next_billing_date])}
	  end

	  desc 'GET /api/v1/users/get_cost_subscription'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
	  end
      get '/get_cost_subscription' do
		params = parse_params(@params)
		authorize(params["token"])
		subscription = current_user.billing_subscription.find(params['subscription_id'])
		domain = Domain.find(subscription.domain)
		{"result" => "success", "message" => current_user.get_full_amount(subscription.type_of, domain)}
	  end

	  desc 'GET /api/v1/users/bill_subscription'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :id, type:Integer
	  end
      get '/bill_subscription' do
		 params = parse_params(@params)
		authorize(params["token"])
		subscription = current_user.billing_subscription.where('id = ?', params['id']).first
		subscription.bill
		{"result" => "success", "message" => "successfully added payment"}
	  end

	  desc 'GET /api/v1/users/check_phone'
      get '/check_phone' do
	  params = parse_params(@params)
		GlobalPhone.db_path = Rails.root.join('db/global_phone.json')

		phone = "+" + params['cellphone']
		number = GlobalPhone.parse(phone)
		
		#show_response({"valid"=>GlobalPhone.validate(phone), "territory" => number.territory.name})
	  end

	  desc 'GET /api/v1/users/test_push_ios'
      get '/test_push_ios' do
		authorize
		send_ios_notify(current_user.device_token, 'Hello iPhone!')
	  end

	  desc 'GET /api/v1/users/test_push_android'
      get '/test_push_android' do
		authorize
		send_android_notify(current_user.device_token, {:hello => "world"})
	  end

    end
  end
end


