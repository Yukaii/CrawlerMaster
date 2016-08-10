# == Schema Information
#
# Table name: crawlers
#
#  id                           :integer          not null, primary key
#  name                         :string
#  short_name                   :string
#  class_name                   :string
#  organization_code            :string
#  setting                      :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  data_management_api_endpoint :string
#  data_management_api_key      :string
#  data_name                    :string
#  save_to_db                   :boolean          default(TRUE)
#  sync                         :boolean          default(FALSE)
#  category                     :string
#  description                  :string
#  year                         :integer
#  term                         :integer
#  last_sync_at                 :datetime
#  courses_count                :integer
#  last_run_at                  :datetime
#

class Crawler < ActiveRecord::Base
  include CourseCrawler::Mixin

  has_many :rufus_jobs
  has_many :courses, foreign_key: :organization_code, primary_key: :organization_code
  has_many :crawl_tasks, primary_key: :organization_code, foreign_key: :organization_code

  store :setting, accessors: [:schedule]

  SCHEDULE_KEYS = [
    :at,
    :in,
    :every,
    :cron
  ].freeze

  API_MANAGEMENT_KEYS = [
    :year,
    :term,
    :description,
    :data_management_api_endpoint,
    :data_management_api_key,
    :data_name,
    :category
  ].freeze

  TEST_SETTING_KEYS = [
    :save_to_db,
    :sync
  ].freeze

  def klass
    CourseCrawler.get_crawler(name)
  end

  def short_org
    organization_code.downcase
  end

  def run_up(job_type, args = {}, year = self.year, term = self.term)
    time_str = schedule[job_type]
    return nil if time_str.nil? || time_str.empty?

    default_args = {
      year: year,
      term: term
    }
    default_args.merge!(args)

    j = Rufus::Scheduler.s.send(:"schedule_#{job_type}", time_str) do
      Sidekiq::Client.push(
        'queue' => name,
        'class' => CourseCrawler::CourseWorker,
        'args' => [
          name,
          default_args
        ]
      )
    end

    rufus_jobs.create(jid: j.id, type: job_type.to_s, original: j.original)

    j
  end

  def sync_to_core(year = year, term = term)
    j = Rufus::Scheduler.s.send(:schedule_in, '1s') do
      Sidekiq::Client.push(
        'queue' => 'CourseCrawler::CourseSyncWorker',
        'class' => CourseCrawler::CourseSyncWorker,
        'args' => [
          organization_code,
          year,
          term
        ]
      )
    end

    rufus_jobs.create(jid: j.id, type: 'in', original: j.original)

    j
  end

  before_create :setup
  def setup
    klass                  = CourseCrawler.get_crawler(name) if name.present?
    self.class_name        = klass.name if klass.present?
    self.organization_code = name.match(/(.+?)CourseCrawler/)[1].upcase if name.present?

    self.schedule          = { in: '1s' }
    self.year              = current_year
    self.term              = current_term
  end

end
