# 國立聯合大學
# 課程查詢網址：http://studentaid.nuucloud.com/

# 無法選擇學年度,沒有教師資料,沒有上課地點
module CourseCrawler::Crawlers
class NuuCourseCrawler < CourseCrawler::Base

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://studentaid.nuucloud.com/'
  end

  def courses
    @courses = []

    # 課程時間地點
    r = RestClient.get(@query_url+"search_post.php?seaco=")
    data1 = Nokogiri::HTML(r).css('p')[0].text.split("z")

    # 選課代碼
    data2 = ""
    (1..data1.count).each do |i|
      data2 += "#{i}c"
    end
    r = RestClient.get(@query_url+"listpost.php?data=#{data2}&department=%E7%84%A1%E7%8F%AD%E7%B4%9A%E7%84%A1%E7%8F%AD%E7%B4%9A")
    data2 = Nokogiri::HTML(r).css('table tr:nth-child(n+2) td:nth-child(4)').map{|td| td.text}

    (0..data1.count-1).each do |i|
      data = [data2[i]] + data1[i].split("y")

      course_time = data[6].scan(/([\d])x([\d]+)/)

      course_days, course_periods, course_locations = [], [], []
      course_time.each do |day, period|
        course_days << day.to_i
        course_periods << period.to_i
        course_locations << data[5]
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[2],    # 課程名稱
        lecturer: nil,    # 沒有授課教師
        credits: data[7].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{data[1]}_#{data[0]}",
        general_code: data[0],    # 選課代碼
        url: nil,    # 沒有課程大綱之類的連結
        required: data[4].include?('必'),    # 必修或選修
        department: data[3],    # 開課系所
        # department_code: nil,
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
# binding.pry if data[1] == "100"
    end
    @courses
  end
end
end