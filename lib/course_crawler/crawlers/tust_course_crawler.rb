module CourseCrawler::Crawlers
class TustCourseCrawler < CourseCrawler::Base
  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year                 = year
    @term                 = term
    @update_progress_proc = update_progress
    @after_each_proc      = after_each

    @query_url = 'http://elearning.tust.edu.tw/CourseSchedule.aspx'
  end

  def courses
    @courses = []

    res = http_client.get(@query_url, follow_redirect: true)
    @query_url = res.header.request_uri.to_s # it redirects

    doc = Nokogiri::HTML(res.body)
    view_state = Hash[ doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]] } ]

    departments = doc.css('select[name="Department"] option').map{|option| option[:value] }

    departments.each do |dep|
      r = http_client.post(@query_url, view_state.merge({
        "Department" => dep,
        "TableKind"  => '班級',
        "FindObjects"  => '選完後請按鈕'
      }))

      doc = Nokogiri::HTML(r.body)
      view_state = Hash[ doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]] } ]

      classes = doc.css('select[name="ObjectName"] option').map{|option| option[:value] }
      classes.each do |clas|

        http_client.post(@query_url, view_state.merge({
          "Department" => dep,
          "TableKind"  => '班級',
          "ObjectName" => clas,
          "FindTable"  => '選完後請按鈕'
        }))

        r = http_client.get(URI.join(@query_url, "Table.aspx").to_s)
        doc = Nokogiri::HTML(r.body)

        parse_courses(doc, dep, clas)
      end
    end

    @courses
  end

  def parse_courses doc, dep, clas
    table_hash = {}

    doc.css('table tr:not(:first-child)').each_with_index do |tr, tr_index|
      period = tr_index + 1

      tr.css('td:not(:first-child)').each_with_index do |td, td_index|
        next if power_strip(td.text).empty?

        day = td_index + 1

        td.search('br').each{|br| br.replace("\n") }
        name, lecturer, location = td.text.split("\n")
        course_hash = power_strip(td.text)

        raw_hex = Digest::MD5.hexdigest("#{name}#{lecturer}#{dep}#{clas}")
        general_code = "#{raw_hex[0..4]}#{raw_hex[-5..-1]}"

        table_hash[course_hash] = table_hash[course_hash] || {
          :year         => @year,
          :term         => @term,
          :name         => name,
          :lecturer     => lecturer,
          :general_code => general_code,
          :code         => "#{@year}-#{@term}-#{general_code}"
        }

        table_hash[course_hash][:course_days]      ||= []
        table_hash[course_hash][:course_periods]   ||= []
        table_hash[course_hash][:course_locations] ||= []

        table_hash[course_hash][:course_days]      << day
        table_hash[course_hash][:course_periods]   << period
        table_hash[course_hash][:course_locations] << location
      end # end each td
    end # end each tr

    table_hash.values.each do |course|
      @courses << {
        :year         => course[:year],
        :term         => course[:term],
        :name         => course[:name],
        :lecturer     => course[:lecturer],
        :credits      => 0, # sorry about that
        :general_code => course[:general_code],
        :code         => course[:code],
        :required     => false, # sorry about that
        :day_1        => course[:course_days][0],
        :day_2        => course[:course_days][1],
        :day_3        => course[:course_days][2],
        :day_4        => course[:course_days][3],
        :day_5        => course[:course_days][4],
        :day_6        => course[:course_days][5],
        :day_7        => course[:course_days][6],
        :day_8        => course[:course_days][7],
        :day_9        => course[:course_days][8],
        :period_1     => course[:course_periods][0],
        :period_2     => course[:course_periods][1],
        :period_3     => course[:course_periods][2],
        :period_4     => course[:course_periods][3],
        :period_5     => course[:course_periods][4],
        :period_6     => course[:course_periods][5],
        :period_7     => course[:course_periods][6],
        :period_8     => course[:course_periods][7],
        :period_9     => course[:course_periods][8],
        :location_1   => course[:course_locations][0],
        :location_2   => course[:course_locations][1],
        :location_3   => course[:course_locations][2],
        :location_4   => course[:course_locations][3],
        :location_5   => course[:course_locations][4],
        :location_6   => course[:course_locations][5],
        :location_7   => course[:course_locations][6],
        :location_8   => course[:course_locations][7],
        :location_9   => course[:course_locations][8]
      }
    end
  end
end
end
