class TicketsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.string :title, null: false
      t.text :description
      t.string :category
      t.string :status, null: false, default: 'open'
      t.string :priority, null: false, default: 'medium'
      t.string :location
      t.string :submmiter_name
      t.string :assigned_to

      t.timestamps
    end
    create_table :comments do |t|
      t.references :ticket, null: false, foreign_key: true
      t.text :content, null: false
      t.string :author_name

      t.timestamps
    end

    add_index :tickets, :status
    add_index :tickets, :priority
  end
end
