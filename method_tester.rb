require "yaml"
require "bcrypt"

require_relative "./user"
require_relative "./database_persistence"

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def encrypt(password)
  BCrypt::Password.create(password)
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data/users.yaml", __FILE__)
  else
    File.expand_path("../data/users.yaml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def tomorrow(date_string)
  date_array = date_string.split("-")
  date_array[2] = (date_array[2].to_i + 1).to_s
  date_array.join('-')
end

def yesterday(date_string)
  date_array = date_string.split("-")
  date_array[2] = (date_array[2].to_i - 1).to_s
  date_array.join('-')
end

def fetch_exercises_for(user_id, date)
  sql = <<~SQL 
    SELECT * FROM workouts
    WHERE user_id = $1
    AND exercise_date = $2;
  SQL
  result = query(sql, user_id, date)
  exercises = {}
  result.each do |tuple|
    puts tuple
  end
end

@storage = DatabasePersistence.new(true)
@storage.fetch_exercises_for('james', '2022-03-25')



