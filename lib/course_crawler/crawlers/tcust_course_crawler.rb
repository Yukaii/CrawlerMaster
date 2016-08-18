##
# 慈濟科技大學課程爬蟲
# http://linuxweb.tccn.edu.tw/st/tad/stQrySubj.php
#
module CourseCrawler::Crawlers
  class TcustCourseCrawler < CourseCrawler::Base

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

      @year = year || current_year
      @term = term || current_term
      @query_url = "http://linuxweb.tccn.edu.tw/st/tad/stQrySubj.php"
      @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
      @update_progress_proc = update_progress
         @after_each_proc      = after_each
    end

    def courses
      @courses = []
      year = @year - 1911
      term = @term

      r = RestClient.get(@query_url)
      doc =  Nokogiri::HTML(@ic.iconv(r))
      department = doc.css('select[name="sClsId"] option').map { |option| option[:value] }.reject(&:empty?)
      department.each do |val|
        begin
          r = RestClient.post("http://linuxweb.tccn.edu.tw/st/tad/stQrySubj.php", {
            "fmYy" => year,
            "fmSmstr" => @term,
            "sSuTg" => "",
            "sClsId" => val,
            "OpType" => "QryCrs"
          })
        rescue Exception => e
          raise e
        end
        doc = Nokogiri::HTML(@ic.iconv(r))

        doc.css('td').each do |td|
          td.search('br').each{|br| br.replace("\n") }
        end

        doc.css('fieldset table tr:not(:first-child)').each do |tr|
          data = tr.css('td:nth-child(n+2)').map{|td| td.text}
          course_link = "http://linuxweb.tccn.edu.tw/st/tad/" + tr.css('td a').map{|link| link['href']}.join.sub("查詢", "%ACd%B8%DF")
          #need to tanslate from chinese to %%%

          course_days, course_periods, course_locations = [], [], []

              day_period = data[4].strip.split('\n').map {|s|
                s.match(/(?<day>[#{DAYS.keys.join}])\:(?<period_start>\d)\-(?<period_end>\d)/)
                #'?' for what?
              }


            data[2].gsub!("\n", " ")

            course_r = RestClient.get(course_link)
          course_doc =  Nokogiri::HTML(@ic.iconv(course_r))

          dep = course_doc.css('table table.TR1 > tr:first-child td:nth-child(2)').map{|td| td.text}.join.match(/(?<dep>[\u4e00-\u9fa5]+)["一二三四"]+[\u4e00-\u9fa5]+/)
          #department match not good
          credits = course_doc.css('table table tr:nth-child(4) td:nth-child(3)').map{|td| td.text}.join.match(/.{4}(?<credits>\d)/)

            day_period.reject(&:nil?).each do |arr|
              i = 0
              while i < arr[:period_end].to_i - arr[:period_start].to_i
                course_days << DAYS[arr[:day]]
                course_periods << arr[:period_start].to_i + i
                course_locations << data[5]
                i += 1
              end
            end

          course = {
                year:         @year,    # 西元年
                term:         @term,    # 學期 (第一學期=1，第二學期=2)
                name:         data[1],    # 課程名稱
                lecturer:     data[2],    # 授課教師
                credits:      credits && credits[:credits].to_i,    # 學分數
                code:         "#{@year}-#{@term}-#{data[0]}",
                general_code: "#{data[0]}",
                # general_code: data[2],    # 選課代碼
                # url: syllabus_url,    # 課程大綱之類的連結(內容為HTML，這是一個要POST的)
                required:     data[6].include?('必'),    # 必修或選修
                # department:   dep[:dep],    # 開課系所
                # note: note,
                day_1:        course_days[0],
                day_2:        course_days[1],
                day_3:        course_days[2],
                day_4:        course_days[3],
                day_5:        course_days[4],
                day_6:        course_days[5],
                day_7:        course_days[6],
                day_8:        course_days[7],
                day_9:        course_days[8],
                period_1:     course_periods[0],
                period_2:     course_periods[1],
                period_3:     course_periods[2],
                period_4:     course_periods[3],
                period_5:     course_periods[4],
                period_6:     course_periods[5],
                period_7:     course_periods[6],
                period_8:     course_periods[7],
                period_9:     course_periods[8],
                location_1:   course_locations[0],
                location_2:   course_locations[1],
                location_3:   course_locations[2],
                location_4:   course_locations[3],
                location_5:   course_locations[4],
                location_6:   course_locations[5],
                location_7:   course_locations[6],
                location_8:   course_locations[7],
                location_9:   course_locations[8],
          }
          @courses << course
        end
      end
      @courses
    end
  end
end
