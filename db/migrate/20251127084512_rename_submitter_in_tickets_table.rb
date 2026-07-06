class RenameSubmitterInTicketsTable < ActiveRecord::Migration[8.0]
  def change
    rename_column :tickets, :submmiter_name, :submitter_name
    # Ex:- rename_column("admin_users", "pasword","hashed_pasword")
  end
end
