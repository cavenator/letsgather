class CreateSuggestions < ActiveRecord::Migration
  def change
    create_table :suggestions do |t|
			t.integer  :event_id
			t.string  :new_or_existing
			t.string  :requester_name
			t.string  :requester_email
			t.string  :category
			t.text    :suggested_items
      t.timestamps
    end
  end
end
