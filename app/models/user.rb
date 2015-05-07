class User < ActiveRecord::Base
  include AASM

  has_many :api_keys, dependent: :destroy
  has_many :domains, dependent: :destroy
  has_many :email_accounts
  has_many :tickets, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :user_role

  has_many :billing_subscriptions, :class_name => 'Billing::Subscription'

  has_attached_file :avatar
  validates_attachment_content_type :avatar, :content_type => %w(image/jpeg image/jpg image/png)

  before_save :ensure_authentication_token

  has_many :billing_subscription,
    :class_name => 'Billing::Subscription',
    #:conditions => proc {
      #["billing_subscriptions.subscription_date <= ? AND (billing_subscriptions.unsubscription_date IS NULL OR billing_subscriptions.unsubscription_date > ?)", Date.today, Date.today]
    #},
    :dependent => :destroy,
    :inverse_of => :user

  has_many :billing_invoices, :class_name => 'Billing::Invoice', :dependent => :destroy, :inverse_of => :user
  has_many :billing_transactions, :class_name => 'Billing::Transaction', :dependent => :destroy, :inverse_of => :user


  validates :cellphone, presence: true, uniqueness: true, length: { in: 6..40 },  format: { with: /\A[0-9]+\z/,
    message: "only allows numbers" }

  attr_accessor :locked_credit
  
  
  aasm do
    state :confirming, :initial => true
    state :recovering
    state :activated
    state :disabled


    event :activated do
      transitions :from => [:recovering, :disabled, :confirming, :activated], :to => :activated
    end

    event :disable do
      transitions :from => :activated, :to => :disabled
    end

    event :recovering do
      transitions :from => [:confirming, :activated, :disabled], :to => :recovering
    end
  end

  
  
  def self.check_cellphone(params)
    if params['cellphone'] == params['recovery_cellphone']
        raise ApiError.new("Recover user failed", "RECOVER_USER_FAILED",'Recovery cellphone and cellphone are similar')
    end
  end

  def check_activated
    if self.activated? == true
       raise ApiError.new("register user failed", "REG_USER_FAILED", 'user already activated')
    end
  end

  
  def decode_image_data(image_data)
	  if image_data.present?
      data = StringIO.new(Base64.decode64(image_data))
      data.class.class_eval {attr_accessor :original_filename, :content_type}
      data.original_filename = self.id.to_s + ".jpg"
      data.content_type = "image/jpg"
      self.avatar = data
		  self.save!
    end
  end
  
  def history
    info = Array.new
    self.domains.each do |domain|
        domain.audits.each do |audit|
          info << {:type => audit[:auditable_type], 
                   :action => audit[:action], 
                   :created_at =>audit[:created_at].strftime("%d-%m-%Y")}
        end

        domain.associated_audits.each do |audit|
          info << {:type => audit[:auditable_type], 
                   :action => audit[:action], 
                   :email => audit[:audited_changes]["email"], 
                   :created_at =>audit[:created_at].strftime("%d-%m-%Y")}
        end
      end
    return info
  end



  def email_list()
    domain_ids = self.domain_ids
    emails = EmailAccount.where("domain_id IN (?)", domain_ids)
    data = Array.new
    emails.each do |email|
      name = email.is_admin? ? email.user["name"] : email["name"]
      status = email.is_enabled? ? "yes" : "no"
      me = email.user == self ? "yes" : "no"
      data << {"id" => email["id"],"email" => email["email"],"name" => name, "cellphone" => email.user["cellphone"], "enabled" => status, "avatar" => email.user.avatar.url, "me" => me}
    end
    return data
  end

  def update_emails(name)
    EmailAccount.where('user_id = ?', self.id).update_all(name: name)
  end

  def user_info()
      user_info = Hash.new
      user_info['domains'] = Array.new
      user_info['groups'] = Array.new
      self.email_accounts.each do |email|
        domain = Domain.find(email.domain_id)
        user_info['domains'] << {"domain_id" => domain.id, "domain_name" => domain.domain}
        email.groups.each do |group|
          group = Group.find(group.id)
          user_info['groups'] << {"group_id" => group.id, "group_name" => group.email}
        end
      end
      return user_info
  end

  def self.get_belongs(roles)
    data = Array.new
	  roles.each do |role|
      domain = Domain.where('id = ?', role.domain_id).first
      if domain
        email =  EmailAccount.where('user_id =? and domain_id = ?', current_user["id"], domain.id).first
        data << {"email_id" => email["id"], "email_name" => email["email"], "domain_id" => domain["id"], "domain_name" => domain["domain"]}
      end
    end
  end
  
  def self.recover_user(params)
    if user = User.where('cellphone = ?', params['cellphone']).first
      user.update_attributes( :recovery_cellphone => params['recovery_cellphone'],:confirmation_hash => Digest::SHA1.hexdigest(confirmation_hash), :recovery_hash => Digest::SHA1.hexdigest(recovery_hash), :aasm_state => 'recovering', :temp_device_token => params['device_token']) 
    else 
      user = User.create(cellphone: params['cellphone'].strip, recovery_cellphone: params['recovery_cellphone'], recovery_hash: Digest::SHA1.hexdigest(recovery_hash), confirmation_hash: Digest::SHA1.hexdigest(confirmation_hash), device_token: device_token, internal_credit: 5000, aasm_state: 'recovering')
    end
    return user
  end

  def pay_subscription(domain_id)
    self.pay_domain(domain_id)
    self.pay_email(domain_id, 1)
    self.create_subscriptions(domain_id)
  end

  def send_sms(text, cellphone = 'register')
  	require '/home/pushtostart/smsc_api'
    sms_cellphone = self.cellphone
    sms_cellphone = self.recovery_cellphone if cellphone != 'register'
  	sms = SMSC.new()
  	ret = sms.send_sms('+' + sms_cellphone, text, 0, 0, 0, 0, 'ps-app', "maxsms=3")
  	if ret[1] == '1'
  	  return true
  	else
  	  raise ApiError.new(ret, "SEND_SMS_FAILED", "send sms failed")
  	end
   end
   
  def check_code(confirm_code, recovery_code = nil)
    check_recovery_code(recovery_code) if !recovery_code.nil?
    check_confirm_code(confirm_code)
  end

  def check_recovery_code(code)
    if !code.nil? && self.recovery_hash == Digest::SHA1.hexdigest(code)
      return true 
    else 
      raise ApiError.new("Confirm user failed", "USER_CONFIRM_FAILED", "not valid code")
    end
  end

  def check_confirm_code(code)
    if !code.empty? && self.confirmation_hash == Digest::SHA1.hexdigest(code)
      return true 
    else 
      raise ApiError.new("Confirm user failed", "USER_CONFIRM_FAILED", "not valid code")
    end
   end
   
  def activate
    if self.aasm_state == 'recovering' 
      recovery_user = User.where('cellphone = ?', self.recovery_cellphone).first
      user.update_attribute(:internal_credit, recovery_user.internal_credit)
      Domain.where('recovery_cellphone = ?', self.recovery_cellphone).update_all(user_id: user.id)
    end
	  
    #self.update_attribute( :activated, true ) 
    self.update_attributes(:temp_device_token => '', :confirmation_hash => '')
    self.activated
    self.save
	  api_key = self.find_api_key
  end
   
  def set_recovery_cellphone(recovery_cellphone)
	  if recovery_cellphone == self.cellphone 	
		  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", "recovery cellphone similar user main cellphone")
		end 
		
		if recovery_cellphone != self.recovery_cellphone && self.domains.count > 0
		  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", "recovery_cellphone doesnt match first recovery cellphone'") 
		else
		  self.recovery_cellphone = recovery_cellphone
		  self.save!
		end
	end

  def add_user_to_company(role, domain_id)
    UserToCompanyRole.create(user_id: self.id, role_id:2, domain_id: domain_id)
  end

  def pay_domain(domain_id)
    domain = Domain.find(domain_id)
    type_of = 'create_domain'
    domain_zone = domain['domain'].split(".")[1]
    zone = PsConfigZones.where("name = ?", domain_zone).first
    full_amount = zone.ps_price
    invoice = create_invoice(self, domain, full_amount, type_of, zone.orig_price)
    pay!(invoice)
  end

  def pay_email(domain_id, interval)
    domain = Domain.find(domain_id)
    type_of = 'create_email'
    full_amount = EmailAccount.amount_per_day + (interval-1)*PsConfig.email_price
    invoice = create_invoice(self, domain, full_amount, type_of)
    pay!(invoice)
  end

  def invoice!(type_of, domain_id)
    domain = Domain.find(domain_id)
    full_amount = get_full_amount(type_of, domain)
    invoice = create_invoice(self, domain, full_amount, type_of)
    pay!(invoice)
  end  

  #TODO CHEKC full_amount = 8
  def get_full_amount(type_of, domain)
    if type_of == 'domain'
      full_amount = 7
    elseif type_of == 'email_create'
      full_amount = EmailAccount.amount_per_day
    else
      full_amount = PsConfig.email_price*domain.email_accounts.count
    end
    return full_amount
  end

  def create_invoice(user, domain, full_amount, type, provider_price=0)
    provider_price = provider_price if provider_price!=0
    check_balance(full_amount)      
    invoice = self.billing_invoices.create! do |i|
      i.user = user
      i.type_of = type
      i.domain_id = domain.id
      i.params = domain.domain     
      i.full_amount = full_amount
      i.title = domain.domain
      i.credit_deduction = 0     
      i.amount = 0
      i.provider_price = provider_price
    end
    return invoice
  end
  
  def create_subscriptions(domain_id)
    self.billing_subscription.create(type_of: 'domain', domain: domain_id, billed_at: Date.today)
    self.billing_subscription.create(type_of: 'email', domain: domain_id)
  end

  def pay!(invoice)
    invoice.amount = self.from_credit(invoice.full_amount, invoice.id)
    invoice.paid_at = Time.now
    invoice.save
  end

  def check_balance(amount)
    balance = self.internal_credit-amount
    raise ApiError.new("Payment failed", "PAY_FAILED", "Not enough credit") unless balance > 0
  end

  def find_api_key ()
    self.api_keys.first_or_create
  end

  def to_credit(amount)           
    success = transaction do
      self.lock_internal_credit!
      self.internal_credit += amount.abs      
      self.save(:validate => false)            
    end
    amount = (self.internal_credit - self.locked_credit).abs
    
    self.billing_transactions.create(
      :action => 'internal_credit_replenishment',
      :amount => amount,
      :success => success    
    ) if amount != 0       
    
    return amount
  end

  def from_credit(amount, invoice_id)        
    success = transaction do
      self.lock_internal_credit!
      self.internal_credit < amount.abs ? self.internal_credit = 0 : self.internal_credit -= amount.abs        
      self.save(:validate => false)
    end
    amount = (self.locked_credit - self.internal_credit).abs
    
    self.billing_transactions.create(
      :action => 'internal_credit_withdrawal',
      :invoice_id => invoice_id,
      :amount => amount,
      :success => success    
    ) if amount != 0       
    
    return amount
  end

  def enough_credit?(full_amount)
    raise ApiError.new("Payment failed", "PAY_FAILED", "Not enough credit") unless self.internal_credit >= full_amount
  end  

   def ensure_authentication_token
    self.authentication_token ||= generate_authentication_token
  end


  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end


  protected

  def lock_internal_credit!
    self.lock!
    self.locked_credit = self.internal_credit
  end

end
