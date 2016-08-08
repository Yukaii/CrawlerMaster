class CreateCourseErrors < ActiveRecord::Migration
  def change
    create_table :course_errors do |t|
      t.integer :type
      t.string :message
      t.integer :relation_id

      t.timestamps null: false
    end
  end
end
