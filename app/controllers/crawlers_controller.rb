class CrawlersController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :find_crawler, only: [:show, :setting, :run, :unschedule_job, :sync]

  def index
    available_crawler_names = CourseCrawler.crawler_list.map(&:to_s)
    create_missing_crwaler(available_crawler_names)
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

    @crawler = Crawler.includes(:rufus_jobs).find_or_create_by(name: demodulized_name)
  end

  def create_missing_crwaler(available_crawler_names)
    current_crawlers = Crawler.where(name: available_crawler_names)
    missing_crawler_names = available_crawler_names - current_crawlers.map(&:name)

    @created_crawlers = Crawler.create!(missing_crawler_names.map { |name| { name: name } })
    @crawlers = (@created_crawlers + current_crawlers).sort_by(&:name)
  end
end
