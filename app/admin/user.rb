ActiveAdmin.register User do
 menu :label => "Пользователи"
 
 filter :cellphone
 
 index :title => "Пользователи" do  
    column "Телефон", :cellphone,  sortable: :cellphone
    column "Имя", :name
    column "Дата регистрации", :created_at, sortable: :created_at
    column "Кол-во доменов" do |user|
      user.domains.count
    end
    column "Кол-во ящиков купленных" do |user|
      count = 0
      user.domains.map {|domain| count = count + domain.email_accounts.count}
      link_to(count,emails_admin_user_path(user))
    end
    column "Кол-во ящиков делегированых" do |user|
      count = 0
      user.domains.each do  |domain| 
        domain.email_accounts.each do |email|
          count = count + 1 if email.user != user
        end
      end
      link_to(count,emails_delegated_admin_user_path(user))
    end
    column "Оплаты" do |user|
      link_to("Оплаты",billing_admin_user_path(user))
    end
  end
  

  member_action :billing do
    @invoices = resource.billing_invoices
  end

  member_action :emails do
    info = Array.new
    resource.domains.each do  |domain| 
        domain.email_accounts.each do |email|
          info << email
        end
    end
    @emails = info
  end

  member_action :emails_delegated do
    info = Array.new
    resource.domains.each do  |domain| 
        domain.email_accounts.each do |email|
          info << email if email.user != resource
        end
    end
    @emails = info
  end

  show do |user|
      attributes_table do
        row "Телефон" do
            user.cellphone
        end
        row "Фио" do
            user.name
        end
        row "Количество доменов" do
            user.domains.count
        end
        row "Баланс" do
            user.internal_credit
        end
		row "Резервный телефон" do
            if user.domains.count > 0
				user.domains.first["recovery_cellphone"]
			end
        end
        table_for user.domains do
          column "Владеет доменами:" do |domain|
            domain.domain
          end
          column "Количество ящиков" do |domain|
            link_to(domain.email_accounts.count,'/admin/domains/' + domain.id.to_s + '/emails')
          end
          column "Группы" do |domain|
            link_to(domain.groups.count, '/admin/domains/' + domain.id.to_s + '/groups')
          end
        end

        table_for user.billing_subscriptions do
          column "Домен" do |subscription|
		    domain = Domain.where("id = ?", subscription.domain.to_i).first
            if !domain.nil?
              domain.domain
            end
          end
          column "Тип подписки:" do |subscription|
            subscription.type_of
          end
          column "Предыдущая дата оплаты" do |subscription|
            subscription.previous_billing_date
          end
		  
		  column "Статус reg.ru" do |subscription|
            link_to "Получить", '#', :class => "check_reg_ru"
          end
		  
		  column "Статус Yandex" do |subscription|
            link_to "Получить", '#', :class => "check_yandex"
          end
		  
          column "Следующая дата оплаты" do |subscription|
            subscription.next_billing_date
          end
          column "Оплачено" do |subscription|
            if (subscription.previous_billing_date.nil? || subscription.previous_billing_date <= Date.today)
              "ДА"
            else
              "НЕТ"
            end
          end
		  
		  column "Действия" do |subscription|
			link_to('Посмотреть оплаты','/admin/billing_subscriptions/' + subscription.id.to_s + '/payments')
		  end

        end

       
        roles = UserToCompanyRole.where('user_id = ? and role_id = ?', user.id, 2)
        table_for roles do
          column "Состоит в:" do |role|
			domain = Domain.where('id = ?', role.domain_id).first
			if !domain.nil?
              domain.domain
            end
          end
        end
      end
  end
end
