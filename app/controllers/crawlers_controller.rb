class CrawlersController < ApplicationController
  before_filter :authenticate_admin_user!
  before_filter :find_crawler, only: [:show, :setting, :run, :unschedule_job]

  def index
    available_crawler_names = CourseCrawler.crawler_list.map(&:to_s)

    available_crawler_names.each do |crawler_name|
      Crawler.find_or_create_by(name: crawler_name)
    end

    @crawlers = Crawler.where(name: available_crawler_names).order(:name)
  end

  def show
    @title = "#{@crawler.name} | CrawlerMaster"
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

    flash[:success] = "Settings has been successfully updated"
    redirect_to crawler_path(@crawler.organization_code)
  end

  def run
    jobs = Crawler::SCHEDULE_KEYS.map do |job_type|
      @crawler.run_up(job_type, {year: params[:year], term: params[:term]})
    end

    flash[:success] = "job_ids: #{jobs.map{|j| j && j.id}}"

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
    demodulized_name = CourseCrawler.crawler_list.map(&:to_s).find { |cn| cn.match(%r{#{params[:id].downcase.capitalize}CourseCrawler}) } or not_found

    @crawler = Crawler.find_or_create_by(name: demodulized_name)
  end
end
