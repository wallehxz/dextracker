class CreateSnapshots < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.integer :exchange_id
      t.string  :period
      t.string  :time_stamp
      t.float   :estimate

      t.timestamps null: false
    end
  end
end
