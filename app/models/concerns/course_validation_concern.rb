module CourseValidationConcern
  extend ActiveSupport::Concern

  included do
    def name_valid?(course)
      course.name.present? && !course.name.empty?
    end

    def lecturer_valid?(course)
      course.lecturer.present? && !course.lecturer.empty?
    end

    def required_valid?(course)
      !course.required.nil?
    end

    def credits_valid?(course)
      !course.credits.nil?
    end
  end
end
