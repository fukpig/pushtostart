ActiveAdmin.register Domain do
	menu :label => "Домены"
	
	index :title => "Домены" do
	  column "Id", :id
	  column "Дата регистрации", :registration_date
	  column "Домен", :domain
	  column "Дата окончания", :expiry_date
	  column "Статус", :status
	  column "Резервный телефон", :recovery_cellphone
	 end
	

	member_action :emails do
      @emails = EmailAccount.where('domain_id = ?', params[:id])

      # This will render app/views/admin/domains/emails.html.erb
    end

    member_action :groups do
      @groups = Group.where('domain_id = ?', params[:id])
    end
end
