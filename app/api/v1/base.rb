require 'grape-swagger'
require 'api_exception'
require 'yandex'

module MyErrorFormatter
  def self.call status, text, code, message
      { :result => status, :text => text, :code => code, :message => message }
  end
end

class Grape::Middleware::Error
    def error_message(status, text, code, message)
      {
          :result => status,
          :error_text => text,
          :error_code => code,
          :error_data => message
      }.to_json
    end
  end


module V1
  class Base < Grape::API
    format :json
    content_type :xml, "text/xml"
    content_type :json, "application/json"
    default_format :json

    # for Grape::Jbuilder
    formatter :json, Grape::Formatter::Jbuilder
	  error_formatter :txt, MyErrorFormatter

    prefix :api
    version 'v1', using: :path 
   


    helpers do
      def warden
        env['warden']
      end

  	  def authorize(token)
  	    raise ApiError.new("Auth user failed", "AUTH_USER_FAILED", "Invalid token") unless authenticated(token)
  	  end
  	  
      def authenticated(token)
  	    @user = User.find_by_authentication_token(token)
  		  if !@user.nil? && @user.activated?
  			  token
  		  else
    			return false
  		  end
      end

      def init_pdd()
        pdd = Yandex::PDD::new()
        return pdd
      end


      def current_user
        @user
      end
	  
  	  def parse_params(params)
  	    params = JSON.parse(params[:input_data])
  	  end
  	  
  	  def show_response(response_data)
  		  data = {"result" => "success", "data" => response_data}
  		  render json: data, status: 201
  		end

  		def error(error_text, error_code, error_data)
  		  data = {"result"=>"errors", "error_text" => error_text, "error_code"=> error_code, "error_data"=> error_data}
  		  render json: data, status: 422
  		end
  		
  		def generate_user_hash
        code = Array.new(4){[*'0'..'9'].sample}.join
      end

      #NEXMO
      def send_registration_sms(cellphone, user_hash)
          require 'nexmo'
          nexmo = Nexmo::Client.new(key: 'ac5a236a', secret: '49ffb251')
          sms_answer = nexmo.send_message(from: 'PS App', to: '+' + cellphone, text: 'Your confirmation code:' + user_hash)  
          if sms_answer
            return true
          else
            raise ApiError.new("Send sms failed", "SEND_SMS_FAILED", "send sms failed")
          end
      end

      def add_user_to_company(role_id, domain_id)
          UserToCompanyRole.create(user_id: current_user['id'], role_id: role_id, domain_id: domain_id)
      end

    end
	
	
    #rescue_from ActiveRecord::RecordNotFound do |e|
      #error_response(message:  e.message, status: 404)
    #end

    #rescue_from Grape::Exceptions::ValidationErrors do |e|
      #error_response(message:e.message, status:500)
    #end

	#rescue_from :ApiError do |e|
	  #info = e.as_json
	  #if info["message"].is_a?(String)
		#info["message"] = {"message"=>info["message"]}
	  #end
	  #status = 'errors' 
	  #status = 'variants' if info["text"] == 'reg.ru variants'
      #{"result" => status,"error_text"=>info["text"],"error_code"=>info["text"],"message"=> info["message"]}
      #{"test" => "test"}

    #end
	
    rescue_from :all do |e|
      info = e.as_json
      if info["message"].is_a?(String)
        info["message"] = {"message"=>info["message"]}
      end
      status = 'errors' 
      status = 'variants' if info["text"] == 'reg.ru variants'
      
      if !info["text"].nil?
        rack_response(error_message(status, info["text"], info["text"], info["message"]), 422)
      else
        rack_response(error_message(status, "API ERROR", "API ERROR", e.message), 422)
      end
    end


	mount V1::Users
	mount V1::Domains
	mount V1::Groups
	mount V1::Emails
	mount V1::Invites

    add_swagger_documentation api_version: 'v1'
  end
end
