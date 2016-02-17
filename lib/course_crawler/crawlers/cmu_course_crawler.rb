# 中國醫藥大學
# 課程查詢網址：http://web1.cmu.edu.tw/courseinfo/

module CourseCrawler::Crawlers
class CmuCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "A" => 10,
    "B" => 11,
    "C" => 12,
    "D" => 13,
    "E" => 14
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://web1.cmu.edu.tw/courseinfo/'
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url+"get_dept.asp?cos_year=#{@year-1911}&cos_smtr=#{@term}&ref_type=&i18n=zh")
    doc = Nokogiri::HTML(r)

    doc.css('select[id="dept_no_q"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v,dept_n|

      r = RestClient.post(@query_url+"courselist.asp",{
        "i18n" => "ref_dept.dept_name",
        "cos_setyear_q" => @year-1911,
        "cos_setterm_q" => @term,
        "type_no_q" => "",
        "dept_no_q" => dept_v,
        "cos_year_q" => "",
        "cos_sel_type_q" => "",
        "cos_id_q" => "",
        "cos_name_q" => "",
        "teacher_name_q" => "",
        "class_name_q" => "",
        "GE_Requirements" => "ALL",
        "UCAN_mtype" => "ALL",
        "cos_week_S_q" => "",
        "cos_week_E_q" => "",
        "cos_sec_S_q" => "",
        "cos_sec_E_q" => "",
        "Qry" => "送出查詢",
        })
      doc = Nokogiri::HTML(r)

      data, swich = nil, true # 在迴圈外設變數，讓資料可以沿用
      course_days, course_periods, course_locations = [], [], []
      (0..doc.css('table:nth-child(6) tr:nth-child(n+3)').count-1).each do |count|
        data_temp = doc.css('table:nth-child(6) tr:nth-child(n+3)')[count].css('td').map{|td| td.text}
        if doc.css('table:nth-child(6) tr:nth-child(n+3)')[count+1] != nil
          data_next = doc.css('table:nth-child(6) tr:nth-child(n+3)')[count+1].css('td').map{|td| td.text}
        else
          data_next = data_temp
        end

        if data == nil
          data = data_temp
          data[17] = @query_url+doc.css('table:nth-child(6) tr:nth-child(n+3)')[count].css('td:nth-child(3) a')[0][:href]

          course_time = data[10..15]+[data[9]]

          day = 0
          course_time.each do |period|
            day += 1
            period.scan(/\w/).each do |p|
              course_days << day
              course_periods << PERIODS[p]
              course_locations << data[8]
            end
          end
        elsif data_temp.count < 12

          if data[7].include?(data_temp[1])
            if swich == true
              course_time = data_temp[4..9]+[data_temp[3]]

              day = 0
              course_time.each do |period|
                day += 1
                period.scan(/\w/).each do |p|
                  course_days << day
                  course_periods << PERIODS[p]
                  course_locations << data_temp[2]
                end
              end
            end
          else
            data[7] = "#{data[7]},#{data_temp[1]}"
            swich = false
          end
        end

        if data_next.count > 11
          course_id += 1

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[2],    # 課程名稱
            lecturer: data[7],    # 授課教師
            credits: data[5].to_i,    # 學分數(需要轉換成數字，可以用.to_i)
            code: "#{@year}-#{@term}-#{course_id}_#{data[1].split("/")[0]}",
            general_code: data[1].split("/")[0],    # 選課代碼
            url: data[17],    # 課程大綱之類的連結
            required: data[3].include?('必'),    # 必修或選修
            department: data[0],    # 開課系所
            # department_code: department_code,
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

# binding.pry if course_id == 9
          course_days, course_periods, course_locations = [], [], []
          swich = true
          data = nil
        end
      end
    end
    @courses
  end
end
end