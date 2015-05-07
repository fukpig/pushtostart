ActiveAdmin.register PsConfig do
   menu :parent => "Настройки", :label => "Общие настройки"
   config.filters = false

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
  index do  
    column "Описание",:description
    column "Значение", :value
    actions
  end

  permit_params do
    permitted = [:option, :description, :value]
   end

end
