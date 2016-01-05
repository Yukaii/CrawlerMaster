# t.string   "name"
# t.string   "short_name"
# t.string   "class_name"
# t.string   "organization_code"
# t.string   "setting"
# t.datetime "created_at",                                   null: false
# t.datetime "updated_at",                                   null: false
# t.string   "data_management_api_endpoint"
# t.string   "data_management_api_key"
# t.string   "data_name"
# t.boolean  "save_to_db",                   default: false
# t.boolean  "sync",                         default: false
# t.string   "category"
# t.string   "description"
# t.integer  "year"
# t.integer  "term"

class Crawler < ActiveRecord::Base

  before_create :setup
  has_many :rufus_jobs
  has_many :courses, foreign_key: :organization_code, primary_key: :organization_code

  store :setting, accessors: [ :schedule ]

  SCHEDULE_KEYS = [:at, :in, :every, :cron]
  API_MANAGEMENT_KEYS = [:year, :term, :description, :data_management_api_endpoint, :data_management_api_key, :data_name, :category]
  TEST_SETTING_KEYS = [ :save_to_db, :sync ]

  def klass
    CourseCrawler.get_crawler self.name
  end

  def short_org
    self.organization_code.downcase
  end

  def run_up(job_type, args={}, year=self.year, term=self.term)
    time_str = self.schedule[job_type]
    return nil if time_str.nil? || time_str.empty?

    default_args = {
      year: year,
      term: term
    }
    default_args.merge!(args)

    j = Rufus::Scheduler.s.send(:"schedule_#{job_type}", time_str) do
      Sidekiq::Client.push(
        'queue' => self.name,
        'class' => CourseCrawler::CourseWorker,
        'args' => [
          self.name,
          args
        ]
      )
    end
    self.rufus_jobs.create(jid: j.id, type: job_type.to_s, original: j.original)

    j
  end

  def sync_to_core(year=self.year, term=self.term)
    j = Rufus::Scheduler.s.send(:"schedule_in", '1s') do
    Sidekiq::Client.push(
      'queue' => "CourseCrawler::CourseSyncWorker",
      'class' => CourseCrawler::CourseSyncWorker,
      'args' => [
        org:        self.organization_code,
        year:       year,
        term:       term,
        class_name: self.class.to_s
      ]
    )
    end
    self.rufus_jobs.create(jid: j.id, type: 'in', original: j.original)

    j
  end

  private

  def setup
    klass                  = CourseCrawler.get_crawler self.name

    self.class_name        = klass.name
    self.organization_code = self.name.match(/(.+?)CourseCrawler/)[1].upcase
    self.schedule          = {}
  end

end
