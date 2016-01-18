class RenameLecturerNameToLecturer < ActiveRecord::Migration
  def change
    rename_column :courses, :lecturer_name, :lecturer
  end
end
