class CreateCoursePeriods < ActiveRecord::Migration
  def change
    create_table :course_periods do |t|
      t.string  :organization_code, null: false
      t.string  :code
      t.integer :order
      t.string  :time

      t.timestamps
    end
  end
end
