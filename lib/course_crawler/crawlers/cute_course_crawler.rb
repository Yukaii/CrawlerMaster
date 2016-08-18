##
# 中國科技大學
# http://192.192.78.80/acad_curr/T_CourseInfo.aspx
#
# 沒有節次資料，不過難得有 injection 的娛樂，就把它弄完吧 :p

module CourseCrawler::Crawlers
class CuteCourseCrawler < CourseCrawler::Base
  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://192.192.78.80/acad_curr/T_CourseInfo.aspx"
    @count = 1
  end

  def courses
    @courses = []
    puts "get url ..."
    doc = Nokogiri::HTML(http_client.get_content @query_url)

    view_state = Hash[doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]] }]
    doc = Nokogiri::HTML(http_client.post(@query_url, {
      "__EVENTTARGET" => 'RdBtn_3',
      "dl_Year" => @year-1911,
      "dl_Semester" => @term == 1 ? '上' : '下',
      "Terms" => 'RdBtn_3',
    }.merge(view_state)).body)

    view_state = Hash[doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]] }]
    doc = Nokogiri::HTML(http_client.post(@query_url, {
      "dl_Year" => @year-1911,
      "dl_Semester" => @term == 1 ? '上' : '下',
      "Terms" => 'RdBtn_3',
      "txt_course" => '     ',
      "btn_ClassInfo" => '查詢',
    }.merge(view_state)).body)

    doc.css('tr[bgcolor="#EEEEEE"]').each do |row|
      datas = row.xpath('td')

      dept_code, dept    = datas[0].text.strip.split(/\s+/)
      general_code, name = datas[3].text.strip.split(/\s+/)
      puts "data crawled : " + name
      @courses << {
        :year         => @year,
        :term         => @term,
        :name         => name,
        :lecturer     => datas[4].text.strip,
        :credits      => datas[6].text.strip.to_i,
        :general_code => general_code+"-#{@count}",
        :code         => "#{@year}-#{@term}-#{general_code}-#{@count}"
      }
      @count += 1
     end
     puts "Project finished !!!"
    @courses
  end
end
end
