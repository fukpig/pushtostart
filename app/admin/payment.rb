ActiveAdmin.register Payment do
  menu :label => "Оплаты"
  filter :created_at
  filter :id
  filter :user_cellphone, :as => :string
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # permit_params :list, :of, :attributes, :on, :model
  #
  # or
  #
  # permit_params do
  #   permitted = [:permitted, :attributes]
  #   permitted << :other if resource.something?
  #   permitted
  # end
 index :title => "Оплаты" do
    column "Телефон" do |payment|
      payment.user.cellphone
    end  
    column "Имя" do |payment|
      payment.user.name
    end  
    column "Номер" do |payment|
      payment.id
    end  
    column "Тип", :type
    column "Дата оплаты", :created_at
    column "Референс", :reference
    column "Сумма", :amount
  end

end
