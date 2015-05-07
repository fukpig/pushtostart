class AddCellphoneToDelegatedDomains < ActiveRecord::Migration
  def change
    add_column :delegated_domains, :cellphone, :string
  end
end
