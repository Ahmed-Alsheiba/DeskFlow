class AddUserReferencesToTickets < ActiveRecord::Migration[8.0]
  def change
    add_reference :tickets, :submitter, null: true, foreign_key: { to_table: :users }
    add_reference :tickets, :assigned_to, null: true, foreign_key: { to_table: :users }
  end
end
