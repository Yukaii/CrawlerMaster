class CreateCourseTaskRelations < ActiveRecord::Migration
  def change
    create_table :course_task_relations do |t|
      t.integer :version_id
      t.integer :task_id

      t.timestamps null: false
    end

    add_index :course_task_relations, :version_id
    add_index :course_task_relations, :task_id
    add_index :course_task_relations, [:task_id, :version_id], unique: true
  end
end
