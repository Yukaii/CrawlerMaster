#桃園銘傳大學
#使用到McuBaseCrawler

module CourseCrawler::Crawlers
class McutyCourseCrawler < McuBaseCrawler
  alias old_courses courses

  def initialize *args
    super *args
    @args = args
  end

  def courses *args
    @courses = send(:old_courses, *args)

    @courses.select do |course|
      course[:location_1].include?('桃園')
    end
  end

end
end
