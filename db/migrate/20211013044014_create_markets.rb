class CreateMarkets < ActiveRecord::Migration
  def change
    create_table :markets do |t|
      t.integer :exchange_id
      t.string :quote
      t.string :base

      t.timestamps null: false
    end
  end
end
