class AddUsersWithAuthentication < Jennifer::Migration::Base
  def up
    create_table :personas do |t|
      t.string :email, {:null => false}
      t.string :password_digest, {:null => false}
      t.string :type, {:null => false, :default => "User"}
      t.string :api_key, {:null => false, :default => ""}
      t.string :api_secret, {:null => false, :default => ""}
      t.date :last_login_at
      t.timestamps
    end

    add_index :personas, :email
  end

  def down
    drop_table :personas
  end
end
