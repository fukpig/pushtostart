ActiveAdmin.register Billing::Invoice do
  menu false	
  menu :label => "Оплаты"


  index :title => "Пользователи" do
  	column "Телефон" do |invoice|
      invoice.user.cellphone
    end  
    column "Имя" do |invoice|
      invoice.user.name
    end  
    column "Дата оплаты", :created_at
    column "Кол-во доменов" do |invoice|
		invoice.user.domains.count
	end
	column "Домен", :params
	column "Действие", :type_of
	column "Кол-во ящиков" do |invoice|
		count = 0
        invoice.user.domains.map {|domain| count = count + domain.email_accounts.count}
        count
	end
	column "Сумма оказанных услуг", :full_amount
	column "Сумма оплаты поставщикам", :provider_price
	column "Разница в деньгах" do |invoice|
	  provider_price = invoice.provider_price
	  provider_price = 0 if provider_price.nil?
 	  invoice.full_amount-provider_price
	end
	column "Разница в процентах" do |invoice|
		provider_price = invoice.provider_price
	    provider_price = 0 if provider_price.nil?
 	    price = invoice.full_amount-provider_price
		percentage = price/invoice.full_amount*100
		percentage.round(2)
	end
  end
end