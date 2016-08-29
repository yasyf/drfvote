class ChangeListsFixPosIndex < ActiveRecord::Migration[5.0]
  def change
    change_table :lists do |t|
      t.remove_index :pos
      t.index [:pos, :trello_board_id], unique: true
    end
  end
end
