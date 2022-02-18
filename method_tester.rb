require "yaml"
require "bcrypt"

require_relative "./user"

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def data_path_for(username)
  data_path + "/user_workouts/" + username + ".yaml"
end

def add_to_yaml(file_path, hash)
  data = YAML.load_file(file_path)
  data = !!data ? data.merge(hash) : hash
  File.open(file_path, "w") { |file| file.write(data.to_yaml) }
end

def encrypt(password)
  BCrypt::Password.create(password)
end

def register_new_user(username, plaintext_password)
  new_user_credentials = { username.to_sym => encrypt(plaintext_password) }
  add_to_yaml(data_path + "/users.yaml", new_user_credentials)
  new_user = User.new(username.to_sym)
  create_new_user_file(username, new_user)
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data/users.yaml", __FILE__)
  else
    File.expand_path("../data/users.yaml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def load_user_file(username)
  YAML.load_file(data_path_for(username))
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


james = User.new("jamesreckinger")
james.add_new_workout
james.add_exercise_to_workout("2022-02-18", "Bench Press")
james.workouts["2022-02-18"]["Bench Press"].add_new_set(10, 150)
james.workouts["2022-02-18"]["Bench Press"].add_new_set(10, 150)
james.workouts["2022-02-18"]["Bench Press"].add_new_set(10, 150)
james.workouts["2022-02-18"]["Bench Press"].add_new_set(10, 150)
james.add_exercise_to_workout("2022-02-18", "Overhead Press")
james.workouts["2022-02-18"]["Overhead Press"].add_new_set(10, 125)
james.add_new_exercise_to_list("Bench Press")
james.add_new_exercise_to_list("Overhead Press")

puts james.workouts["2022-02-18"]

puts tomorrow("2022-02-18")
puts yesterday("2022-02-18")


