module BlogHelper
  MONTHS = %w[Jänner Februar März April Mai Juni Juli August September Oktober November Dezember].freeze

  def blog_date(date)
    "#{date.day}. #{MONTHS[date.month - 1]} #{date.year}"
  end

  def blog_reading_time(post)
    "#{post.reading_minutes} Min. Lesezeit"
  end
end
