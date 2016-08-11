module CourseCrawler
  extend SidekiqHelper

  class << self
    include Enumerable

    def all
      crawlers
    end

    def each(&block)
      crawlers.each(&block)
    end

    def last
      crawlers.last
    end

    # may raise NameError: uninitialized constant
    # TODO: should include ActiveSupport::Inflector dependency when extracted into gem
    def find!(organization_code)
      "CourseCrawler::Crawlers::#{organization_code.downcase.camelize}CourseCrawler".constantize
    end

    def demodulized_names
      available_organization_codes.map do |organization_code|
        "#{organization_code.downcase.camelize}CourseCrawler"
      end
    end

    private

    def crawlers
      @crawlers ||= available_organization_codes.map(&method(:find!))
    end

    # list all avaliable organization by finding each crawler in lib/course_crawler/crawlers path
    def available_organization_codes
      @available_organization_codes ||= Dir.glob(Rails.root.join('lib/course_crawler/crawlers', '*.rb')).map do |filename|
        filename.match(%r{crawlers/(.+?)_course_crawler}) do |m|
          m[1].upcase
        end
      end.reject(&:nil?)
    end

  end
end
