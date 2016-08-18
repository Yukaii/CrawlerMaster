module CourseCrawler
  module DateMixin
    def self.included(base)
      base.include(InstanceMethods)
    end

    module InstanceMethods

      def current_year
        (Time.zone.now.month.between?(1, 7) ? Time.zone.now.year - 1 : Time.zone.now.year)
      end

      def current_term
        (Time.zone.now.month.between?(2, 7) ? 2 : 1)
      end

    end
  end
end
