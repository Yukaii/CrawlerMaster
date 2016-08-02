require 'csv'

module CoursePeriod
  DATA_PATH = File.join(File.dirname(__FILE__), 'course_period/data')

  def self.find!(organization_code)
    raise PeriodNotFound unless File.exist?(csv_path(organization_code))
    Record.new(csv_path(organization_code))
  end

  def self.find(organization_code)
    return nil unless File.exist?(csv_path(organization_code))
    Record.new(csv_path(organization_code))
  end

  def self.csv_path(organization_code)
    File.join(DATA_PATH, "#{organization_code.downcase}.csv")
  end

  class << self
    private :csv_path
  end

end
