module V1
  class Users < Grape::API
	require 'digest/sha1'
	
    resource :user do
  
		desc 'POST /api/v1/user/upload_avatar'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :image, type:String
		end
		post '/upload_avatar' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  image = params['image'].gsub("\\\\", "").tr(" ","+")
		  avatar = current_user.decode_image_data(image)
		  if !avatar.nil? 
		    {"result" => "success", "data" => {"message" => current_user.avatar.url}}
		  else
		    raise ApiError.new("Upload error", "Upload error", "Try later")  
		  end
		end

		desc 'GET /api/v1/user/history'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	 	 get '/history' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  info = current_user.history
		  {"result" => "success", "data" => info.sort_by{|e| e[:created_at]}}
		end

	  desc 'GET /api/v1/user/get_avatar_by_email'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :email, type:String
		end
	  get '/get_avatar_by_email' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  email = EmailAccount.where('email = ?', params["email"]).first
		  if !email.nil?
		    user = User.find(email.user_id)
			  {"result" => "success", "data" => {"message" => user.avatar.url}}
		  else 
		    raise ApiError.new("No such email", "No such email", "No such email")  
		  end
		end

	 	desc 'GET /api/v1/user/get_my_avatar'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	  get '/get_my_avatar' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  {"result" => "success", "data" => {"message" => current_user.avatar.url}}
		end

		desc 'GET /api/v1/user/list'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	    get '/list' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  email_list = current_user.email_list
		  {"result" => "success", "data" => email_list}
		end


		desc 'GET /api/v1/domain/all_services'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :domain, type:String
	  	end
    	get '/all_services' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  #domain = Domain.where(["domain = ?", params["domain"]]).first
		  info = Hash.new
		  current_user.domains.each do |domain|
  		  subscription = current_user.billing_subscriptions.where('domain= ? and type_of=?', domain.id.to_s, 'email').first
		    billing_date = subscription.nil? ? '' : subscription.next_billing_date
		    info[domain.domain] = {'one_mailbox_month_price'         => PsConfig.email_price, 
		  		  'one_mailbox_year_price'          => PsConfig.email_price*12,
		  		  'all_mailboxes_in_month'          => Domain.get_domains_emails_count(current_user.domains)*PsConfig.email_price,
		  		  'all_mailboxes_next_billing_date' => billing_date,
		  		  'mine_mailboxes_year_price' 	 	=> current_user.email_accounts.count*PsConfig.email_price,
		  		  'mine_first_mailbox'				=> current_user.email_accounts.first.created_at.strftime('%F'),
		  		  'mine_last_mailbox'				=> current_user.email_accounts.last.created_at.strftime('%F'),
		  		  'mine_mailboxes_next_billing_date'=> billing_date
		  		}
		  end
		    {"result" => "success", "data" => info}
	  	end
		  
		desc 'GET /api/v1/user/recover'
		params do
		  requires :input_data, type: String
		  optional :device_token, type:String
		  optional :recovery_cellphone, type:String
		  optional :cellphone, type:String
		end
	  get '/recover' do
		  params = parse_params(@params)
		  recovery_hash = generate_user_hash
		  confirmation_hash = generate_user_hash
		  device_token = params['device_token'].nil? ? '' : params['device_token']
		  
		  User.check_cellphone(params)
		  user = User.recover_user(params)
		  if user.send_sms("Your recovery code:#{recovery_hash}", params['recovery_cellphone']) && user.send_sms("Your confirmation code:#{confirmation_hash}")
		    {"result" => "success", "data" => {"message" =>  "SMS successfully sended"}}
		  end
		end
		  
		desc 'GET /api/v1/user/belong_to'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	  get '/belong_to' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  roles = UserToCompanyRole.where('user_id = ? and role_id = ?', current_user["id"], 2)
		  data = User.get_belongs(roles)
		  {"result" => "success", "data" =>data}
		end

    desc 'GET /api/v1/user/info'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	  get '/info' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  user_info = current_user.user_info 
		  info = {"name" => current_user.name, "cellphone" => current_user.cellphone, "emails" => current_user.email_accounts, "domains" => user_info['domains'].uniq, "groups" => user_info['groups'].uniq}
		  {"result" => "success", "data" => info}
		end

		desc 'GET /api/v1/user/update_info'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :name, type:String
		end
	  get '/update_info' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  if current_user.update_attributes(:name => params['name']) && !params['name'].nil?
		  	current_user.update_emails(params['name'])
		    {"result" => "success", "data" => {"message" => "User successfully updated"}}
		  else
		    raise ApiError.new("update user info failed", "UPDATE_USER_FAILED", "user dont exist or name param is empty")  
		  end
		end

		desc 'GET /api/v1/user/register'
		format :json
		params do
	      requires :input_data, type: String
		  optional :device_token, type:String
		  optional :cellphone, type:String
		end
		get '/register' do
		  params = parse_params(@params)
		  confirmation_hash = generate_user_hash
		  device_token = params['device_token'].nil? ? '' : params['device_token']
		  user = User.where('cellphone = ?', params['cellphone']).first_or_create!(:cellphone => params['cellphone'].strip.tr("+", ""), :device_token => device_token, :internal_credit => 5000)
		  if user.send_sms("Your confirmation code:#{confirmation_hash}")
			  user.update_attribute(:confirmation_hash, Digest::SHA1.hexdigest(confirmation_hash))
			  {"result" => "success", "data" => {"message" => "SMS successfully sended"}}
		  else 
		    raise ApiError.new("register user failed", "REG_USER_FAILED", user.errors)
		  end
		end

		desc 'GET /api/v1/user/get_recovery_cellphone'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	  get '/get_recovery_cellphone' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  params = parse_params(@params)
		  if current_user.domains.count > 0 
		    {"result" => "success", "data" => {"recovery_cellphone" =>current_user.recovery_cellphone}}
		  else 
		    raise ApiError.new("Find recovery cellphone failed", "FIND_REC_CELLPHONE_FAILED", "recovery_cellphone not found")
		  end
		end

		desc 'GET /api/v1/user/confirm'
		params do
		  requires :input_data, type: String
		  optional :cellphone, type:String
		  optional :confirm_code, type:String
		  optional :recover_code, type:String
		end
	  get '/confirm' do
		  params = parse_params(@params)
		  user = User.where("cellphone = ?", params['cellphone'].tr("+", "")).first
		  raise ApiError.new("Confirm user failed", "USER_CONFIRM_FAILED", "user not exist or already activated") if !user
		  recovery_code = params['recovery_code'].nil? ? nil : params['recovery_code']
		  user.check_code(params['confirm_code'], recovery_code)
		  user.activated
		  user.save!
		  {"result" => "success", "data" => {"access_token" => user.authentication_token}}
		end

		desc 'GET /api/v1/user/update_device'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :device_token, type:String
		end
	  get '/update_device_token' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  if current_user.update_attribute( :device_token, params['device_token'] ) 
		    {"result" => "success", "data" => {"message" => "device token updated"}}
		  else
		    raise ApiError.new("Update device token failed", "UPDATE_DEVICE_TOKEN_FAILED", user.errors)
		  end
		end
		  
		desc 'GET /api/v1/user/resend_code'
		params do
		  requires :input_data, type: String
		  optional :cellphone, type:String
		end
	  get '/resend_code' do
		  params = parse_params(@params)
		 	user = User.where("cellphone = ?", params['cellphone']).first
		 	user.check_activated
		  confirmation_hash = generate_user_hash
		  if user.send_sms('Your confirmation code:' + hash)
		    {"result" => "success", "data" => {"message" => "SMS successfully sended"}}
		  else 
			  raise ApiError.new("register user failed", "REG_USER_FAILED", user.errors)
			end
		end

		desc 'GET /api/v1/user/create_ticket'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :message, type:String
		end
	  get '/create_ticket' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  ticket = Ticket.new(:user_id => current_user.id, :message => params['message'])
		  if ticket.save!
			  {"result" => "success", "data" => {"message" => "Ticket created"}}
		  else
		    raise ApiError.new("create ticket failed", "CREATE_TICKET_FAILED", ticket.errors)
		  end
		end

		desc 'GET /api/v1/user/ticket_list'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	  get '/ticket_list' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  {"result" => "success", "data" => current_user.tickets}
		end
		  
		#TODO DESTROY IN PRODUCTION
		desc 'GET /api/v1/user/delete_by_phone'
		params do
		  requires :input_data, type: String
		  optional :cellphone, type:String
		end
	  get '/delete_by_phone' do
		  params = parse_params(@params)
		  user = User.where("cellphone = ?", params['cellphone']).first
		  user.destroy
		  if user.destroyed?
		    {"result" => "success", "data" => {"message"=>"User successfully delete"}}
		  else
		    raise ApiError.new("Delete user failed", "DEL_DOMAIN_FAILED", user.errors)
		  end
		end

		desc 'GET /api/v1/user/to_balance'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :amount, type:String
		end
	  get '/to_balance' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  payment = current_user.payments.build(:amount => params['amount'], :reference => 'test')
		  if payment.save 
		    current_user.to_credit(params['amount'].to_f)
		    {"result" => "success", "data" => {"message" => "Balance successfully added"}}
		  end
		end

		desc 'GET /api/v1/user/balance'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	  get '/balance' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  {"result" => "success", "data" => current_user.internal_credit}
		end

		desc 'GET /api/v1/user/get_subscriptions'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	  get '/get_subscriptions' do
		  authorize
		  params = parse_params(@params)
		  {"result" => "success", "data" => {"message" => current_user.billing_subscriptions.as_json(only: [:id, :type_of, :subscription_date, :previous_billing_date, :next_billing_date])}}
		end

		desc 'GET /api/v1/user/get_cost_subscription'
		params do
		  requires :input_data, type: String
		  optional :token, type:String
		end
	  get '/get_cost_subscription' do
		  params = parse_params(@params)
		  authorize(params["token"])
		  subscription = current_user.billing_subscription.find(params['subscription_id'])
		  domain = Domain.find(subscription.domain)
		  {"result" => "success", "data" => {"message" => current_user.get_full_amount(subscription.type_of, domain)}}
		end

		desc 'GET /api/v1/user/bill_subscription'
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
		  {"result" => "success", "data" => {"message" => "successfully added payment"}}
		end

		desc 'GET /api/v1/user/check_phone'
	  get '/check_phone' do
		  params = parse_params(@params)
		  GlobalPhone.db_path = Rails.root.join('db/global_phone.json')
	   	  phone = "+" + params['cellphone']
		  number = GlobalPhone.parse(phone)
		  #show_response({"valid"=>GlobalPhone.validate(phone), "territory" => number.territory.name})
		end

		desc 'GET /api/v1/user/test_push_ios'
	  get '/test_push_ios' do
		  authorize
		  send_ios_notify(current_user.device_token, 'Hello iPhone!')
		end

		desc 'GET /api/v1/user/test_push_android'
	  get '/test_push_android' do
		  authorize
		  send_android_notify(current_user.device_token, {:hello => "world"})
		end

  end
end
end


