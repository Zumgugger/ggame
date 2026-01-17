class AddHiddenUntilToEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :hidden_until, :datetime
  end
end
