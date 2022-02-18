ENV["RACK_ENV"] = "test"

require "fileutils"

require "minitest/autorun"
require "rack/test"

require_relative "../fitness"

class FitnessTests < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def session
    last_request.env["rack.session"]
  end

  # -------TESTS BELOW--------

  # HOMEPAGE
  def test_homepage_logged_in
    get "/", {}, admin_session

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Workout for"
  end

  def test_homepage_logged_out
    get "/"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "Sign In"
  end

  # LOGGING IN
  def test_display_login
    get "/login"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Sign In"
  end

  def test_submit_login_form
    post "/login", username: "admin", password: "secret"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "Workout for"
  end

  def test_submit_login_form_with_bad_credentials
    post "/login", username: "guest", password: "letmein"

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username and password do not match, please try again."
  end

  def test_add_exercise
    today = Time.now.to_s.split[0]
    post "/create/#{today}", {exercise: "Bench Press", reps: 10, weight: 200}, admin_session

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "<h3>Bench Press</h3>"
  end

  def test_register_new_user_passswords_match
    post "/register", { new_username: "test_user", 
                        new_user_password: "password", 
                        new_user_password_reenter: "password" 
                      }
    assert_equal true, File.exists?(data_path_for("test_user"))

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 302, last_response.status
    
    get last_response["Location"]

    assert_includes last_response.body, "Sign In"
  end

  def test_register_new_user_passswords_not_match
    post "/register", { new_username: "test_user", 
                        new_user_password: "password", 
                        new_user_password_reenter: "guest" 
                      }

    assert_equal 422, last_response.status
    
    assert_includes last_response.body, "Passwords do not match. Please try again."
  end
end