# == Schema Information
#
# Table name: crawl_tasks
#
#  id                :integer          not null, primary key
#  type              :integer          default(0), not null
#  finished_at       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  course_year       :integer
#  course_term       :integer
#  organization_code :string
#
# Indexes
#
#  index_crawl_tasks_on_course_term        (course_term)
#  index_crawl_tasks_on_course_year        (course_year)
#  index_crawl_tasks_on_organization_code  (organization_code)
#  index_crawl_tasks_on_type               (type)
#

class CrawlTask < ActiveRecord::Base
  has_many :course_task_relations, foreign_key: :task_id
  has_many :course_versions, through: :course_task_relations, source: :version

  belongs_to :crawler, foreign_key: :organization_code, primary_key: :organization_code

  enum type: [:crawler, :import]

  validates :organization_code, :course_year, :course_term, presence: true

  self.inheritance_column = :_type_disabled

  def generate_snapshot(errors_only: false)
    filename = "#{course_year}_#{course_term}_#{organization_code}_course_snapshot_#{created_at.strftime('%Y%m%d-%H%M')}.xls"
    order_map = CoursePeriod.find!(organization_code).order_map

    book = Spreadsheet::Workbook.new

    sheet = book.create_worksheet(name: created_at.strftime('%Y%m%d-%H%M'))
    sheet.update_row(0, *Course::COLUMN_NAMES.map(&:to_s))

    select_course_versions(errors_only).find_each.with_index do |version, index|
      course_snapshot = version.reify.nil? ? version.item : version.reify
      row = Course::COLUMN_NAMES.map do |key|
        if key.to_s.include?('period')
          course_snapshot.send(key) && order_map[course_snapshot.send(key)]
        else
          course_snapshot.send(key)
        end
      end
      sheet.update_row(index + 1, *row)
    end

    yield(book, filename)
  end

  def select_course_versions(errors_only)
    return course_versions unless errors_only

    # TODO: improve SQL statement
    PaperTrail::Version.where(id: CourseTaskRelation.joins(:version, :course_errors) \
                                                    .where('versions.id in (?)', course_versions.pluck(:id)) \
                                                    .group('course_errors.relation_id') \
                                                    .having('COUNT(course_errors.relation_id) > 0').pluck(:version_id))
  end
end
