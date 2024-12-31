class CreateOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :options do |t|
      t.string :name
      t.integer :count
      t.boolean :active

      t.timestamps
    end
  end
end
