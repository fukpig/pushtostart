class EmailAccount < ActiveRecord::Base
    require 'yandex'
    require 'mechanize'

    belongs_to :user
    belongs_to :domain
    audited :associated_with => :domain
    has_and_belongs_to_many :groups

    validates :user_id, presence: true
    validates :domain_id, presence: true
    validates :email, :presence => true, uniqueness: true, format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/,
    message: "not valid email" }

    scope :common, ->{ where('is_admin = ?', 'f') }

    def self.create_email(current_user, domain_id, email, role, name)
      domain = current_user.domains.where(["id = ?", domain_id]).first   
      email = EmailAccount.create(user_id: current_user['id'], domain_id: domain['id'], email: "#{email}@#{domain['domain']}".downcase , is_admin: self.get_role(role), name: name, is_enabled: true)

      if !email.new_record?
        pdd = Yandex::PDD::new
        password = Array.new(10){[*"A".."Z", *"0".."9"].sample}.join
    
        #pdd.email_create(domain.domain, email.email, password)
        #pdd.email_verify(domain.domain, email.email)
        #email.activate_yandex(password)
       return email
      else
        raise ApiError.new("Register email failed", "REG_EMAIL_FAILED", "email already exist")
      end
    end

    def self.get_role(role)
    	if role == 'admin'
    		return true
    	else 
    		return false
    	end
    end

    def self.amount_per_day
    	days = (Date.today.at_beginning_of_month.next_month - Date.today).to_i
    	days*((PsConfig.email_price / 30).round(2))
    end

    def self.split_email(email)
      array = email.split("@")
  		raise ApiError.new("Check email failed", "CHECK_EMAIL_FAILED", "Email not valid") if array.count < 2
  		raise ApiError.new("Check email failed", "CHECK_EMAIL_FAILED", "Email empty") if array[0].empty?
		
      if array[0].match('[a-zA-Z0-9\.\-\s]+')
        info = array[1].split(".")
        info = array[1].split(".",2) if info.count == 3
        return {"email_name" => array[0].downcase, "domain" => array[1].downcase, "zone" => info.second.downcase }
      else
        raise ApiError.new("Check email failed", "CHECK_EMAIL_FAILED", "Email not latin")
      end  
    end
	
	def self.change_owner(domain_id)
	   EmailAccount.where('domain_id = ?', domain_id).update_all(domain_id:domain_id)
	end

   def self.generate_email(data)
    emails_a = []
    firstname = Russian.translit(data[:firstname])
    if !firstname.empty?
      email = "#{firstname}@#{data[:domain]}"
      emails_a << email unless !available? email
    end

    if !data[:phone].empty?
      email = "#{data[:phone]}@#{data[:domain]}"
      emails_a << email unless !available? email
    end

    if !data[:email].empty?
      emails_a << assort_email(data[:domain], data[:email])
    end

    emails_a
  end


  def self.available?(email)
    email = EmailAccount.where(:email => email).first
    return true unless email
  end

  def self.assort_email(domain, email)
    available = false
    counter = 1
    while available == false  do
      email = "#{email}#{counter}@#{domain}"
      available = available? email
      counter += 1
    end
    return email
  end

  def self.generate_mobileconfig(email, password)
    time = Digest::SHA1.hexdigest(Time.now.getutc.to_s)
    file_email = Digest::SHA1.hexdigest("--a982lsnn--#{email}--")
    file_name = file_email + "_" + time 

    Dir.glob(Rails.root.join("public/mobileconfigs/#{file_email}_*.mobileconfig")).each { |f| File.delete(f) }

    path = Rails.root.join("public/mobileconfigs/"+file_name+".mobileconfig")
    File.open(path, "w") do |out|
      File.open(Rails.root.join("templates/profile.mobileconfig"), "r") do |tmpl|
        out.write tmpl.read.gsub('[email]', email).gsub('[password]', password)
      end
    end
    return file_name
  end


  def activate_yandex(password)
    catch (:done) do
      5.times { 
        page = authorization_yandex(password)
        throw :done if page
      }
      return page
    end
  end

  def authorization_yandex(password)
    agent = Mechanize.new { |a| a.log = Logger.new("mech.log") }
    page = agent.post('https://passport.yandex.com/passport?mode=auth&ncrnd=7424', {
      "login" => self.email,
      "passwd" => password,
      "loginSubmit" => "Login",
      "url" => ""
    })


    captcha = page.at(".captcha__captcha__text").attributes["src"].value


    client = DeathByCaptcha.new('fukpig@mail.ru', 'a982lsnn', :http)
    captcha = client.decode(url:captcha)

    page.form.answer = captcha.text
    page.form.submit
    return page
  end


  def info(user_id)
    info = Hash.new

    my = (self.user_id == user_id)? true : false
    admin = (self.user.domains.where('id = ?', self.domain_id).first)? true : false

    last_disable_time = nil
    self.audits.each do |audit|
      if audit[:action] == 'update' && audit.audited_changes["is_enabled"][0] == true
        last_disable_time = audit[:created_at].strftime("%d-%m-%Y")
      end
    end
    about = {"admin" => admin, "my" => my, "last_disable_time" => last_disable_time, "enabled" => self.is_enabled}
    info[:about] = about
    if my == true
      split_info = EmailAccount.split_email(self.email)
      outlook = {"name" => self.user.name, "email" => self.email, "pop3" => 'pop.'+self.domain.domain, 'smtp' => 'smtp.'+self.domain.domain}
      info[:outlook] = outlook
    end
    return info
  end
end
