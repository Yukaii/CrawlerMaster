class CoursesController < ApplicationController
  # before_filter :authenticate_admin_user!

  def index
    filters = Hash[params.slice(*Course::BASIC_COLUMNS).map { |k, v| k.to_s == 'organization_code' ? [k, v.upcase] : [k, v] } ]
    @courses = Course.where(filters).page(params[:page]).per(params[:paginate_by])

    @title = "All Courses | CrawlerMaster"
    @title = "#{params[:organization_code]} Courses | CrawlerMaster" if params[:organization_code]
  end
end
