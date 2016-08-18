class CoursesController < ApplicationController
  before_action :authenticate_admin_user!

  def index
    @courses = Course.where(filters).page(params[:page]).per(params[:paginate_by])

    @title   = 'All Courses | CrawlerMaster'
    @title   = "#{params[:organization_code]} Courses | CrawlerMaster" if params[:organization_code]
  end

  def download
    organization_code = params[:organization_code] && params[:organization_code].upcase

    if organization_code.nil?
      flash[:warning] = 'organization_code 不可為空白'
      redirect_to :back
      return
    end

    book, filename = Course.export(filters, organization_code)

    temp_file = Tempfile.new(filename)
    book.write(temp_file.path)
    send_data(File.read(temp_file), type: 'application/xls', filename: filename)

    temp_file.close
    temp_file.unlink
  end

  private

  def filters
    Hash[params.slice(*Course::BASIC_COLUMNS).map { |k, v| k.to_s == 'organization_code' ? [k, v.upcase] : [k, v] }].symbolize_keys
  end

end
