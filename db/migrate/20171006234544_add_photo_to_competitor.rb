class AddPhotoToCompetitor < ActiveRecord::Migration[5.1]
  def change
    add_column :competitors, :photo, :string
  end
end
