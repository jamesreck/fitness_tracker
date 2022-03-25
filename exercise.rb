class Exercise
  attr_accessor :name, :reps, :weight, :date

  def initialize(name:, reps:, weight:, date:)
    @name = name
    @reps = reps
    @weight = weight
    @date = date
  end
end