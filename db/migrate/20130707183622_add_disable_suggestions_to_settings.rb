class AddDisableSuggestionsToSettings < ActiveRecord::Migration
  def change
		add_column :settings, :disable_suggestions, :boolean, :default => false
  end
end
