class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
			t.integer :user_id
			t.integer :event_id
			t.string  :privilege
      t.timestamps
    end
  end
end
