class CrawlersController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :find_crawler, except: [:index, :batch_run]

  def index
    available_crawler_names = CourseCrawler.crawler_list.map(&:to_s)
    create_missing_crwaler(available_crawler_names)
  end

  def show
    @title = "#{@crawler.name} | CrawlerMaster"
  end

  def changes
    @task = @crawler.crawl_tasks.find(params[:task_id])
    @versions = @task.course_versions.page(params[:page]).per(params[:paginate_by])
  end

  def snapshot
    task = @crawler.crawl_tasks.find(params[:task_id])
    task.generate_snapshot(errors_only: params[:errors_only]) do |book, filename|
      temp_file = Tempfile.new(filename)
      book.write(temp_file.path)
      send_data(File.read(temp_file), type: 'application/xls', filename: filename)

      temp_file.close
      temp_file.unlink
    end
  end

  def setting
    params[:schedule].slice(*Crawler::SCHEDULE_KEYS).each do |hkey, value|
      @crawler.schedule[hkey] = value
    end

    Crawler::API_MANAGEMENT_KEYS.each do |hkey|
      @crawler.send("#{hkey}=", params[hkey])
    end

    Crawler::TEST_SETTING_KEYS.each do |hkey|
      @crawler.send("#{hkey}=", !params[hkey].nil?)
    end

    @crawler.save!

    flash[:success] = 'Settings has been successfully updated'
    redirect_to crawler_path(@crawler.organization_code)
  end

  def run
    jobs = Crawler::SCHEDULE_KEYS.map do |job_type|
      @crawler.run_up(job_type, year: params[:year], term: params[:term])
    end

    flash[:success] = "job_ids: #{jobs.map { |j| j && j.id }}"

    redirect_to crawler_path(@crawler.organization_code)
  end

  def batch_run
    Crawler.where(organization_code: params[:run_crawler]).find_each do |crawler|
      crawler.run_up(:in, {})
    end

    redirect_to crawlers_path
  end

  def upload
    uploaded_file = params[:file]

    if File.extname(uploaded_file.original_filename) != '.xls'
      flash[:warning] = 'Wrong file extension'
      redirect_to crawler_import_path(@crawler.organization_code)
      return
    end

    temp_file = Tempfile.new([File.basename(uploaded_file.original_filename, '.xls'), '.xls'])

    File.open(temp_file.path, 'wb') do |file|
      file.write(uploaded_file.read)
    end

    CrawlTask.from_file(temp_file.path) do |task|
      if task.course_versions.size.zero?
        task.destroy
        flash[:warning] = 'No course changes'
        redirect_to crawler_import_path(@crawler.organization_code)
      else
        redirect_to crawler_path(@crawler.organization_code)
        flash[:success] = 'Successfully imported'
      end
    end

  end

  def sync
    j = @crawler.sync_to_core
    flash[:success] = "job_id: #{j && j.id}"
    redirect_to crawler_path(@crawler.organization_code)
  end

  def unschedule_job
    job = RufusJob.find_by(id: params[:jid])
    job.unschedule if job

    job.destroy

    redirect_to crawler_path(@crawler.organization_code)
  end

  private

  def find_crawler
    demodulized_name =
      CourseCrawler
      .crawler_list
      .map(&:to_s)
      .find { |cn| cn.match(/#{params[:id].downcase.capitalize}CourseCrawler/) } || not_found

    @crawler = Crawler.includes(:rufus_jobs, :crawl_tasks).find_or_create_by(name: demodulized_name)
  end

  def create_missing_crwaler(available_crawler_names)
    current_crawlers = Crawler.where(name: available_crawler_names)
    missing_crawler_names = available_crawler_names - current_crawlers.map(&:name)

    @created_crawlers = Crawler.create!(missing_crawler_names.map { |name| { name: name } })
    @crawlers = (@created_crawlers + current_crawlers).sort_by(&:name)
  end
end
