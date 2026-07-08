class AddTerminatedUserRefsToTicketsAndComments < ActiveRecord::Migration[8.0]
  def change
    # Durable back-links from a record to the archive row of the user who
    # submitted/was-assigned/authored it, stamped during User#terminate! before
    # the user row is destroyed. on_delete: :nullify keeps a future archive
    # purge clean.
    add_reference :tickets, :submitter_terminated_user, null: true,
      foreign_key: { to_table: :terminated_users, on_delete: :nullify }
    add_reference :tickets, :assignee_terminated_user, null: true,
      foreign_key: { to_table: :terminated_users, on_delete: :nullify }
    add_reference :comments, :author_terminated_user, null: true,
      foreign_key: { to_table: :terminated_users, on_delete: :nullify }
  end
end
