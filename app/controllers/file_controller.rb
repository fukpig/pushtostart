class FileController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  def ios_file
    file_path = Rails.root.join("public/mobileconfigs/"+params['filename']+".mobileconfig")
   	if File.exist?(file_path)
   	  File.open(file_path, 'r') do |f|
	    send_data f.read, type: "application/x-apple-aspen-config"
	  end
	  File.delete(file_path)
	else 
	  redirect_to "http://belkamail.com/"
	end
   end
end
