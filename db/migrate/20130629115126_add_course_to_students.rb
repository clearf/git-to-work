class AddCourseToStudents < ActiveRecord::Migration
  def change
    add_column :students, :course, :string
  end
end
