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

  FILENAME_REGEX = /^\d{4}_\d_[A-Z]+?_course_snapshot_/

  def generate_snapshot(errors_only: false)
    filename = [
      course_year,
      course_term,
      organization_code,
      'course_snapshot',
      created_at.strftime('%Y%m%d-%H%M')
    ].join('_').concat('.xls')

    order_map = CoursePeriod.find!(organization_code).order_map

    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name: created_at.strftime('%Y%m%d-%H%M'))
    sheet.update_row(0, *Course::COLUMN_NAMES.map(&:to_s))

    select_course_versions(errors_only).find_each.with_index do |version, index|
      course_snapshot = version.reify.nil? ? Course.new_from_changeset(version.changeset) : version.reify
      row = Course::COLUMN_NAMES.map do |key|
        if key.to_s.include?('period')
          course_snapshot.send(key) && order_map[course_snapshot.send(key)]
        else
          course_snapshot.send(key)
        end
      end
      sheet.update_row(index + 1, *row) # start fromm row 1, row 0 is the header row
    end

    [book, filename]
  end

  def self.from_file(path)
    course_year, course_term, organization_code, = File.basename(path, '.xls').split('_')

    code_map = CoursePeriod.find!(organization_code).code_map
    task = create!(
      type: :import,
      course_year: course_year,
      course_term: course_term,
      organization_code: organization_code
    )

    sheet = Spreadsheet.open(path).worksheet(0)

    ActiveRecord::Base.transaction do
      sheet.each_with_index do |row, row_index|
        next if row_index.zero?
        course = Course.where(
          year: row[Course::COLUMN_NAMES.index(:year)],
          term: row[Course::COLUMN_NAMES.index(:term)],
          organization_code: organization_code,
          code: row[Course::COLUMN_NAMES.index(:code)],
          lecturer: row[Course::COLUMN_NAMES.index(:lecturer)],
          name: row[Course::COLUMN_NAMES.index(:name)]
        ).first_or_initialize.tap do |new_course|
          Course::COLUMN_NAMES.each_with_index do |key, column_index|
            if key.to_s.include?('period')
              new_course.send(:"#{key}=", code_map[row[column_index]])
            else
              new_course.send(:"#{key}=", row[column_index])
            end
          end
        end

        if course.new_record? || course.changed?
          course.save!
          task.course_versions << course.versions.last
        end
      end

      task.update(finished_at: Time.zone.now)
    end

    yield(task)
  end

  def select_course_versions(errors_only)
    return course_versions unless errors_only

    # TODO: improve SQL statement
    PaperTrail::Version.where(id: CourseTaskRelation.joins(:version, :course_errors) \
                                                    .where('versions.id in (?)', course_versions.pluck(:id)) \
                                                    .group('course_errors.relation_id, course_task_relations.version_id') \
                                                    .having('COUNT(course_errors.relation_id) > 0').pluck(:version_id)).includes(:item)
  end
end
