# 華梵大學
# 選課網址: http://webcourse.hfu.edu.tw/acadann1.aspx

module CourseCrawler::Crawlers
class HfuCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "早" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "10" => 11,
    "11" => 12,
    "12" => 13,
    "13" => 14
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://webcourse.hfu.edu.tw/AcadWebShow.aspx'
  end

  def courses
    @courses = []

    r = HTTPClient.get(@query_url).body
    doc = Nokogiri::HTML(r)

    doc.css('#ctl00_Label1').text.match(/ (?<year>\d+) 學年度第 (?<term>\d) 學期全校課程表/) do |m|
      @year = m[:year].to_i + 1911
      @term = m[:term].to_i
    end

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    dept_c = -1
    doc.css('ul[id="ctl00_ContentPlaceHolder1_TabContainer1_TabPanel1_ComboBox1_OptionList"] li').map{|li| li.text}.each do |dept_n|
      dept_c += 1

      next if dept_n.include?('---')

      r = HTTPClient.post(@query_url, hidden.merge({
        "ctl00_ContentPlaceHolder1_TabContainer1_ClientState" => "{\"ActiveTabIndex\":0,\"TabState\":[true,true,true,true,true,true]}",
        "__EVENTTARGET" => "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel1$LB_dep",
        # "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel1$ComboBox1$TextBox" => "工管系",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel1$ComboBox1$HiddenField" => dept_c,
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel2$ComboBox2$TextBox" => "--請選擇---",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel2$ComboBox2$HiddenField" => "0",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel2$DDL_Week" => "1",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel2$DDL_Period1" => "0",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel2$DDL_Period2" => "0",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel3$Txt_SubjectName" => "",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel4$Txt_TeacherName" => "",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel5$DDL_Building" => "1",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel5$DDL_Room" => "于",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel6$DDL_OfficeDep" => "00",
        "ctl00$ContentPlaceHolder1$TabContainer1$TabPanel6$Txt_Office_Teacher" => "",
        "hiddenInputToUpdateATBuffer_CommonToolkitScripts" => "1",
        }) ).body
      doc = Nokogiri::HTML(r)

      doc.css('tr[onmouseout="this.style.backgroundColor=currentcolor;"]').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}
        syllabus_url = tr.css('a').map{|a| a[:href]}[0]

        course_days, course_periods, course_locations = [], [], []
        (14..20).each do |day|
          data[day].scan(/(?<period>([\d早]\,)+)(\((?<location>\S+)\))?/).each do |period, location|
            period.split(',').each do |p|
              next if p == nil
              course_days << day - 13
              course_periods << PERIODS[p]
              course_locations << location
            end
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[6],    # 課程名稱
          lecturer: data[9],    # 授課教師
          credits: data[10].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[0]}_#{data[4]}",
          general_code: data[4],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[12].include?('必'),    # 必修或選修
          department: data[13],    # 開課系所
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

        @after_each_proc.call(course: course) if @after_each_proc

        @courses << course
      end
    end
    @courses
  end

end
end
