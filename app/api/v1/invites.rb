module V1
  class Invites < Grape::API
  resource :invite do
 
  desc 'GET /api/v1/invites/create'
  params do
	requires :input_data, type: String
	  optional :token, type:String
	  optional :cellphone, type:String
	  optional :email, type:String
	end
  get '/create' do
		params = parse_params(@params)
		authorize(params["token"])

		info = EmailAccount.split_email(params['email']) 
		domain = current_user.domains.where('domain = ?', info['domain']).first
		raise ApiError.new("Create invite failed", "CREATE_INVITE_FAILED", {"message" => 'no such domain'}) if domain.nil?
		email = EmailAccount.where('domain_id = ? and email = ?', domain['id'],params['email']).first
		raise ApiError.new("Create invite failed", "CREATE_INVITE_FAILED", {"message" => 'no such email'}) if email.nil?
		invite = Invite.where('cellphone = ? and email_id = ?', params['cellphone'], email.id).first
		raise ApiError.new("Create invite failed", "CREATE_INVITE_FAILED", {"message" => 'invite exist'}) if !invite.nil?		

		user = User.where('cellphone = ?', params['cellphone']).first
		if !user.nil? 
			if user.id == email.user_id 
				raise ApiError.new("Create invite failed", "CREATE_INVITE_FAILED", {"message" => 'User already have this email'})
			end 
		end

		data = {'user_id'=>current_user['id'], 'cellphone' => params['cellphone'], 'domain_id' => domain['id'], 'email_id' => email['id'], 'name' => ''}
		result = Invite.create_invite(data)
		{"result" => "success", "data" => result}
  end

  desc 'GET /api/v1/invites/list'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	end
  get '/list' do
	params = parse_params(@params)
		authorize(params["token"])
		list = Domain.get_invite_domains(current_user, 'invites')
	{"result" => "success", "data" => list}
  end

  desc 'GET /api/v1/invites/accept'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	  optional :invite_id, type:Integer
	end
  get '/accept' do
	params = parse_params(@params)
		authorize(params["token"])
		invite = Invite.where(["cellphone = ? and id=?",current_user["cellphone"], params["invite_id"]]).first
		raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", {"message" => 'no such invite'}) if invite.nil?
		if invite.update_attribute( :accepted, true ) 
		  add_user_to_company(2, invite["domain_id"])
	  email = EmailAccount.find(invite['email_id'])
	  email.update_attributes(:user_id => current_user['id'], :name => invite['name'])
		{"result" => "success", "data" => { "message" => "successfully added to company"}}
		else 
			error!({ result: "errors", error_text: "Accept invite failed", error_code: "ACCEPT_INVITE_FAILED", error_data: invite.errors }, 422)
		end
  end
  
  desc 'GET /api/v1/invites/reject'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	  optional :invite_id, type:Integer
	end
  get '/reject' do
	params = parse_params(@params)
		authorize(params["token"])
		invite = Invite.where(["cellphone = ? and id=?",current_user["cellphone"], params["invite_id"]]).first
		raise ApiError.new("Reject invite failed", "REJECT_INVITE_FAILED", {"message" => 'no such invite'}) if invite.nil?
		invite.destroy!
		if invite.destroyed?
		  {"result" => "success", "data" => { "message" => "Invite successfully reject"}}
		else 
			raise ApiError.new("Reject invite failed", "REJECT_INVITE_FAILED", {"message" => invite.errors })
		end
  end

end
end
end
