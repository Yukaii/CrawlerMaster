class AddIndexToAdminUsers < ActiveRecord::Migration
  def change
    add_index :admin_users, :username, unique: true
  end
end
