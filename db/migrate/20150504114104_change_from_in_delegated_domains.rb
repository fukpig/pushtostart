class ChangeFromInDelegatedDomains < ActiveRecord::Migration
  def change
    rename_column :delegated_domains, :from, :inviter_id
  end
end
