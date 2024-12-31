class CreateGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :groups do |t|
      t.string :name
      t.integer :points
      t.boolean :false_information
      t.integer :kopfgeld
      t.integer :sort_order

      t.timestamps
    end
  end
end
