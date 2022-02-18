require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "bcrypt"
require "yaml"
require "pry"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def authenticated?
    !!session[:username]
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
end

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
    unless @workouts[date].has_key? exercise_name
      exercise = Exercise.new(exercise_name)
      @workouts[date][exercise_name] = exercise
    end
  end

  def add_new_set(exercise, reps, weight)
    @workout[:exercise] = []
    @workout[:exercies] << {reps => weight}
  end

  def workout_exists_for(date)
    !!@workouts[date]
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

# -----BACKEND HELPER METHODS-----

# DATA PATHS AND FILE WRITING METHODS
# general data path director for testing vs production
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

# data path redirector for user files
def data_path_for(username)
  data_path + "/user_workouts/" + username + ".yaml"
end

# loads in existing yaml file and merges provided hash with existing data
def update_credential_file(file_path, credentials)
  data = YAML.load_file(file_path)
  data = !!data ? data.merge(credentials) : credentials
  File.open(file_path, "w") { |file| file.write(data.to_yaml) }
end

def update_workout_file(user)
  file_path = data_path_for(user.username.to_s)
  File.open(file_path, "w") { |file| file.write(user.to_yaml) }
end

def load_user_file(username)
  YAML.load_file(data_path_for(username))
end

# REGISTER NEW USER AND CREATE USER DATA FILE
# register a new user and store the encrypted credentials in the yaml file
def register_new_user(username, plaintext_password)
  new_user_credentials = { username.to_sym => encrypt(plaintext_password) }
  update_credential_file(data_path + "/users.yaml", new_user_credentials)
  new_user = User.new(username.to_sym)
  create_new_user_file(new_user)
end

# create a new user yaml file
def create_new_user_file(user_object)
  file_path = data_path_for(user_object.username.to_s)
  File.new(file_path, "w")
  update_workout_file(user_object)
end

# SESSION AUTHENTICATION AND LOGIN/LOGOUT
# loads hash of valid credentials, passwords encrypted
def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data/users.yaml", __FILE__)
  else
    File.expand_path("../data/users.yaml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

# encrypt a plain text password
def encrypt(password)
  BCrypt::Password.create(password)
end

# check an encrypted password against the entered plain text password
def passwords_equal?(password, encrypted_password)
  return false unless encrypted_password
  BCrypt::Password.new(encrypted_password) == password
end

# redirects if not logged in
def require_logged_in
  redirect "/login" unless authenticated?
end

# logs user in
def authenticate_session
  session[:username] = params[:username]
  session[:message] = "Welcome!"
end

# logs user out
def logout_session
  session[:username] = nil
  session[:message] = "You have been logged out."
end

def no_user_file?(username)
  begin
    !YAML.load_file(data_path_for(username))
  rescue Errno::ENOENT
    true
  end
end

# -----ROUTES-----
# homepage
get "/" do
  require_logged_in
  @today = Time.now.to_s.split[0]
  redirect "/workout/#{@today}"
end

# view workout creation page
get "/workout/:date" do
  require_logged_in
  @date = params[:date]
  @user = load_user_file(session[:username])
  erb :workout
end

# login screen
get "/login" do
  erb :login
end

# submit login form
post "/login" do
  user_credentials = load_user_credentials
  encrypted_password = user_credentials[params[:username].to_sym]

  if passwords_equal?(params[:password], encrypted_password)
    authenticate_session
    if no_user_file?(params[:username])
      new_user = User.new(params[:username].to_sym)
      create_new_user_file(new_user)
    end
    redirect "/"
  else
    session[:message] = "Username and password do not match, please try again."
    status 422
    erb :login
  end
end

# logout
get "/logout" do
  logout_session
  redirect "/"
end

# submit registration form for new user
post "/register" do
  if params[:new_user_password] == params[:new_user_password_reenter]
    register_new_user(params[:new_username], params[:new_user_password])
    session[:message] = "Your account has been created."
    redirect "/"
  else
    session[:message] = "Passwords do not match. Please try again."
    status 422
    erb :login
  end
end

# view exercise creation screen
get "/create/:date" do
  require_logged_in
  @date = params[:date]
  erb :create
end

# submit exercise creation form
post "/create/:date" do
  require_logged_in
  date, exercise = params[:date].strip, params[:exercise]
  user = load_user_file(session[:username])
  user.add_new_workout(date)
  user.add_exercise_to_workout(date, exercise)
  user.workouts[date][exercise].add_new_set(params[:reps], params[:weight])
  update_workout_file(user)
  redirect "/workout/#{date}"
end