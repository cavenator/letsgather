class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
			t.integer   :user_id
			t.string    :name
			t.text      :email_distribution_list
      t.timestamps
    end
  end
end
