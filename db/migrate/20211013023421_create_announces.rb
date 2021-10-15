class CreateAnnounces < ActiveRecord::Migration
  def change
    create_table :announces do |t|
      t.string :title
      t.string :link
      t.string :source

      t.timestamps null: false
    end
  end
end
