require "pg"
require "pry"

class DatabasePersistence
  def initialize(is_test_session = false)
    if is_test_session
      @db = PG.connect(dbname: 'fitness_test')
    else
      @db = PG.connect(dbname: 'fitness')
    end
  end

  def query(statement, *arguments)
    @db.exec_params(statement, arguments)
  end

  def fetch_exercises_for(username, date)
    user_id = fetch_id_for(username)
    sql = "SELECT * FROM workouts WHERE user_id = $1 AND exercise_date = $2;"
    result = query(sql, user_id, date)

    exercises = {}

    result.each do |tuple|
      if exercises.has_key?(tuple["exercise_name"]) == false
        exercises[tuple["exercise_name"]] = []
      end

      exercises[tuple["exercise_name"]] << {tuple["weight"] => tuple["reps"]}
    end
    exercises
  end

  def user_record_exists?(username)
    sql = "SELECT * FROM users WHERE username = $1;"
    result = query(sql, username)
    if result.ntuples == 0
      false
    else 
      true
    end
  end

  def create_user_record(username)
    sql = "INSERT INTO users (username) VALUES ($1);"
    query(sql, username)
  end

  def save_exercise(exercise, username)
    user_id = fetch_id_for(username)
    data = [user_id, exercise.name, exercise.weight, exercise.reps, exercise.date]
    
    sql = <<~SQL
      INSERT INTO workouts (user_id, exercise_name, weight, reps, exercise_date)
      VALUES ($1, $2, $3, $4, $5);
    SQL

    @db.exec_params(sql, data)
  end

  def fetch_id_for(username)
    sql = "SELECT id FROM users WHERE username = $1;"
    result = query(sql, username)
    result.first["id"]
  end
end