class SetKopfgeldToZeroForNilGroups < ActiveRecord::Migration[7.0]
  def change
    Group.where(kopfgeld: nil).update_all(kopfgeld: 0)
  end
end
