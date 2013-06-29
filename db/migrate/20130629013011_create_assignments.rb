class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.string :title
      t.text :description
      t.string :github_login
      t.string :github_repo
      t.datetime :assigned_date
      t.datetime :due_date

      t.timestamps
    end
  end
end
