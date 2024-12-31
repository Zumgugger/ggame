class CreateTargets < ActiveRecord::Migration[7.2]
  def change
    create_table :targets do |t|
      t.string :name
      t.string :description
      t.integer :points, default: 100
      t.integer :mines, default: 0
      t.integer :count, default: 0
      t.datetime :last_action
      t.string :village
      t.integer :sort_order

      t.timestamps
    end
  end
end
