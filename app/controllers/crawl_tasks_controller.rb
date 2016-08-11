class CrawlTasksController < ApplicationController
  before_action :find_crawler

  def changes
    @task = @crawler.crawl_tasks.find(params[:id])
    @versions = @task.course_versions.page(params[:page]).per(params[:paginate_by])
  end

  def snapshot
    task = @crawler.crawl_tasks.find(params[:id])
    book, filename = task.generate_snapshot(errors_only: params[:errors_only])

    temp_file = Tempfile.new(filename)
    book.write(temp_file.path)
    send_data(File.read(temp_file), type: 'application/xls', filename: filename)

    temp_file.close
    temp_file.unlink
  end

  private

  def find_crawler
    demodulized_name =
      CourseCrawler
      .demodulized_names
      .find { |cn| cn.match(/#{params[:crawler_id].downcase.capitalize}CourseCrawler/) } || not_found

    @crawler = Crawler.includes(:rufus_jobs, :crawl_tasks).find_or_create_by(name: demodulized_name)
  end
end
