module CourseCrawler::Crawlers
class NctuCourse
  include DSL

  def initialize year: nil, term: nil
    @host = "http://timetable.nctu.edu.tw/"

    @year = year
    @term = term
  end

  # 大概十二秒
  def update_hash
    save_deps
    @departments = []

    visit "#{@host}view/main/timetable_menu_zh-tw.html"

    ftype_h = Hash[@doc.css('select[name="fType"] option').map{|opt| [opt[:value], opt.text]}]
    @category_threads = []
    @college_threads = []
    @dep_threads = []
    ftype_h.each do |ftype_k, ftype_v|
      @category_threads << Thread.new do
        category_h = get_category(ftype: ftype_k)

        if category_h.empty?
          @departments.concat get_dep(ftype: ftype_k, fcollege: "*")
        else
          category_h.each do |category_k, category_v|
            @college_threads << Thread.new do
              colleges_arr = get_college(ftype: ftype_k, fcategory: category_k)

              colleges_arr.each do |college_h|
                @departments.concat \
                  get_dep(ftype: ftype_k, fcategory: category_k, fcollege: college_h["CollegeNo"])
              end

            end # end @college_threads
            ThreadsWait.all_waits(*@college_threads)
          end
        end
      end # end @category_threads
    end # end ftype
    ThreadsWait.all_waits(*@category_threads)
    @departments = Hash[Hash[@departments.map{|dep| [dep["unit_id"], dep["unit_name"]]}].sort]
    save_deps
  end # end update_hash

  def departments
    load_deps if !@departments
    @departments
  end

  def save_deps
    @config["departments"] = @departments
    File.write(Rails.root.join('tmp', 'config.yaml'), @config.to_yaml)
  end

  def load_deps
    begin
      load_config
      @departments = @config["departments"]
    rescue Errno::ENOENT => e
      puts "no departments found in local, try load it online"
      @config = {}
      update_hash
    end
  end

  def load_config
    @config = YAML.load File.read(Rails.root.join('tmp', 'config.yaml'))
  end

  # [
  #   {
  #     "acy": "103",
  #     "sem": "2",
  #     "cos_id": "1010",
  #     "cos_code": "DEE1113",
  #     "num_limit": "9999",
  #     "dep_limit": "N",
  #     "URL": null,
  #     "cos_cname": "服務學習(一)",
  #     "cos_credit": "0",
  #     "cos_hours": "2",
  #     "TURL": "http://hcchang.ee.nctu.edu.tw",
  #     "teacher": "張錫嘉、林聖迪",
  #     "cos_time": "2HY-ED220",
  #     "memo": "電子系及電資學士班優先。第一次上課時間及地點為 2HY-ED220，接下來之實作服務時間與地點：配合參與組別規劃進行。同一學期不得同時修習服務學習(一)與(二)",
  #     "cos_ename": "Student Service Education(I)",
  #     "brief": " ",
  #     "degree": "3",
  #     "dep_id": "11",
  #     "dep_primary": "1",
  #     "dep_cname": "電子工程學系",
  #     "dep_ename": "Department of Electronics Engineering",
  #     "cos_type": "必修",
  #     "cos_type_e": "Required",
  #     "crsoutline_type": "data",
  #     "reg_num": "86",
  #     "depType": "U"
  #   },
  #   ...
  # ]
  # unit_id should looks like "343"
  def get_course_list unit_id: nil
    courses = []

    course_list = get_cos_list(degree: unit_id[0], dep_id: unit_id[1..-1])
    if not course_list.empty?
      courses_h = course_list[unit_id]
      courses_h["1"] && courses.concat(courses_h["1"].values)
      courses_h["2"] && courses.concat(courses_h["2"].values)
    end

    courses
  end

  # {
  #   "2*": "一般研究所",
  #   "2E": "EMBA",
  #   "2J": "在職專班",
  #   "2I": "產業專班",
  #   "2M": " 碩(博)士學位學程 "
  # }
  def get_category ftype: "3"
    r = RestClient.post "#{@host}?r=main/get_category", {
      ftype: ftype,
      flang: 'zh-tw'
    }
    Oj.load(r)
  end


  # [
  #   {
  #     "CollegeNo": "A",
  #     "0": "A",
  #     "CollegeName": "人文社會學院",
  #     "1": "人文社會學院"
  #   },
  #   {
  #     "CollegeNo": "B",
  #     "0": "B",
  #     "CollegeName": "生物科技學院",
  #     "1": "生物科技學院"
  #   },
  #   ...
  # ]
  def get_college ftype: "3", fcategory: "3*"
    r = RestClient.post "#{@host}?r=main/get_college", {
      ftype: ftype,
      fcategory: fcategory,
      flang: 'zh-tw'
    }
    Oj.load(r)
  end

  # [
  #   {
  #     "unit_id": "241",
  #     "0": "241",
  #     "unit_name": "ICT(傳播研究所)",
  #     "1": "ICT(傳播研究所)",
  #     "dep_id": "41",
  #     "2": "41"
  #   },
  #   {
  #     "unit_id": "242",
  #     "0": "242",
  #     "unit_name": "IAA(應用藝術研究所)",
  #     "1": "IAA(應用藝術研究所)",
  #     "dep_id": "42",
  #     "2": "42"
  #   },
  #   ...
  # ]
  # 取 unit_id 和 unit_name 就夠用了
  def get_dep ftype: "3", fcategory: "3*", fcollege: "A"
    r = RestClient.post "#{@host}?r=main/get_dep", {
      acysem: "#{@year-1911}#{@term}",
      ftype: ftype,
      fcategory: fcategory,
      fcollege: fcollege,
      flang: 'zh-tw'
    }
    Oj.load(r)
  end

  def get_group ftype: "3", fcategory: "3*", fcollege: "A", fdep: "343"
    r = RestClient.post "#{@host}?r=main/get_group", {
      acysem: "#{@year-1911}#{@term}",
      ftype: ftype,
      fcategory: fcategory,
      fcollege: fcollege,
      fdep: fdep,
      flang: 'zh-tw'
    }
    Oj.load(r)
  end

  def get_cos_list degree: "3", dep_id: "43"
    r = RestClient.post "#{@host}?r=main/get_cos_list", {
      m_acy: @year-1911,
      m_sem: @term,
      m_degree: degree,
      m_dep_id: dep_id,
      m_group: "**",
      m_grade: "**",
      m_class: "**",
      m_option: "**",
      m_crsname: "**",
      m_teaname: "**",
      m_cos_id: "**",
      m_cos_code: "**",
      m_crstime: "**",
      m_crsoutline: "**",
    }
    Oj.load(r)
  end
end
end
