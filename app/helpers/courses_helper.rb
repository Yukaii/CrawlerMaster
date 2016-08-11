module CoursesHelper
  def course_download_link(params)
    link_to 'Download', download_courses_path(params.slice(*Course::BASIC_COLUMNS)), method: :post
  end
end
