# 新增課程爬蟲說明

## 爬蟲文件目錄

目前爬蟲相關檔案主要放在 `lib` 底下的 `course_crawler/crawlers` 資料夾。`base.rb` `mixin.rb` 兩個檔案放的是爬蟲的 helper functions，而 `crawlers.rb` 放的是爬蟲管理的 function。

```bash
lib
├── course_crawler
│   ├── base.rb  # 爬蟲繼承的 class
│   ├── crawlers # 爬蟲都放在這個資料頰
│   │   ├── ccu_course_crawler.rb
│   │   ├── cgu_course_crawler.rb
│   │   ├── cycu_course_crawler.rb
│   │   ├── ...
│   │   ├── ...
│   │   └── yzu_course_crawler.rb
│   ├── crawlers.rb
│   ├── mixin.rb
│   └── course_worker.rb # 爬蟲 worker runner
└── course_crawler.rb
```

## 爬蟲架構

放在 `lib/course_crawler/crawlers` 底下

* 檔名命名：`xxx_course_crawler.rb`，`xxx` 為學校英文小寫縮寫，如台科即為 `ntust_course_crawler.rb`。
* 類別命名：`XxxCourseCrawler`，`Xxx` 為學校英文駝峰命名法，如台科即為 NtustCourseCrawler

### 規格

> 在檔頭註解的地方必須附上大學中文名稱，以及附上查課系統的網址，範例如下：

```ruby
# XXX 大學
# 選課網址： http://xxxxxxxx
module CourseCrawler::Crawlers
  class XxxCourseCrawler < CourseCrawler::Base
    def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil
      @year = year
      @term = term
    end

    def courses
      # code
      # ...
    end
  end
end
```

> `initialize` function：

```ruby
def initialize year: current_year, term: current_term
  @year = year
  @term = term

  @course_system_url = 'https://xxx.xxxxxxxxx' # 學校選課系統網址
end
```

> `courses` function

`courses` 方法回傳的資料為 `Hash` 的 `Array`（an Array of Hash），主要資料欄位如下：

* `year`：西元年 (Integer)
* `term`：學期，一般為 1 或 2 (Integer)
* `code`：課程代碼，請確認為 courses 中的唯一碼 (String)，為 `"#{year}-#{term}-#{general_code}"` 之組合
* `general_code`：通用課程代碼，請確認為 courses 中的唯一碼 (String)
* `name`：課程名稱 (String)
* `url`：課程網址（String)
* `credits`：學分數 (Integer)
* `required`：必修否 (Boolean)
* `lecturer`：教師姓名 (String)

課程節次資料

* `day_1`
* `day_2`
* `day_3`
* `day_4`
* `day_5`
* `day_6`
* `day_7`
* `day_8`
* `day_9`
* `period_1`
* `period_2`
* `period_3`
* `period_4`
* `period_5`
* `period_6`
* `period_7`
* `period_8`
* `period_9`
* `location_1`
* `location_2`
* `location_3`
* `location_4`
* `location_5`
* `location_6`
* `location_7`
* `location_8`
* `location_9`

`day_x`(Integer) `period_x`(Integer) `location_x`(String) 是為了通用課表所設計的欄位，每堂課的單一節為基本單位。

舉例來說，微積分（一）這門課在禮拜三的 3/4 節在 EE-502 這間教室上課，禮拜五的 1 節在 EE-501 這間教室上課，資料記錄如下：

```ruby
# 週三第三節
day_1 = 3
period_1 = 3
location_1 = "EE-502"

# 週三第四節
day_2 = 3
period_2 = 4
location_2 = "EE-502"

# 週五第一節
day_3 = 5
period_3 = 1
location_3 = "EE-501"
```

其餘節次欄位皆留 `nil`。[範例見此](../lib/course_crawler/crawlers/ntust_course_crawler.rb?ts=2#L339)。

## 開發

`lib/course_crawler/crawlers` 底下的任一隻爬蟲可以由 rake task 直接跑起，指令為：

```bash
rake course_crawler:run[ym,2015,2,true,false] # 參數之間不含空白
# => courses crawled results generate at: ..../tmp/ym_courses_1469697508.json
```

會在 tmp 資料夾下產生一包課程 json。

另外在開發爬蟲時可以加入 `binding.pry` 設置斷點，方便開發時除錯。
