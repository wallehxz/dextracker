class AddPrecisionToMarket < ActiveRecord::Migration
  def change
    add_column :markets, :precision, :integer
  end
end
