class CreateMailSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :mail_settings do |t|
      t.boolean :enabled, default: true, null: false
      t.string :address
      t.integer :port, default: 587
      t.string :user_name
      t.text :password # encrypted at rest (Active Record Encryption)
      t.string :from_address

      t.timestamps
    end
  end
end
