class CreateRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_tokens do |t|
      t.references :admin, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at
      t.string :session_id, null: false

      t.timestamps
    end
    add_index :refresh_tokens, :token, unique: true
    add_index :refresh_tokens, :session_id, unique: true
  end
end
