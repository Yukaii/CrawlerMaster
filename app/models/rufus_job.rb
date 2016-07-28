# == Schema Information
#
# Table name: rufus_jobs
#
#  id         :integer          not null, primary key
#  jid        :string
#  crawler_id :integer
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  original   :string
#

class RufusJob < ActiveRecord::Base
  belongs_to :crawler
  after_initialize :check_existance

  self.inheritance_column = :_type_disabled

  def job_instance
    jid && Rufus::Scheduler.s.job(jid)
  end

  def original
    job_instance && job_instance.original
  end

  def last_time
    job_instance && job_instance.last_time
  end

  def scheduled_at
    job_instance && job_instance.scheduled_at
  end

  def running?
    job_instance && job_instance.running?
  end

  def check_existance
    jid && !job_instance && destroy
  end

  def unschedule
    job_instance && job_instance.unschedule
  end
end
