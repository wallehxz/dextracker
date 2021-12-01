class CreatePeriods < ActiveRecord::Migration
  def change
    create_table :periods do |t|
      t.integer :market_id
      t.integer :period
      t.string  :state
      t.float   :amount
      t.float   :bid_qty
      t.float   :ask_qty
      t.timestamps null: false
    end
  end
end
