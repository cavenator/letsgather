class AddEventAndThemeToEvents < ActiveRecord::Migration
  def change
		add_column :events, :description, :text
		add_column :events, :theme, :string
  end
end
