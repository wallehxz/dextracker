class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :exchange_id
      t.string  :asset
      t.string  :quote
      t.float   :balance
      t.float   :freezen
      t.float   :cost

      t.timestamps null: false
    end
  end
end
