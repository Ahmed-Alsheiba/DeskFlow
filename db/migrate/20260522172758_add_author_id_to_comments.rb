class AddAuthorIdToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :author_id, :bigint
    add_index :comments, :author_id
    add_foreign_key :comments, :users, column: :author_id
  end
end
