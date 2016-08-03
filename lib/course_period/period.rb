module CoursePeriod
  class Period
    attr_accessor :order, :code, :time, :start_at, :end_at

    def initialize(row)
      self.order, self.code, self.time = row
      self.order = order.to_i

      self.start_at, self.end_at = time.split('-').map { |s| Time.zone.parse(s) }

      validate_time
    end

    def validate_time
      # a full time string should match something like "10:10-11:30"
      time_regex = /\d{2}\:\d{2}\-\d{2}\:\d{2}/
      raise InvalidTimeFormat unless time.match(time_regex)
    end

    def start_time(date)
      utc_format_str(merge_date(date, start_at))
    end

    def end_time(date)
      utc_format_str(merge_date(date, end_at))
    end

    def to_s
      {
        order: order,
        code: code,
        start_at: start_at,
        end_at: end_at
      }.to_s
    end

    private

    def merge_date(date, time)
      DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time.zone)
    end

    def utc_format_str(time)
      time.getutc.iso8601.gsub(/[-:]/, '')
    end
  end
end
