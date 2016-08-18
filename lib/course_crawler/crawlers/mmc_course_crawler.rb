##
# 馬偕醫學院課程爬蟲
# http://portal.mmc.edu.tw/VC2/global_cos.aspx
#

module CourseCrawler::Crawlers
class MmcCourseCrawler < CourseCrawler::Base

	DEP = [ 910, 500, 510, 520, 610, 620, 630 ]
	GRADE = [ 1, 2, 3, 4, 5, 6, 7 ]

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    @year = year || current_year
    @term = term || current_term

    @post_url = "http://portal.mmc.edu.tw/VC2/global_cos.aspx"
    @update_progress_proc = update_progress
    @after_each_proc = after_each
	end

	def courses
		@courses = []

		puts "get url ..."
    r = RestClient.get(@post_url);
    doc = Nokogiri::HTML(r.to_s)

    view_state  = Hash[doc.css('input[type="hidden"]').map{|input| [ input[:name], input[:value] ] }]

    dept_h      = Hash[doc.css('select[name="DDL_Dept"] option').map{|opt| [opt.text, opt[:value] ] }]
    degree_h    = Hash[doc.css('select[name="DDL_Degree"] option').map{|opt| [opt.text, opt[:value] ] }]

    done_result = 0
    total_count = dept_h.count * degree_h.count

    dept_h.map do |dept_name, dept_value|
    degree_h.map do |degree_name, degree_value|
      r = RestClient.post( @post_url , view_state.merge({
        'Q'          => 'RadioButton1',
        'DDL_YM'     => "#{@year-1911},#{@term}",
        'DDL_Dept'   => dept_value,
        'DDL_Degree' => degree_value,
        'Button1'    => '確定'
      }));
			puts "data crawled : Department -> " + dept_name + " , Degree -> " + degree_name
      doc = Nokogiri::HTML(r)
      view_state = Hash[doc.css('input[type="hidden"]').map{|input| [ input[:name], input[:value] ] }]

      doc.css('table[id="Table1"] tr:not(:first-child)').each do |row|
        datas = row.css('td')

        if datas[3] != nil

          #from another url , get the credits
          @url_get = "http://portal.mmc.edu.tw/VC2/Guest/Cos_Plan.aspx?y=#{@year-1911}&s=#{@term}&id="+datas[1].text[0..4].to_s+"&c="+datas[1].text[6].to_s
          r_get = RestClient.get @url_get
          doc_get = Nokogiri::HTML(r_get)
          #doc_get.css('div[id="Cos_info"]').css('table[class="table_1"]').css('tr')[1].css('td')[3].text

          course_days, course_periods, course_locations = [], [], []
          datas[5].search('br').each {|br| br.replace("\n")}
          datas[5].text.split("\n").map{|data| data.split(',')}.each do |arr|
            break if arr[0] == '未設定'

            course_days << arr[0][0].to_i
            course_periods << arr[0][1..-1].to_i
            course_locations << arr[1]
          end

          datas[6].search('br').each {|br| br.replace("\n")}

          course = {
            name:         datas[3].text.strip,
            year:         @year,
            term:         @term,
            code:         "#{@year}-#{@term}-#{datas[1].text.strip.gsub(/\s/, '_')}",
            general_code: datas[1].text.strip.gsub(/\s/, '_'),
            degree:       datas[2].text.strip,
            credits:      doc_get.css('div[id="Cos_info"]').css('table[class="table_1"]').css('tr')[1].css('td')[3].text,
            lecturer:     datas[6].text.split("\n").join(','),
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

      done_result += 1
      set_progress "#{done_result} / #{total_count}"
    end
    end
		puts "Project finished !!!"
		@courses
	end
end
end
