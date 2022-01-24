class ChangeColumnToTradesNumber < ActiveRecord::Migration
  def change
    change_column :trades, :number, :string
  end
end
