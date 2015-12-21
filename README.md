CrawlerMaster
=============

你的爬蟲大統領

-----------------

## TODOs

* index => 列出所有的 crawlers
  - [x] endpoint: /crawlers
  - [x] show last_run_at
  - [x] show running workers in queue (Sidekiq::Queue find class name)
  - [x] show how many courses each crawler had done

* show => 顯示單一爬蟲的資訊 name / crawling status
  - [x] endpoint: /crawlers/ntust, /crawler/{school name}
  - [x] track each worker job progress and status
  - [x] Start crawler anytime => track job ids => maybe save it to another model?
  - [x] ScheduledSet / RetrySet / DeadSet status (filtered by class name) (<- just a tab in sidekiq web)
  - [ ] Limiting queueing crawler (eg. each class for 5 instances)
  - [x] Manage/Track Rufus Scheduled Job
  - [x] Unschedule EveryJob / CronJob(EveryJob first)

* setting => 設定單一爬蟲的 api secrets / retry interval / scheduling
  - [x] endpoint: /crawlers/{school name}/setting (ediqt page)
  - [x] understanding sidekiq scheduler usage and parameters
  - [x] Schedule crawler (whenever, .etc)
```
  I use rufus-scheduler eventually
```
  - [ ] initializer setup existing scheduling behavior

* Course Model
  - [x] Copy and Paste from Colorgy/Book :p
  - [ ] Check data integrity (no blank class name / no blank class period data / no invalid period data......)
  - [ ] Check course_code
  - [x] Sync data to Core

* 後期調教
  - [x] Redis Namespace
  - [x] queue namespace(Sidekiq::Client push specific queue name)
  - [x] Limiting retry count
  - [ ] limit queue number
  - [x] we can't kill workers orz
  - [ ] sidekiq-limit_fetch set limit
  - [ ] download json course data

```ruby
Sidekiq::Client.push('queue' => 'NtustCourseCrawler', 'class' => CourseCrawler::Worker, 'args' => ['NtustCourseCrawler'])
```

* 有閒套個 AdminLTE 吧 ww
