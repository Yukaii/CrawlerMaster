# 敏惠醫護管理專科學校
# 課程查詢網址：http://school.mhchcm.edu.tw/minhwei_webmis/minhwei_courseqry.asp

module CourseCrawler::Crawlers
class MhchcmCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://school.mhchcm.edu.tw/minhwei_webmis/'
    @ic = Iconv.new('big5//IGNORE//translit', 'utf-8')  # POST需要BIG5碼的中文
  end

  def courses
    @courses = []
    course_id = 0
    puts "get url ..."
    # r = RestClient.get(@query_url+"minhwei_courseqry.asp")
    # doc = Nokogiri::HTML(r)

# 科系是用勾選的，如果有新增或移除需要注意
    r = RestClient.post(@query_url+"minhwei_courseqry2.asp", {
      "ysem" => "#{@year-1911}#{@term}",
      # "ysemt" => "104%BE%C7%A6%7E%B2%C4%A4G%BE%C7%B4%C1",
      "deptsub_1" => "1",
      "deptsub_1_code" => "500",
      "deptsub_2" => "1",
      "deptsub_2_code" => "501",
      "deptsub_3" => "1",
      "deptsub_3_code" => "502",
      "deptsub_4" => "1",
      "deptsub_4_code" => "503",
      "deptsub_5" => "1",
      "deptsub_5_code" => "504",
      "which" => "1",
      "cnt" => "5",
      })
    doc = Nokogiri::HTML(r)

    doc.css('table table tr td a:nth-child(1)').map{|a| a[:href].split('"')}.each do |url_temp|
      puts "data crawled : "+"#{course_id}/#{url_temp[3]}"
      r = RestClient.post(@query_url+"minhwei_courseqry3.asp", {
        "ysem" => "#{@year-1911}#{@term}",
        # "ysemt" => "104%BE%C7%A6%7E%B2%C4%A4G%BE%C7%B4%C1",
        "deptsub" => url_temp[1],
        "cour_cname" => @ic.iconv(url_temp[3]),
        "terms" => url_temp[5],
        })
      doc = Nokogiri::HTML(r)

      doc.css('table table tr[align="center"]').each do |tr|
        data = tr.css('td').map{|td| td.text.gsub(/[\s ]/,'')}
        data[7] = tr.css('td:nth-child(8)').map{|td| td.text.split(" ")[0]}[0]
        post_temp = tr.css('td a').map{|a| a[:href].split('"')}[0]

        r = RestClient.post(@query_url+"minhwei_courseqry4.asp", {
          "ysem" => "#{@year-1911}#{@term}",
          "tech_no" => post_temp[1],
          "cour_no" => post_temp[3],
          "deptyear" => post_temp[5]
          })
        doc = Nokogiri::HTML(r)

        teacher = doc.css('table tr:nth-child(3) td')[1].text.gsub(/[\r\n\s]/,'')

        course_id += 1

        course_time = data[6].scan(/(?<day>[一二三四五六日])(?<period>[\w]+)/)

        course_days, course_periods, course_locations = [], [], []
        course_time.each do |day, period|
          course_days << DAYS[day]
          course_periods << PERIODS[period]
          course_locations << data[7]
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[2],    # 課程名稱
          lecturer: teacher,    # 授課教師
          credits: data[3][0].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{post_temp[3]}",
          general_code: post_temp[3],    # 選課代碼
          url: nil,    # 課程大綱之類的連結
          required: data[4].include?('必'),    # 必修或選修
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
      end
    end
    puts "Project finished !!!"
    @courses
  end
end
end
