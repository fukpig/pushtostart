class AddProviderPriceToBillingInvoices < ActiveRecord::Migration
  def change
    add_column :billing_invoices, :provider_price, :decimal
  end
end
