class Crawler < ActiveRecord::Base

  before_create :setup
  has_many :rufus_jobs
  has_many :courses, foreign_key: :organization_code, primary_key: :organization_code

  store :setting, accessors: [ :schedule ]

  SCHEDULE_KEYS = [:at, :in, :every, :cron]
  API_MANAGEMENT_KEYS = [:description, :data_management_api_endpoint, :data_management_api_key, :data_name, :category]
  TEST_SETTING_KEYS = [ :save_to_db, :sync ]

  def klass
    CourseCrawler.get_crawler self.name
  end

  def short_org
    self.organization_code.downcase
  end

  def run_up(job_type, args={})
    time_str = self.schedule[job_type]
    return nil if time_str.nil? || time_str.empty?

    j = Rufus::Scheduler.s.send(:"schedule_#{job_type}", time_str) do
      Sidekiq::Client.push(
        'queue' => self.name,
        'class' => CourseCrawler::Worker,
        'args' => [
          self.name,
          args
        ]
      )
    end
    self.rufus_jobs.create(jid: j.id, type: job_type.to_s, original: j.original)

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
