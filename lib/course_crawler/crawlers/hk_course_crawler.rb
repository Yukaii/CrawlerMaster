# 弘光科技大學
# 課程查詢網址：http://course.hk.edu.tw/hktea/HK_A02/A020A20.aspx

# 沒有看到這學校的上課時間
module CourseCrawler::Crawlers
class HkCourseCrawler < CourseCrawler::Base

  # DAYS = {
  #   "一" => 1,
  #   "二" => 2,
  #   "三" => 3,
  #   "四" => 4,
  #   "五" => 5,
  #   "六" => 6,
  #   "日" => 7
  #   }

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
  #   "A" => 10,
  #   "B" => 11,
  #   "C" => 12,
  #   "D" => 13,
  #   "E" => 14
  #   }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://course.hk.edu.tw/hktea/HK_A02/'
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url+"A020A20.aspx")
    doc = Nokogiri::HTML(r)

    @hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    doc.css('select[id="cboDvs"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |cboDvs|
      doc = form_data_post(term: nil, cboDvs: cboDvs)
      doc.css('select[id="cboDgr"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |cboDgr|
        doc = form_data_post(cboDvs: cboDvs, cboDgr: cboDgr)
        doc.css('select[id="cboDpt"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |cboDpt|
          doc = form_data_post(cboDvs: cboDvs, cboDgr: cboDgr, cboDpt: cboDpt)
          doc.css('select[id="cboCls"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |cboCls, cboCls_name|
# puts cboDvs+','+cboDgr+','+cboDpt+','+cboCls
            doc = form_data_post(cboDvs: cboDvs, cboDgr: cboDgr, cboDpt: cboDpt, cboCls: cboCls, btnQuery: "查詢該班級的所有課程")

            doc.css('table[id="gvCouList"] tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
              data = tr.css('td').map{|s| s.text}
              data[0..2] = tr.css('td span').map{|s| s.text}[0..2]
              data[7..9] = tr.css('td a').map{|s| s[:href]}

              syllabus_url = @query_url+data[7]

              r = RestClient.get(syllabus_url)
              doc = Nokogiri::HTML(r)

              data[9..10] = doc.css('table table > tr:nth-child(3) td span').map{|t| t.text}.values_at(1,3)

              course_id += 1

              # time_period_regex = /(?<period>[MFTSWUR][\dA-Z]+)(\((?<loc>.*?)\))?/
              # course_time_location = Hash[ time.scan(time_period_regex) ]

              course_days, course_periods, course_locations = [], [], []
              # course_time_location.each do |k, v|
              #   course_days << DAYS[k[0]]
              #   course_periods << PERIODS[k[1..-1]]
              #   course_locations << v
              # end

              course = {
                year: @year,    # 西元年
                term: @term,    # 學期 (第一學期=1，第二學期=2)
                name: data[1],    # 課程名稱
                lecturer: data[9],    # 授課教師
                credits: data[10][0].to_i,    # 學分數
                code: "#{@year}-#{@term}-#{course_id}_#{data[0]}",
                general_code: data[0],    # 選課代碼
                url: syllabus_url,    # 課程大綱之類的連結
                required: data[4].include?('必'),    # 必修或選修
                department: cboCls_name,    # 開課系所
                # department_code: cboCls,
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
# binding.pry
    end

    @courses
  end

  def form_data_post term: @term, cboDvs: nil, cboDgr: nil, cboDpt: nil, cboCls: nil, btnQuery: nil
    r = RestClient.post(@query_url+"A020A20.aspx", @hidden.merge({
      "cboAyr" => @year-1911,
      "cboAsm" => term,
      "cboDvs" => cboDvs,
      "cboDgr" => cboDgr,
      "cboDpt" => cboDpt,
      "cboCls" => cboCls,
      "btnQuery" => btnQuery
      }) )
    doc = Nokogiri::HTML(r)
    @hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]
    doc
  end

end
end