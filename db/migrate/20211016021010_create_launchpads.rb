class CreateLaunchpads < ActiveRecord::Migration
  def change
    create_table :launchpads do |t|
      t.integer   :exchange_id
      t.string    :base
      t.string    :quote
      t.string    :state
      t.float     :funds
      t.datetime  :launch_at

      t.timestamps null: false
    end
  end
end
