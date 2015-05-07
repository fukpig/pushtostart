class AddTimestampsToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :created_at, :datetime
    add_column :domains, :updated_at, :datetime
  end
end
