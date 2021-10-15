class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer :exchange_id
      t.integer :market_id
      t.string :type
      t.float :amount
      t.float :price

      t.timestamps null: false
    end
  end
end
