class CreateEmails < ActiveRecord::Migration
  def change
    create_table :com_emails do |t|
      t.string :message_id

      t.timestamps
    end
  end
end
