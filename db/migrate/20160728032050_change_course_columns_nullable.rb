class ChangeCourseColumnsNullable < ActiveRecord::Migration
  def change
    change_column :courses, :lecturer,     :string, null: true
    change_column :courses, :name,         :string, null: true
    change_column :courses, :code,         :string, null: true
    change_column :courses, :general_code, :string, null: true
  end
end
