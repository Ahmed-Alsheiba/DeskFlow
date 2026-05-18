class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :sector, :string, null: false, default: "General"
    add_column :users, :job_title, :string, null: false, default: ""
  end
end
