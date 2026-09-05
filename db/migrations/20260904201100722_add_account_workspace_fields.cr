class AddAccountWorkspaceFields < Jennifer::Migration::Base
  def up
    change_table(:personas) do |table|
      table.add_column :display_name, :string, {:size => 100, :null => false, :default => ""}
      table.add_column :session_version, :string, {:size => 64, :null => false, :default => ""}
    end
  end

  def down
    change_table(:personas) do |table|
      table.drop_column :display_name
      table.drop_column :session_version
    end
  end
end
