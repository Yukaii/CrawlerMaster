# 東南科技大學
# 課程查詢網址：http://info.tnu.edu.tw/comm_index.php

# 這學校不耐爬，伺服器端可能比較弱
module CourseCrawler::Crawlers
class TnuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://info.tnu.edu.tw/Comm_QuerySbj.php'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    doc.css('select[name="Div"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |d_n|
      next if d_n != "1" # 只跑日間部

      r = RestClient.post(@query_url, {
        "D1" => @year-1911,
        "D2" => @term,
        "Div" => d_n,
        "Class" => "---+%BD%D0%BF%EF%BE%DC+---",
        })
      doc = Nokogiri::HTML(r)

      doc.css('select[name="Class"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |cla_v,cla_n|
        r = %x(curl -s 'http://info.tnu.edu.tw/Comm_QuerySbj.php?D1=#{@year-1911}&D2=#{@term}&Div=#{d_n}&Class=#{cla_v}' --compressed)
        # r = RestClient.post(@query_url, {
        #   "D1" => @year-1911,
        #   "D2" => @term,
        #   "Div" => d_n,
        #   "Class" => cla_v,
        #   })
        doc = Nokogiri::HTML(@ic.iconv(r))
        doc.css('table:nth-child(2) tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
# puts cla_v+","+tr.css('td font').map{|td| td.text}[0]
          data = tr.css('td font').map{|td| td.text}
          course_id += 1

          course_time_location = Hash[data[8].scan(/\((?<day>[一二三四五六日])\)(?<period>[\d\[\]]+)/)]

          course_days, course_periods, course_locations = [], [], []
          course_time_location.each do |k, v|
            v.scan(/[\d(\[\d\d)]/).each do |p|
              course_days << DAYS[k]
              course_periods << p.to_i
              course_locations << data[9]
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[2],    # 課程名稱
            lecturer: data[7],    # 授課教師
            credits: data[5].to_i,    # 學分數(需要轉換成數字，可以用.to_i)
            code: "#{@year}-#{@term}-#{course_id}_#{data[1]}",
            general_code: data[1],    # 選課代碼
            url: nil,    # 課程大綱之類的連結(如果有的話)
            required: data[4].include?('必'),    # 必修或選修
            department: cla_n,    # 開課系所
            # department_code: cla_v,
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

    @courses
  end

end
end
