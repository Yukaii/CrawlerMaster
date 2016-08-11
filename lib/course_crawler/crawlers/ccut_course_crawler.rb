# 中州科技大學
# 課程查詢網址：http://schinfo.ccut.edu.tw/comm_class.php?Year=104

module CourseCrawler::Crawlers
class CcutCourseCrawler < CourseCrawler::Base

  # PERIODS = {
  #   "1" => 1,
  #   "2" => 2,
  #   "3" => 3,
  #   "4" => 4,
  #   "5" => 5,
  #   "6" => 6,
  #   "7" => 7,
  #   "8" => 8,
  #   "9" => 9,
  #   "10" => 10,
  #   "11" => 11,
  #   "12" => 12,
  #   "13" => 13,
  #   "14" => 14,
  #   "15" => 15
  #   }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://schinfo.ccut.edu.tw/'
  end

  def courses
    @courses = []
    @credit_data = {}

    r = RestClient.get(@query_url+"comm_class.php?Year=#{@year-1911}&Sem=#{@term}")
    doc = Nokogiri::HTML(r)

    doc.css('select[name="Div"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |d_n|
      r = RestClient.post(@query_url+"comm_class.php", {
        "Year" => @year-1911,
        "Sem" => @term,
        "Div" => d_n,
        })
      doc = Nokogiri::HTML(r)

      doc.css('select[name="Class"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v, dept_n|
        r = RestClient.post(@query_url+"comm_class.php", {
          "Year" => @year-1911,
          "Sem" => @term,
          "Div" => d_n,
          "Class" => dept_v
          })
        doc = Nokogiri::HTML(r)

        scan_courses(doc,dept_v,dept_n)
      end
    end

    @courses
  end

  def scan_courses course_table,dept_v,dept_n
    credit_data = nil

    if @credit_data[dept_v[1..2]] == nil
      r = RestClient.post(@query_url+"comm_course.php", {
        "Dept" => dept_v[1..2],
        "Key" => "",
        "PageNum" => "1",
        })
      doc = Nokogiri::HTML(r)
      credit_data = get_credit(doc)

      credit_data = switch_page(credit_data,doc,dept_v)

      @credit_data[dept_v[1..2]] = credit_data
    else
      credit_data = @credit_data[dept_v[1..2]]
    end

    mix_courses(course_table,credit_data,dept_v,dept_n)
  end

  def get_credit doc
    credit_data = {}
    doc.css('table table tr:nth-child(n+2)').each do |tr|
      credit_data_temp = tr.css('td')[0..4].map{|td| td.text.gsub(/[\r\n\s]/,'')}
      credit_data[credit_data_temp[1]] = credit_data_temp
    end
    credit_data
  end

  def switch_page credit_data,doc,dept_v
    doc.css('select[name="PageNum"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |page|
      r = RestClient.post(@query_url+"comm_course.php", {
        "Dept" => dept_v[1..2],
        "Key" => "",
        "PageNum" => page,
        })
      doc = Nokogiri::HTML(r)

      credit_data = credit_data.merge(get_credit(doc))
    end
    credit_data
  end

  def mix_courses course_table,credit_data,dept_v,dept_n
    day = 0
    period = 1
    data = {}

    course_table.css('table table tr:nth-child(n+2) td:nth-child(n+2)').map{|td| td.text.scan(/(\w+)([\W\(\)]+)(\w+)(\W+)/)[0]}.each do |data_temp|
      if day < 7
        day += 1
      else
        day = 1
        period += 1
      end

      next if data_temp == nil

      if data[data_temp[0]] == nil
        data[data_temp[0]] = [data_temp[1],data_temp[3],[[day,period,data_temp[2]]]]
        data[data_temp[0]][3..7] = credit_data[data_temp[1]]
      else
        data[data_temp[0]][2] += [[day,period,data_temp[2]]]
      end
    end

    data.each do |course_code,data|

      course_days, course_periods, course_locations = [], [], []
      data[2].each do |day,period,loc|
        course_days << day
        course_periods << period
        course_locations << loc
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[0],    # 課程名稱
        lecturer: data[1],    # 授課教師
        credits: data[6].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{data[3]}_#{course_code}",
        general_code: course_code,    # 選課代碼
        url: nil,    # 課程大綱之類的連結
        required: nil, # course_type.include?('必'),    # 必修或選修
        department: dept_n,    # 開課系所
        # department_code: dept_v,
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

end
end
