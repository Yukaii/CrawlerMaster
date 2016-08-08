module CourseValidationConcern
  extend ActiveSupport::Concern

  included do
    def name_valid?(course)
      !course.name.nil? || !course.name.empty?
    end

    def lecturer_valid?(course)
      !course.lecturer.nil? || !course.lecturer.empty?
    end

    def required_valid?(course)
      !course.required.nil?
    end

    def credits_valid?(course)
      !course.credits.nil?
    end
  end
end
