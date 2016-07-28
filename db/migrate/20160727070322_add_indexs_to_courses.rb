class AddIndexsToCourses < ActiveRecord::Migration
  def change
    add_index :courses, :organization_code
    add_index :courses, :year
    add_index :courses, :term
    add_index :courses, :code
    add_index :courses, :required
  end
end
