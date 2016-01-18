##
# 臺藝大課程爬蟲
# http://uaap3.ntua.edu.tw/ntua/f_index.html
#
module CourseCrawler::Crawlers
class NtuaCourseCrawler < CourseCrawler::Base

  DAYS = {
    '一' => 1,
    '二' => 2,
    '三' => 3,
    '四' => 4,
    '五' => 5,
    '六' => 6,
    '日' => 7
  }

  PERIODS = {
    "1"  =>  1,
    "2"  =>  2,
    "3"  =>  3,
    "4"  =>  4,
    "5"  =>  5,
    "6"  =>  6,
    "7"  =>  7,
    "8"  =>  8,
    "9"  =>  9,
    "10" => 10,
    "A"  => 11,
    "B"  => 12,
    "C"  => 13,
    "D"  => 14
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://uaap3.ntua.edu.tw/ntua/index.html"
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []

    setup;

    doc = Nokogiri::HTML(http_client.get_content("http://uaap3.ntua.edu.tw/ntua/ag_pro/ag304_01.jsp"))
    depts = doc.css('select[name="rtxt_untid"] option').map{|opt| opt[:value] }

    depts.each do |dept|
      doc = Nokogiri::HTML(
        http_client.post("http://uaap3.ntua.edu.tw/ntua/ag_pro/ag304_02.jsp", {
          :yms_yms    => "#{@year-1911}##{@term}",
          :rtxt_untid => dept
        }).body
      )

      doc.css('table td').select{|td| td.text != '班級名稱'}.map{|td| td[:onclick] && td[:onclick].match(/window\.open\(\'(.+)\'\)/)[1] }.reject(&:nil?).map{|url| "http://uaap3.ntua.edu.tw/ntua/ag_pro/#{url}" }.each do |url|
        doc = Nokogiri::HTML(http_client.get_content(url))

        doc.css('table.stable tr:not(:first-child)').each do |row|
          datas = row.xpath('td')

          general_code = power_strip(datas[0].text)

          course_days, course_periods, course_locations = [], [], []
          location = power_strip(datas[9].text)
          datas[10].text.scan(/\((?<day>.)\)(?<p>.+)/).each do |m|
            head, tail = m[1].split('-').map{|i| PERIODS[power_strip(i)] }
            tail ||= head # when only one period

            (head..tail).each do |p|
              course_days << DAYS[m[0]]
              course_periods << p
              course_locations << location
            end
          end

          @courses << {
            :year         => @year,
            :term         => @term,
            :name         => datas[1].text,
            :general_code => general_code,
            :code         => "#{@year}-#{@term}-#{general_code}",
            :credits      => datas[5].text.to_i,
            :required     => datas[6].text.include?('必'),
            :lecturer     => power_strip(datas[8].text),
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
            :location_9   => course_locations[8]
          }
        end
      end
    end # each dept do

    @courses.uniq
  end # end courses method

  def setup
    http_client.post("http://uaap3.ntua.edu.tw/ntua/get_sts.jsp", {
      "uid"       => 'guest',
      "pwd"       => 123,
      "sys_name"  => 'webweb',
      "ls_chochk" => 'N',
      "navigator" => 'Chrome 或 Safari',
    });

    http_client.post("http://uaap3.ntua.edu.tw/ntua/perchk.jsp", {
      'uid'          => 'guest',
      'pwd'          => 123,
      'sys_name'     => 'webweb',
      'fnc_id'       => '',
      'web_type'     => '',
      'ls_chochk'    => 'N',
      'ls_stsid'     => 66,
      'ls_loginkind' => 'TRIPLE_DES'
    });

    http_client.post("http://uaap3.ntua.edu.tw/ntua/fnc.jsp", {
      'fncid' => 'AG304',
      'std_id' => '',
      'local_ip' => '',
      'web_sys' => 'web'
    })

    http_client.post("http://uaap3.ntua.edu.tw/ntua/ag_pro/ag304_00.jsp", {
      'arg01' => @year-1911,
      'arg02' => @term,
      'arg03' => 'guest',
      'arg04' => '',
      'arg05' => '',
      'arg06' => '',
      'fncid' => 'AG304'
    })
  end

end
end
