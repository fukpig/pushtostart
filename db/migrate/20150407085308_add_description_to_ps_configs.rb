class AddDescriptionToPsConfigs < ActiveRecord::Migration
  def change
    add_column :ps_configs, :description, :string
  end
end
