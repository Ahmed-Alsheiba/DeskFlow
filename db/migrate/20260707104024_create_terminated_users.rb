class CreateTerminatedUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :terminated_users do |t|
      # Identity snapshot of the removed user (no password hash, deliberately).
      # original_user_id is a plain bigint — the users row is destroyed, so no FK.
      t.bigint :original_user_id, null: false
      # Not unique: the same email can register again and be terminated again.
      t.string :email, null: false
      t.string :first_name, null: false, default: ""
      t.string :last_name, null: false, default: ""
      t.string :role, null: false
      t.string :job_title, null: false, default: ""
      t.string :sector, null: false, default: ""

      # Dependent-data counts, frozen at termination time.
      t.integer :submitted_tickets_count, null: false, default: 0
      t.integer :assigned_tickets_count, null: false, default: 0
      t.integer :solved_tickets_count, null: false, default: 0
      t.integer :comments_count, null: false, default: 0

      # Termination record. The name is the durable snapshot; the id is a
      # best-effort pointer with no FK since the terminator may later be
      # terminated themselves.
      t.text :reason, null: false
      t.string :terminated_by_name, null: false
      t.bigint :terminated_by_id

      # created_at doubles as the termination timestamp.
      t.timestamps
    end
    add_index :terminated_users, :original_user_id
  end
end
