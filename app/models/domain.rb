class Domain < ActiveRecord::Base
	extend  Regru
	require 'domain'
	require 'yandex'
   
  belongs_to :user
  has_many :groups, dependent: :destroy
  has_many :email_accounts, dependent: :destroy
  audited
  has_associated_audits

  validates :domain, presence: true, uniqueness: true
	
	
	def self.list(user)
		domains = user.domains
		domains_info = Array.new()
		domains.each do |domain|
		  next_billing_date = get_next_billing_date(domain)
		  domains_info << {"id" => domain.id, "domain" => domain.domain, "registration_date"=>domain.registration_date, "expiry_date"=>domain.expiry_date, "status"=>domain.status, "next_billing_date"=>next_billing_date}
		end
		return domains_info
	end
	
	def self.get_price(domain)
	  info = parse_domain(domain)
    zone = PsConfigZones.get_zone(info["domain_zone"])
	  result = Domain.whois(domain)  
    email_price = zone.ps_price > 0 ? EmailAccount.amount_per_day : 0
    {"domain_price" => zone.ps_price, "email_price" => email_price}
	end
	
	def self.get_variants(domain)
		info = parse_domain(domain)
		reg_ru = RegApi2.domain.get_suggest(word: info["domain_word"],
        use_hyphen: "1",
		  category: "pattern",
		  limit: "5",
		  tlds: ["su", "ru", "com"],
		)
		variants = Array.new
		i = 0
		reg_ru.each do |variant|
		  break if i == 4
		  variant["avail_in"].each do |zone|
			  i += 1
			  break if i == 4
			  variants << variant["name"] + "." + zone
		  end
		end
		return variants
	end
	

	def self.get_domains_emails_count(domains)
		count = 0
		domains.each do |domain|
			count = count + domain.email_accounts.count
		end
		return count
	end
	
	def self.parse_domain(domain)
	  info = domain.split(".")
	  info = domain.split(".",2) if info.count == 3
	  {"domain_word" => info.first, "domain_zone" =>info.second}
	end
	
	
	def self.get_invite_domains(current_user, model)
	  list = Array.new
		if model == 'domains'
		  rows = DelegatedDomain.where(["cellphone = ?", current_user.cellphone])
		else 
		  rows = Invite.where(["cellphone = ?", current_user.cellphone])
		end
		rows.each do |row|
		  list << Domain.add_to_list(row) unless row.accepted?
		end
		return list
	end
	
	def self.add_to_list(info)
		data = Hash.new
		domain = Domain.where(["id = ?", info["domain_id"]]).first
		inviter = User.where(["id = ?", info["inviter_id"]]).first
		if !info["email_id"].nil?
			email = EmailAccount.where(["id = ?", info["email_id"]]).first
		end
		if !domain.nil?
		  data = { "id"=> info["id"], "domain_id" => domain.id, "domain"=> domain.domain, "inviter_id" => inviter.id, "inviter_name" => inviter.name}
		  if email
				data[:email] = email.email
			end
		end
		return data
	end
	
	def self.check_domain(domain)
	  raise ApiError.new("find domain failed", "FIND_DOMAIN_FAILED", "domain not found") if domain.nil?
	end
	

	#Yandex

				  #data = {:domain => info["domain"]}
				  #pdd = Yandex::PDD::new()
			  
				  #reg_domain_reg_ru(data)
				  
				  #result = pdd.domain_register(data[:domain])
				  #data[:cname] = 'yamail-'+ result["secrets"]["name"]
				  #set_records(data)

				  #cron = YandexCron.create(domain: info["domain"], email: info["email_name"])
				
				  #Yandex

	def self.register(current_user, info)
		Domain.whois(info["domain"])
		zone = PsConfigZones.get_zone(info["zone"])
		
		current_user.check_balance(zone.ps_price + EmailAccount.amount_per_day)
		Domain.transaction do
			domain = Domain.create(user_id: current_user.id, domain: info["domain"], registration_date: DateTime.now, expiry_date: 1.year.from_now, status: 'ok')
			if !domain.new_record?			
				EmailAccount.create_email(current_user, domain.id, info["email_name"], 'admin', '')
				#RegRu.reg_domain()
				#Yandex.create_domain()
				YandexCron.create(domain: info["domain"], email: info["email_name"])
				if !info["domain"].match(".pushtostart.ru")
					current_user.pay_subscription(domain.id)
				end
				current_user.add_user_to_company(1, domain.id)
		   	return domain
			else
			  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", domain.errors)
			end
    end
  end
	
	def self.get_next_billing_date(domain)
		subscription = Billing::Subscription.where('type_of = ? and domain = ?', 'domain', domain.domain).first
		if subscription.nil?
		  next_billing_date = nil 
		else
			next_billing_date = subscription.next_billing_date
		end
	end
	
	def self.whois(domain)
		begin
			result = Whois.whois(SimpleIDN.to_ascii(domain))
		rescue => e
			raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", "invalid domain")  
		end

		if !result.available?
		  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", 'Domain is not available')
	  end
	end
	
	def change_owner(new_owner_id)
	  self.update_attribute( :user_id, new_owner_id ) 
	end
	
end
