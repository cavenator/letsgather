class AddMoreEventAttributes < ActiveRecord::Migration
  def change
		add_column :events, :user_id, :integer
		add_column :events, :supplemental_info, :text
  end
end
