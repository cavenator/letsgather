class AddPhoneNumberToEvents < ActiveRecord::Migration
  def change
		add_column :events, :contact_number, :string
  end
end
