require 'csv'

module CoursePeriod
  DATA_PATH = File.join(File.dirname(__FILE__), 'course_period/data')

  def self.find(organization_code)
    load_csv(organization_code)
  end

  def self.load_csv(organization_code)
    period_file_name = File.join(DATA_PATH, "#{organization_code.downcase}.csv")
    return nil unless File.exist?(period_file_name)

    CSV.read(period_file_name).map do |row|
      Period.new(row)
    end
  end

  class << self
    private :load_csv
  end

end
