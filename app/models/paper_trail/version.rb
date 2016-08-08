# == Schema Information
#
# Table name: versions
#
#  id             :integer          not null, primary key
#  item_type      :string           not null
#  item_id        :integer          not null
#  event          :string           not null
#  whodunnit      :string
#  object         :text(1073741823)
#  created_at     :datetime
#  object_changes :text(1073741823)
#
# Indexes
#
#  index_versions_on_item_type_and_item_id  (item_type,item_id)
#

module PaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern

    has_many :course_task_relations, foreign_key: :version_id
    has_many :course_tasks, through: :course_task_relations, source: :crawl_task

    # a PaperTrail::Version would only have one corresponding course_task
    # we build many-to-many relationship in order not to ruin the PaperTrail database schema
    def course_task
      course_tasks.first
    end

    # delgate course_errors to relation object
    def course_errors
      course_task_relations.first.course_errors
    end

    def course_errors_size
      course_task_relations.first.course_errors.size
    end

  end
end
