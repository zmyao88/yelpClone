class CreateBusinesses < ActiveRecord::Migration
  def change
    create_table :businesses do |t|
      t.integer :country_id, null: false
      t.string :name, null: false
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.integer :zip_code
      t.string :phone_number
      t.string :website
      t.float :rating
      t.integer :category1_id
      t.integer :category2_id
      t.integer :category3_id

      t.timestamps
    end

    add_index :businesses, :name
  end
end