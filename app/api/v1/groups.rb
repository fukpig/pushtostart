module V1
  class Groups < Grape::API
  resource :group do
  
  desc 'GET /api/v1/groups/list'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	end
  get '/list' do
    params = parse_params(@params)
	  authorize(params["token"])
    domain_ids = current_user.domain_ids
    groups = Group.where("domain_id IN (?)", domain_ids)
    info = Group.get_info(groups)
    
    {"result" => "success", "data" => info}
  end

  desc 'GET /api/v1/groups/check'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	  optional :group_name, type:String
	end
  get '/check' do
    params = parse_params(@params)
	  authorize(params["token"])
    group = Group.where("email = ?", params['group_name']).first
    if !group
	    {"result" => "success",  "data" =>{"message" => "Group available"}}
    else
      raise ApiError.new("group not available", "CHECK_GROUP_FAILED", {"message" => 'group not available'})
    end
  end

  desc 'GET /api/v1/groups/info'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	  optional :mail, type:String
	end
  get '/info' do
    params = parse_params(@params)
	  authorize(params["token"])
    info = EmailAccount.split_email(params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
	  group = Group.get_group(domain, params['mail'])
    {"result" => "success", "data" => {'id' => group['id'], 'email' => group['email'], 'description' => group['description'], 'emails' => group.email_accounts, 'created_at' => group["created_at"].strftime("%d.%m.%Y")}}   
   end

  desc 'GET /api/v1/groups/create'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	  optional :mail, type:String
	  optional :description, type:String
	end
  get '/create' do
    params = parse_params(@params)
	  authorize(params["token"])
    info = EmailAccount.split_email(params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
    group = Group.create(domain_id: domain['id'], email: params['mail'], description: params['description'])
    if !group.new_record?
	    {"result" => "success", "data" => group.as_json(only: [:id, :email])}
    else
       raise ApiError.new("Register group failed", "CREATE_GROUP_FAILED", group.errors)
    end
  end

  desc 'GET /api/v1/groups/delete'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	  optional :mail, type:String
	end
  get '/delete' do
    params = parse_params(@params)
	  authorize(params["token"])
    info = EmailAccount.split_email(params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
	  group = Group.get_group(domain, params['mail'])
	  group.destroy
    if group.destroyed?
	    {"result" => "success",  "data" => {"message" => "Group successfully delete"}}
    else
      raise ApiError.new("Delete group failed", "DEL_GROUP_FAILED", group.errors)
    end
  end

  desc 'GET /api/v1/groups/add'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	  optional :mail, type:String
	  optional :group_emails, type:String
	end
  get '/add' do
    params = parse_params(@params)
    authorize(params["token"])
	  info = Group.edit_group(params['mail'], params['group_emails'], 'add')
	  {"result" => "success",  "data" =>{"message" => info}}
  end

  desc 'GET /api/v1/groups/remove'
	params do
	  requires :input_data, type: String
	  optional :token, type:String
	  optional :mail, type:String
	  optional :group_emails, type:String
	end
  get '/remove' do
    params = parse_params(@params)
	  authorize(params["token"])
    info =  Group.edit_group(params['mail'] , params['group_emails'], 'del')
	  {"result" => "success",  "data" => {"message" => info}}
  end

end
end
end