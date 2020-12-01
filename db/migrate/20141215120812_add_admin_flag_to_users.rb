class AddAdminFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :admin, :boolean, default: false

    execute <<-SQL
      UPDATE users SET admin = 't' WHERE login = 'admin'
    SQL
  end
end
