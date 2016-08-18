namespace :course_crawler do

  desc 'Run up course crawler directly, ex: rake course_crawler:run[ntust,2015,2,true,false]'
  task :run, [:organization_code, :year, :term, :save_json, :save_to_db] => :environment do |_, args|
    CourseCrawlerJob.new.perform(
      args.organization_code.upcase,
      year:       args.year && !args.year.to_i.zero? && args.year.to_i,
      term:       args.term && !args.term.to_i.zero? && args.term.to_i,
      save_json:  true || args.save_json == 'true',
      save_to_db: false || args.save_to_db == 'true'
    )
  end

end
