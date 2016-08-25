##
# 明道大學
# http://isc.mdu.edu.tw/net/cosinfo/pubinfomain.asp
# 節次資料： http://www.mdu.edu.tw/~oaa/CD/selectclass/ht3post/1051/1051.pdf

module CourseCrawler::Crawlers
class MduCourseCrawler < CourseCrawler::Base
  def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    @year = year
    @term = term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://isc.mdu.edu.tw/net/cosinfo/show_class_cos_table.asp"
  end

  def courses
    @courses = []

    puts "get url ..."
    http_client.get_content "http://isc.mdu.edu.tw/net/cosinfo/pubinfomain.asp"

    doc = Nokogiri::HTML(http_client.get_content "http://isc.mdu.edu.tw/net/cosinfo/deptlist.asp")
    depts = doc.css('select[name="selectDepts"] option:not(:first-child)').map{|opt| opt[:value]}
    grades = doc.css('select[name="sel_degree"] option').map{|opt| opt[:value]}

    depts.each do |dept|
    grades.each do |grade|
      puts "data crawled , Department : " + dept + ", Grade : " + grade
      parse_course(Nokogiri::HTML(http_client.get_content(@query_url, {
        :mDept_No   => dept,
        :mDept_year => grade,
        :mSmtr      => "#{@year-1911}#{@term}",
        :mTchName   => ""
      })))
    end; end;
    puts "Project finished !!!"
    @courses
  end

  def parse_course doc

    doc.css('form[name="thisForm"] table[cellspacing="0"] tr:nth-child(n+3)').each do |row|

      datas = row.css('td')

      course_days = []
      course_periods = []
      course_locations = []

      datas[13..19].each do |days|
        next if days.text.empty?

        # days.text => 2(開101),3(開101),4(開101)
        # course_t => [["2", "開101"], ["3", "開101"], ["4", "開101"]]
        course_t = days.text.scan(/(?<per>\d+)\((?<loc>.\d\d\d)\)/)

        course_t.each do |period_data|
          course_days << datas.index(days).to_i - 12
          course_periods << period_data[0].to_i
          course_locations << period_data[1]
        end

      end

      course = {
        name: datas[2].text.strip,
        year: @year,
        term: @term,
        code: "#{@year}-#{@term}-#{power_strip(datas[1].text)}",
        general_code: power_strip(datas[1].text.strip),
        _class: datas[3].text.strip,
        credits: datas[6].text.strip.to_i,
        lecturer: datas[12].text.strip,
        day_1: course_days[0],
        day_2: course_days[1],
        day_3: course_days[2],
        day_4: course_days[3],
        day_5: course_days[4],
        day_6: course_days[5],
        day_7: course_days[6],
        day_8: course_days[7],
        day_9: course_days[8],
        period_1: course_periods[0],
        period_2: course_periods[1],
        period_3: course_periods[2],
        period_4: course_periods[3],
        period_5: course_periods[4],
        period_6: course_periods[5],
        period_7: course_periods[6],
        period_8: course_periods[7],
        period_9: course_periods[8],
        location_1: course_locations[0],
        location_2: course_locations[1],
        location_3: course_locations[2],
        location_4: course_locations[3],
        location_5: course_locations[4],
        location_6: course_locations[5],
        location_7: course_locations[6],
        location_8: course_locations[7],
        location_9: course_locations[8],
      }

      @courses << course
    end
  end

end
end
