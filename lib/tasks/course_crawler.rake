namespace :course_crawler do

  desc 'Run up course crawler directly, ex: rake course_crawler:run[ntust,2015,2,true,false]'
  task :run, [:organization_code, :year, :term, :save_json, :save_to_db] => :environment do |_, args|
    CourseCrawlerJob.new.perform(
      args.organization_code.upcase,
      year:       args.year && !args.year.to_i.zero? && args.year.to_i,
      term:       args.term && !args.term.to_i.zero? && args.term.to_i,
      save_json:  args.save_json == 'true',
      save_to_db: args.save_to_db == 'true'
    )
  end

  desc 'Sync course data to course, ex: rake course_crawler:sync[ntust,2016,1]'
  task :sync, [:organization_code, :year, :term] => :environment do |_, args|
    Course.import_to_course(args.organization_code.upcase, args.year, args.term)
    CourseCacheGenerateJob.perform_now(args.organization_code.upcase, args.year, args.term)
  end

end
