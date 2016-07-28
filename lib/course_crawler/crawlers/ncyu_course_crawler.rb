# 國立嘉義大學

module CourseCrawler::Crawlers
class NcyuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
  }

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "F" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "A" => 11,
    "B" => 12,
    "C" => 13,
    "D" => 14,
  }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year                 = year
    @term                 = term
    @update_progress_proc = update_progress
    @after_each_proc      = after_each

    @query_url = "https://web085003.adm.ncyu.edu.tw/pub_depta1.aspx"
    @post_url = "https://web085003.adm.ncyu.edu.tw/pub_depta2.aspx"
  end

  def courses
    @courses = []

    doc = Nokogiri::HTML(http_client.get_content(@query_url))
    depts = doc.css('select[name="WebDep67"] option').map{|opt| opt[:value] }

    depts.each do |dept|
      r = http_client.post(@post_url, {
        "WebPid1" => nil,
        "Language" => 'zh-TW',
        "WebYear1" => @year-1911,
        "WebTerm1" => @term,
        "WebDep67" => dept
      })

      doc = Nokogiri::HTML(r.body)
      rows = doc.css('table')[3].css('tr:not(:first-child)')

      next if rows[0].text.strip == '查無任何開課資料!!'
      rows.each do |tr|
        datas = tr.css('td')
        general_code = datas[5].text

        days = datas[20] && datas[20].text.strip.split(' ')
        periods = datas[21] && datas[21].text.strip.split(' ')

        course_days, course_periods, course_locations = [], [], []
        days && days.each_with_index do |d, i|
          ps = periods[i].split('~').map{|p| PERIODS[p] }
          next if ps.reject(&:nil?).empty?

          (ps[0]..ps[-1]).each do |p|
            course_days << DAYS[days[i]]
            course_periods << p
            course_locations << datas[22].text.strip
          end
        end

        @courses << {
          :year         => @year,
          :term         => @term,
          :name         => datas[4].text,
          :general_code => general_code,
          :code         => "#{@year}-#{@term}-#{general_code}",
          :required     => datas[13].text.include?('必'),
          :credits      => datas[14].text.to_i,
          :lecturer     => datas[19].text.strip,
          :day_1        => course_days[0],
          :day_2        => course_days[1],
          :day_3        => course_days[2],
          :day_4        => course_days[3],
          :day_5        => course_days[4],
          :day_6        => course_days[5],
          :day_7        => course_days[6],
          :day_8        => course_days[7],
          :day_9        => course_days[8],
          :period_1     => course_periods[0],
          :period_2     => course_periods[1],
          :period_3     => course_periods[2],
          :period_4     => course_periods[3],
          :period_5     => course_periods[4],
          :period_6     => course_periods[5],
          :period_7     => course_periods[6],
          :period_8     => course_periods[7],
          :period_9     => course_periods[8],
          :location_1   => course_locations[0],
          :location_2   => course_locations[1],
          :location_3   => course_locations[2],
          :location_4   => course_locations[3],
          :location_5   => course_locations[4],
          :location_6   => course_locations[5],
          :location_7   => course_locations[6],
          :location_8   => course_locations[7],
          :location_9   => course_locations[8],
        }
      end
    end # end each depts

    @courses
  end # end courses method
end
end
