ActiveAdmin.register EmailAccount do
  menu :label => "Почтовые ящики"

  index :title => "Почтовые ящики" do
	  column "Id", :id
	  column "Email", :email
	  column "Дата создания ящика", :created_at
	  column "Админ", :is_admin
	  column "ФИО", :name
	  actions
	 end


end
