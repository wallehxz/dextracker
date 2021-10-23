class AddBidPriceToLaunchpads < ActiveRecord::Migration
  def change
    add_column :launchpads, :limit_bid, :float, default: 0
  end
end
