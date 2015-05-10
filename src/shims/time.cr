struct Time
  def to_utc
    if utc?
      self
    else
      Time.new(Time.compute_utc_ticks(ticks), Kind::Utc)
    end
  end

  def to_local
    if local?
      self
    else
      Time.new(Time.compute_local_ticks(ticks), Kind::Local)
    end
  end

  protected def self.compute_utc_ticks(ticks)
    compute_ticks do |t, tp, tzp|
      ticks + tzp.tz_minuteswest.to_i64 * TimeSpan::TicksPerMinute
    end
  end

  protected def self.compute_local_ticks(ticks)
    compute_ticks do |t, tp, tzp|
      ticks - tzp.tz_minuteswest.to_i64 * TimeSpan::TicksPerMinute
    end
  end
end

