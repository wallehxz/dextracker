class CreateClimaxes < ActiveRecord::Migration
  def change
    create_table :climaxes do |t|
      t.string :market
      t.decimal :volumes
      t.integer :magnife

      t.timestamps null: false
    end
  end
end
