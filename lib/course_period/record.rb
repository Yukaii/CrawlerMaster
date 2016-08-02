module CoursePeriod
  class Record
    include Enumerable

    attr_reader :periods

    def initialize(csv_path)
      @periods = load_csv(csv_path)
    end

    def each(&block)
      @periods.each(&block)
    end

    def all
      @periods
    end

    def code_map
      create_hash_map do |period|
        [period.code, period.order]
      end
    end

    def order_map
      create_hash_map do |period|
        [period.order, period.code]
      end
    end

    private

    def create_hash_map(&block)
      Hash[@periods.map(&block)]
    end

    def load_csv(csv_path)
      CSV.read(csv_path).map do |row|
        Period.new(row)
      end
    end

  end
end
