ActiveAdmin.register AdminUser do
  menu false
  menu :label => "Администраторы"

  permit_params :email, :password, :password_confirmation

  index :title => "Администраторы" do
    selectable_column
    id_column
    column "Email", :email
    column "Последний логин", :current_sign_in_at
    column "Дата создания", :created_at
    actions
  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs "Admin Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

end
