class CreateMessage < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.text :content
      t.string :file
    end
  end
end
