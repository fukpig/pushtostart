class DelegatedDomain < ActiveRecord::Base

    validates :cellphone, presence: true
    validates :inviter_id, presence: true

	def self.delegate(data)
	  #check_invite_himself(data['domain_id'], data['cellphone'])
  	  delegate = DelegatedDomain.create(domain_id:  data['domain_id'], inviter_id: data['user_id'], cellphone: data['cellphone'])
	  return {"message"=>"delegated domain has been added"}
	end

  def self.check_invite_himself(user_cellphone, cellphone)
  	raise ApiError.new("Send invite failed", "SEND_INVITE_FAILED", "invalid cellphone") unless cellphone != user_cellphone
  end

  def self.get_delegate_invite(cellphone, invite_id)
	invite = DelegatedDomain.where("cellphone = ? and id = ?",cellphone, invite_id).first
	if !invite.nil?
	  return invite
	else
	  raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", "no such invite")
	end
  end
	
	def accept
	 self.update_attribute( :accepted, true ) 
	end
end
