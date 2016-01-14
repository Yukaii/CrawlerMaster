module CourseCrawler::Crawlers
class NtcuCourseCrawler < CourseCrawler::Base
  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://campus.ntcu.edu.tw/ntctc/cur/cur0404.asp"
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    doc = Nokogiri::HTML(http_client.get_content @query_url)
    depts = doc.css('select[name="SelDep"] option').map{|opt| opt[:value] }.reject(&:nil?)

    depts.each do |dept|
      doc = Nokogiri::HTML(query_courses(dept))
      klasses = doc.css('select[name="sEdu06"] option').map{|opt| opt[:value] }.reject(&:nil?)

      klasses.each do |klas|
        doc = Nokogiri::HTML(query_courses(dept, klas))

        doc.css('center table tr:not(:first-child)').map do |row|
          datas = row.xpath('td')
          datas[2].search('br').each{|br| br.replace("\n") }

          general_code = datas[4].text

          course_days, course_periods, course_locations = [], [], []

          raw_days     = datas[10].text.scan(/\[(\d)\]/).flatten.map(&:to_i)
          raw_periods  = datas[11].text.scan(/\[(\d+)\]/)
                          .flatten
                          .map{|d| d.gsub(/\d{2}/, '\0 ')
                          .split(' ')
                          .map(&:to_i)}

          raw_location = datas[12].text.strip

          raw_periods.each_with_index do |periods, i|
            periods.each do |period|
              course_days      << raw_days[i]
              course_periods   << period
              course_locations << raw_location
            end
          end

          @courses << {
            :year         => @year,
            :term         => @term,
            :name         => datas[2].text.split("\n").map(&:strip).join(' '),
            :url          => datas[1].css('a').any? ?
                              URI.join(@query_url, URI.escape(datas[1].css('a')[0][:href])).to_s : nil,
            :serial       => datas[1].text,
            :code         => "#{@year}-#{@term}-#{general_code}",
            :general_code => general_code,
            :required     => datas[6].text.include?('必'),
            :credits      => datas[8].text.strip.to_i,
            :lecturer     => datas[9].text.strip,
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
        end # end each row
      end # end each klasses
    end # end each dept

    @courses
  end # end courses method

  private

  def query_courses(dept, klas=nil)
    @ic.iconv(
      http_client.post(@query_url, {
        'sYear'   => @year-1911,
        'sTerm'   => @term,
        'SelDep'  => dept,
        'sEdu06'  => klas,
        'txtPerm' => '',
        'txtTea'  => '',
        'submit1' => '查詢'.encode('big5')
      }).body
    );
  end
end
end
