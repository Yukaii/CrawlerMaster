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

    def start_time
      utc_format_str(start_at)
    end

    def end_time
      utc_format_str(end_at)
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

    def utc_format_str(time)
      time.getutc.iso8601.gsub(/[-:]/, '')
    end
  end
end
