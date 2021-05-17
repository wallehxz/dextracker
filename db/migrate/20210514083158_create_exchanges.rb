class CreateExchanges < ActiveRecord::Migration
  def change
    create_table :exchanges do |t|
      t.integer :user_id
      t.string :app_key
      t.string :app_secret
      t.string :type
      t.string :remark

      t.timestamps null: false
    end
  end
end
