class CreateTrades < ActiveRecord::Migration
  def change
    create_table :trades do |t|
      t.integer :market_id
      t.integer :period
      t.integer :number
      t.string  :cate
      t.float   :amount
      t.float   :price
      t.float   :total
      t.string  :timestamp
      t.datetime :completed_at
    end
  end
end
