module V1
  class Invites < Grape::API
  resource :invite do
 
  desc 'GET /api/v1/invites/create'
	  params do
		  requires :input_data, type: String
		  optional :token, type:String
		  optional :cellphone, type:String
		  optional :domain_id, type:Integer
		  optional :email_id, type:String
		end
      get '/create' do
  	#TODO REFACT THIS IF`s
  	params = parse_params(@params)
	authorize(params["token"])

    data = {'user_id'=>current_user['id'], 'cellphone' => params['cellphone'], 'domain_id' => params['domain_id'], 'email_id' => params['email_id'], 'name' => params['name']}
  	result = Invite.create_invite(data)
	{"result" => "success", "message" => result}
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
    {"result" => "success", "message" => list}
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
	raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", "no such invite") if invite.nil?
	if invite.update_attribute( :accepted, true ) 
	  add_user_to_company(2, invite["domain_id"])
      email = EmailAccount.find(invite['email_id'])
      email.update_attributes(:user_id => current_user['id'], :name => invite['name'])
	  {"result" => "success", "message" => "successfully added to company"}
	else 
      raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", invite.errors)
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
	raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", "no such invite") if invite.nil?
	if invite.destroyed?
	  {"result" => "success", "message" => "Invite successfully reject"}
	else 
      raise ApiError.new("Reject invite failed", "REJECT_INVITE_FAILED", invite.errors)
	end
  end

end
end
end
