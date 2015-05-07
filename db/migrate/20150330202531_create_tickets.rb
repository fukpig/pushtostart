class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.integer :user_id
      t.text :message
      t.text :answer

      t.timestamps
    end
  end
end
