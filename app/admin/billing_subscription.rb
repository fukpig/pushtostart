ActiveAdmin.register Billing::Subscription do
  menu false
  menu :label => "Подписки"
  
  index  :title => "Подписки" do
	  column "Id", :id
	  column "Тип", :type_of
	  column "Дата создания подписки", :subscription_date
	  column "Оплачена", :billed_at
	  column "Предыдущая дата оплаты", :previous_billing_date
	  column "Следующая дата оплаты", :next_billing_date
	  actions
	 end
  
  member_action :payments do
      subscription = Billing::Subscription.find(params[:id])
	  if subscription.type_of == 'domain'
		@invoices = Billing::Invoice.where('domain_id = ? and (type_of = ? or type_of = ?)', subscription.domain, 'domain', 'create_domain')
      else
		@invoices = Billing::Invoice.where('domain_id = ? and (type_of = ? or type_of = ?)', subscription.domain, 'email', 'create_email')
	  end
	  @test
    end

end
