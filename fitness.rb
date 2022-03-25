require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "bcrypt"
require "yaml"
require "pry"

require_relative "./database_persistence"
require_relative "./exercise"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @storage = DatabasePersistence.new
end

helpers do
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

# loads in existing yaml file and merges provided hash with existing data
def update_credential_file(file_path, credentials)
  data = YAML.load_file(file_path)
  data = !!data ? data.merge(credentials) : credentials
  File.open(file_path, "w") { |file| file.write(data.to_yaml) }
end

# REGISTER NEW USER AND CREATE USER DATA FILE
# register a new user and store the encrypted credentials in the yaml file
def register_new_user(username, plaintext_password)
  new_user_credentials = { username.to_sym => encrypt(plaintext_password) }
  update_credential_file(data_path + "/users.yaml", new_user_credentials)
  @storage.create_user_record(username)
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

# check to see if user is authenticated
def authenticated?
  !!session[:username]
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
  @exercises = @storage.fetch_exercises_for(session[:username], @date)
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
    if @storage.user_record_exists?(params[:username]) == false
      @storage.create_user_record(params[:username])
    end
    authenticate_session
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

  date = params[:date].strip
  name = params[:exercise]
  weight = params[:weight]
  reps = params[:reps]

  exercise = Exercise.new(name: name, reps: reps, weight: weight, date: date)

  @storage.save_exercise(exercise, session[:username])
  redirect "/workout/#{date}"
end