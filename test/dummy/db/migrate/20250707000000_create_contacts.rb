# frozen_string_literal: true

class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :email
      t.string :role

      t.timestamps
    end
  end
end
