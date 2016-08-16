class ChangeCourseColumn < ActiveRecord::Migration
  def change
    # check using command:
    # => Course.all.group(:ucode, :organization_code).having('COUNT(courses.ucode) > 1').pluck(:organization_code).uniq
    # in rails console before migration, it will list all duplicate organization codes
    # destroy those courses using
    # => Course.where(organization_code: ['NTUST', 'YUNTECH']).destroy_all
    # to fix them, then run rake db:migrate again
    remove_index :courses, column: :ucode
    add_index    :courses, :ucode, unique: true
  end
end
