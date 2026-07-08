class AddSuspensionToUsers < ActiveRecord::Migration[8.0]
  def change
    # Reversible account suspension. suspended_at present == suspended.
    # suspended_by_id is a best-effort pointer (no FK) since the suspender may
    # later be terminated; reinstating clears all three columns.
    add_column :users, :suspended_at, :datetime
    add_column :users, :suspended_by_id, :bigint
    add_column :users, :suspension_reason, :text
    add_index :users, :suspended_at
  end
end
