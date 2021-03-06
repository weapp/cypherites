module QueryOutBoxing
  def to_a
    execute
  end

  def all
    execute
  end

  def call(*args)
    execute(*args)
  end

  def first
    limit(1).execute.first
  end

  def last
    limit(1).execute.last
  end
end
