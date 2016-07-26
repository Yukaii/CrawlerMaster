AdminUser.create(email: 'admin@dev.null', username: 'admin', password: 'password', password_confirmation: 'password')

def current_year
  (Time.zone.now.month.between?(1, 7) ? Time.zone.now.year - 1 : Time.zone.now.year)
end

def current_term
  (Time.zone.now.month.between?(2, 7) ? 2 : 1)
end

CourseCrawler.crawler_list.map(&:to_s).each do |crawler_name|
  crawler = Crawler.find_or_create_by(
    name: crawler_name
  )

  crawler.update!(
    schedule: { in: '1s' },
    save_to_db: true,
    year: current_year,
    term: current_term
  )
end
