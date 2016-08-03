# == Schema Information
#
# Table name: semester_dates
#
#  id         :integer          not null, primary key
#  year       :integer
#  term       :integer
#  start_date :date
#  end_date   :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

module Colorgy
  class SemesterDate < ColorgyRecord
    self.table_name = 'semester_dates'

    DAYS = {
      1 => 'monday',
      2 => 'tuesday',
      3 => 'wednesday',
      4 => 'thursday',
      5 => 'friday',
      6 => 'saturday',
      7 => 'sunday'
    }.freeze

    def to_rrule_array(day)
      dtstart = nearest_day(day, start_date)

      [
        "DTSTART=#{to_rrule_string(dtstart)}",
        "UNTIL=#{to_rrule_string(end_date)}"
      ]
    end

    def nearest_day(day, now=start_date)
      Chronic.parse(DAYS[day], now: now)
    end

    def to_rrule_string(datetime)
      Time.zone.parse(datetime.to_s).getutc.iso8601.gsub(/[-:]/, '')
    end
  end

end
