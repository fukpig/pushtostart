ActiveAdmin.register Ticket do
  menu :label => "Сообщения"

  filter :message
  filter :user_cellphone, :as => :string

  index :title => "Сообщения" do
    column "Id", :id
    column "Пользователь" do |ticket|
       link_to(ticket.user.cellphone,'/admin/users/' + ticket.user.id.to_s)
    end
    column "Текст сообщения", :message
    column "Создан", :created_at
   end


end
