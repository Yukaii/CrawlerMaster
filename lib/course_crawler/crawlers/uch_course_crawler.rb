# 健行科技大學
# 課程查詢網址：http://cos.uch.edu.tw/course_info/pubinfomain/pubinfomain.html

module CourseCrawler::Crawlers
class UchCourseCrawler < CourseCrawler::Base

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://cos.uch.edu.tw/course_info/'
  end

  def courses
    @courses = []
    r = RestClient.get(@query_url+"pubinfomain/Dept.aspx")
    doc = Nokogiri::HTML(r)

    course_id = 0

    doc.css('deptno').map{|d| d[:dept_no]}.each do |dept|
      r = RestClient.get(@query_url+"pubinfomain/CourseList.aspx?type=&dept=#{dept}&year=&smtr=#{@year-1911}#{@term}&strtext=")
      doc = Nokogiri::HTML(r)

      doc.css('coslist').map{|c| [c[:cos_id], c[:cos_class]]}.each do |cor|
        syllabus_url = URI.escape(@query_url+"JS/CourseDetail.aspx?smtr=#{@year-1911}#{@term}&cos_id=#{cor[0]}&class=#{cor[1]}")

        r = RestClient.get(syllabus_url)
        doc = Nokogiri::HTML(r)

        course_id += 1

        dep_name = doc.css('detail1').map{|d| d[:dep_name]}[0]
        cname_tname_credits_required = doc.css('detail1').map{|d| [d[:cos_cname],d[:teacher_name],d[:cos_credit],d[:cos_sel_type]]}[0]
        course_time_location = doc.css('detail2').map{|d| [d[:schd_time],d[:schd_room_id]]}

        course_days, course_periods, course_locations = [], [], []
        course_time_location.each do |ctl|
          ctl[0].scan(/(?<day>\d)(?<period>\d\d)/).each do |time|
            course_days      << time[0].to_i
            course_periods   << time[1].to_i
            course_locations << ctl[1]
          end
        end

        course = {
          :year             => @year,    # 西元年
          :term             => @term,    # 學期 (第一學期=1，第二學期=2)
          :name             => cname_tname_credits_required[0],    # 課程名稱
          :lecturer         => cname_tname_credits_required[1],    # 授課教師
          :credits          => cname_tname_credits_required[2].to_i,    # 學分數
          :code             => "#{@year}-#{@term}-#{course_id}_#{cor[0].scan(/\w+/)[0]}",
          :general_code     => cor[0].scan(/\w+/)[0],    # 選課代碼
          :url              => syllabus_url,    # 課程大綱之類的連結
          :required         => cname_tname_credits_required[3].include?('A'),    # 必修或選修
          :department       => dep_name,    # 開課系所
          # department_code => dept,
          :day_1            => course_days[0],
          :day_2            => course_days[1],
          :day_3            => course_days[2],
          :day_4            => course_days[3],
          :day_5            => course_days[4],
          :day_6            => course_days[5],
          :day_7            => course_days[6],
          :day_8            => course_days[7],
          :day_9            => course_days[8],
          :period_1         => course_periods[0],
          :period_2         => course_periods[1],
          :period_3         => course_periods[2],
          :period_4         => course_periods[3],
          :period_5         => course_periods[4],
          :period_6         => course_periods[5],
          :period_7         => course_periods[6],
          :period_8         => course_periods[7],
          :period_9         => course_periods[8],
          :location_1       => course_locations[0],
          :location_2       => course_locations[1],
          :location_3       => course_locations[2],
          :location_4       => course_locations[3],
          :location_5       => course_locations[4],
          :location_6       => course_locations[5],
          :location_7       => course_locations[6],
          :location_8       => course_locations[7],
          :location_9       => course_locations[8],
        }

        @after_each_proc.call(course: course) if @after_each_proc

        @courses << course
      end
    end

    @courses
  end

end
end
