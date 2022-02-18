require "yaml"

class User
  attr_accessor :workouts, :exercises
  attr_reader :username

  def initialize(username)
    @username = username
    @workouts = {}
    @exercises = []
  end

  def add_new_workout(date=Time.now)
    unless workout_exists_for(date)
      today = date.to_s.split[0]
      @workouts[today] = {}
    end
  end

  def add_new_exercise_to_list(exercise_name)
    @exercises << exercise_name.capitalize unless @exercises.include?(exercise_name.capitalize)
  end

  def add_exercise_to_workout(date, exercise_name)
    exercise = Exercise.new(exercise_name)
    @workouts[date][exercise_name] = exercise
  end

  def add_new_set(exercise, reps, weight)
    @workout[:exercise] = []
    @workout[:exercies] << {reps => weight}
  end

  def workout_exists_for(date)
    !!@workouts[date]
  end

  def format_for_yaml
    { 
      username: @username,
      workouts: @workouts,
      exercises: @exercises
    }
  end
end

class Exercise
  attr_accessor :name, :sets

  def initialize(name)
    @name = name
    @sets = []
  end

  def add_new_set(reps, weight)
    @sets << {reps => weight}
  end

  def each
    @sets.each do |set|
      yield(set)
    end
  end
  
end


