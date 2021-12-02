class AddPrecisionToMarket < ActiveRecord::Migration
  def change
    add_column :markets, :precision, :integer
    add_column :markets, :pounds, :float
  end
end
