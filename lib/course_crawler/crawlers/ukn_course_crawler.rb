##
# 康寧課程爬蟲
# http://actweb.ukn.edu.tw:8080/leader/ClsQuery.jsp
#

require 'rmagick'
require 'rtesseract'
require 'tempfile'

module CourseCrawler::Crawlers
class UknCourseCrawler < CourseCrawler::Base
  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://actweb.ukn.edu.tw:8080/leader/ClsQuery.jsp"
    @base_url = "http://actweb.ukn.edu.tw:8080/leader/"
  end

  def courses

    doc, chk = nil, nil;

    loop do
      doc = Nokogiri::HTML(http_client.get(@query_url).body)
      chk = get_image
      break if !chk.empty? && chk.match(/\d{5}/)
    end

    doc.css('form[name="form1"]')[0][:action]


    # syear:104
    # sem:2
    # acadno:11 # 學制
    # deptno:A01 # 系所
    # secno:0 # 組別
    # grade:1 # 年級
    # classcode:A #
    # clsdata:
    # chkImg:25847
    # chkType: 'classes'
    # query: "查詢".encode('big5')



# optsel: 'optselchg'

  end

  def get_image
    temp_file = Tempfile.new(['captcha', '.png'])
    File.write(temp_file.path, http_client.get_content("http://actweb.ukn.edu.tw:8080/leader/getImage.jsp").force_encoding('utf-8'))

    img = RTesseract.new(temp_file.path.to_s, psm: 8, options: :digits, :processor => "mini_magick")
    img.to_s.strip
  end

end
end
