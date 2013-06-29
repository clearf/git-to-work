class CreateContributions < ActiveRecord::Migration
  def change
    create_table :contributions do |t|
      t.integer :assignment_id
      t.integer :student_id
      t.datetime :contribution_created_at
      t.datetime :contribution_updated_at
      t.string :status

      t.timestamps
    end
  end
end
