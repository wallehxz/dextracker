class AddStateToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :state, :string
    add_column :orders, :msg,   :string
  end
end
