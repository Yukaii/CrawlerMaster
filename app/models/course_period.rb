# == Schema Information
#
# Table name: course_periods
#
#  id                :integer          not null, primary key
#  organization_code :string           not null
#  code              :string
#  order             :integer
#  time              :string
#  created_at        :datetime
#  updated_at        :datetime
#

class CoursePeriod < ActiveRecord::Base
  default_scope { order(order: :asc) }

  validate :validate_time

  after_initialize :parse_time

  attr_accessor :start_at, :end_at

  def parse_time
    self.start_at, self.end_at = time.split('-').map { |s| Time.zone.parse(s) }
  end

  def validate_time
    # time string should match "10:10", two digits seperate by a colon
    time_regex = /\d{2}\:\d{2}/
    errors.add(:time, 'time format error') if !time.include?('-') || !start_at.match(time_regex) || !end_at.match(time_regex)
  end

  def start_time
    utc_format_str(start_at)
  end

  def end_time
    utc_format_str(end_at)
  end

  private

  def utc_format_str(time)
    time.getutc.iso8601.gsub(/[-:]/, '')
  end
end
