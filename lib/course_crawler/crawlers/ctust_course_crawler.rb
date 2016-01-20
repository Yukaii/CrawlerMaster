##
# 中臺科技大學
# http://epage.coursemap.ctust.edu.tw/bin/index.php?Plugin=coursemap&Action=csmapschcosrec
#

module CourseCrawler::Crawlers
class CtustCourseCrawler < CourseCrawler::Base
  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://epage.coursemap.ctust.edu.tw/bin/index.php?Plugin=coursemap&Action=csmapschcosrec"
  end

  def courses
    @courses = []
    doc = Nokogiri::HTML(http_client.get_content @query_url)

    depts_h = get_select_hash(doc, "cosrec_unit")
    sys_h   = get_select_hash(doc, "cosrec_edusys")

    depts_h.each do |dept, dept_value|
    sys_h.each   do |sys, sys_value|

      doc = Nokogiri::HTML(http_client.post(@query_url, {
        :cosrec_year   => @year-1911,
        :cosrec_unit   => dept_value, # 系所
        :cosrec_edusys => sys_value,  # 學制
        :cosrec_grade  => @term,      # 學期
        :sch_cond      => 1           # 關鍵字（按課程）
      }).body)

      doc.css('table.CTableList tr:not(:first-child)').each do |row|
        datas = row.xpath('td')

        general_code  = power_strip(datas[1].text)
        lecturer      = power_strip(datas[5].text)
        lecturer_code = Base64.urlsafe_encode64(lecturer)[0..5]

        @courses << {
          :year         => @year,
          :term         => @term,
          :name         => power_strip(datas[2].text),
          :credits      => power_strip(datas[4].text).split('/')[0].to_i,
          :lecturer     => power_strip(datas[5].text),
          :required     => power_strip(datas[8].text).include?('必'),
          :general_code => general_code,
          :code         => "#{@year}-#{@term}-#{general_code}-#{lecturer_code}"
        }
      end
    end; end;

    @courses.uniq
  end

  def get_select_hash doc, select_name
    Hash[ doc.css("select[name=\"#{select_name}\"] option:not(:first-child)").map{|opt| [opt.text, opt[:value]] } ]
  end

end; end;

