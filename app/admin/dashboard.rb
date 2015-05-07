ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do

  min_date = params[:date_min].nil? ? User.first.created_at : Time.parse(params[:date_min])
  max_date = params[:date_max].nil? ? Time.now : Time.parse(params[:date_max])
  date_range = min_date..max_date
  render 'charts_src'
  render 'date_form', :default_min_value => min_date.strftime('%Y-%m-%d'), :default_max_value => max_date.strftime('%Y-%m-%d')
       columns do
       column do
         panel "Оплаты" do
           vendor_payments = vendor_domains_payments = vendor_emails_payments = 0
           Billing::Invoice.where("created_at >= ? AND created_at <= ?", min_date, max_date).map {|invoice| vendor_payments += invoice.provider_price.to_f}
           Billing::Invoice.where("created_at >= ? AND created_at <= ? AND type_of = ?", min_date, max_date, 'create_domain').map {|invoice| vendor_domains_payments += invoice.provider_price.to_f}
           Billing::Invoice.where("created_at >= ? AND created_at <= ? AND type_of = ?", min_date, max_date, 'create_email').map {|invoice| vendor_emails_payments += invoice.provider_price.to_f}
           

           render 'billing', :all_payments => Payment.where("created_at >= ? AND created_at <= ?", min_date, max_date).sum(:amount), 
                             :vendor_payments => vendor_payments.round(2),
                             :domains_count => Domain.where("created_at >= ? AND created_at <= ?", min_date, max_date).count,
                             :emails_count => EmailAccount.where("created_at >= ? AND created_at <= ?", min_date, max_date).count,
                             :vendor_domains_payments => vendor_domains_payments.round(2),
                             :vendor_emails_payments => vendor_emails_payments.round(2)
         end
       end

       column do
         panel "Пользователи" do
           @users = User.group_by_day(:created_at, range:date_range).count
           render 'user_count', :users => @users
         end
       end
     end

     columns do
       column do
         panel "Домены" do
          @domains_type = Array.new
          @domains_type << ['.pushtostart.ru', Domain.where("created_at >= ? AND created_at <= ? AND domain like ?", min_date, max_date, '%.pushtostart.ru%').count]
          @domains_type << ['other', Domain.where("created_at >= ? AND created_at <= ? AND domain not like ?", min_date, max_date, '%.pushtostart.ru%').count]
          @domains = Domain.group_by_day(:created_at, range:date_range).count
          render 'domain_count', :domains_type => @domains_type, :domains => @domains
         end
       end

       column do
         panel "Ящики" do
           @emails = EmailAccount.group_by_day(:created_at, range:date_range).count
           render 'email_count', :emails => @emails
         end
       end
      
     end
  end # content
end
