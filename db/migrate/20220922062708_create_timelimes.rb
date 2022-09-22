class CreateTimelimes < ActiveRecord::Migration
  def change
    create_table :timelimes do |t|
      t.integer :climax_id
      t.float   :o_price
      t.float   :h_price
      t.float   :l_price
      t.float   :c_price
      t.float   :volumes
      t.float   :turnover
      t.float   :base_vols
      t.datetime :completed_at
    end
  end
end
