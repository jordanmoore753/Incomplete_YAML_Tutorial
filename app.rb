require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "rack"
require "yaml"
require "bcrypt"
require_relative "user_obj"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def data_path # this method returns the absolute path to the users directory
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data/users", __FILE__)
  else
    File.expand_path("../data/users", __FILE__)
  end
end

def create_user_yml(obj) # YOU WILL MODIFY THIS METHOD
  # YOUR CODE WILL GO HERE
end

def create_user(username, pw) # this instantiates the user object and encrypts the password
  User.new(username, BCrypt::Password.create(params[:password]).split('').join('')) 
end

def all_users # this method returns an array of all the user objects in the users folder
  pattern = data_path + "/*"
  users = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  pattern.gsub!('*', '')
  users.map { |file| YAML.load_file(pattern + file) }
end

def find_user(username) # this method either returns the user object whose user attribute matches the given string, or false
  users = all_users
  users.each { |obj| return obj if obj.user == username }
  false
end

def valid_credentials?(obj, username, obj_two, input) # validates credentials
  if obj.user == username
    bcrypt_password = BCrypt::Password.new(obj_two)
    bcrypt_password == input
  else
    false
  end
end

def valid_password?(password, confirm_pw) #  validates password
  password == confirm_pw
end

def valid_username?(username) # ensures that username doesn't contain invalid characters or existing username
  invalid_chars = %w(! @ # $ % ^ & * ( ) - _ + = / ] [ } { : ; ' " . , ? ` ~ < >) << ' '
  @users.each { |obj| return false if obj.user == username }
  username.each_char { |chr| return false if invalid_chars.include?(chr) }
  true
end

def return_interests
  user = find_user(session[:curr_user])
  user.interests
end

def logged_in?
  redirect "/" if session[:curr_user].nil?
end

get "/" do 
  @interests = return_interests if !session[:curr_user].nil?
  erb :index
end

get "/register" do 
  erb :register
end

get "/login" do 
  erb :login
end

get "/add_interest" do 
  erb :add_interest
end

post "/add_interest" do # YOU WILL MODIFY THIS
  logged_in?

  @user = find_user(session[:curr_user]) 
  # ADD INTEREST TO @user
  # REWRITE THE YML FILE

  session[:success] = "Interest added."
  redirect "/"
end

post "/login" do 
  @user = find_user(params[:username])
  @users = all_users

  if @user != false && valid_credentials?(@user,
                        params[:username], 
                        @user.pw, 
                        params[:password])

    session[:success] = "#{params[:username]} logged in."
    session[:curr_user] = params[:username]
    redirect "/"
  else
    session[:error] = "Invalid credentials."
    erb :login
  end
end

post "/register" do
  @users = all_users

  if valid_username?(params[:username]) &&
     valid_password?(params[:password], params[:confirm_pw]) # validating the username and password

    obj = create_user(params[:username], params[:password]) # creating the user object
    create_user_yml(obj) # writes the user object to a YML file in the users folder

    session[:success] = "User #{obj.user} created."
    redirect "/login"
  else
    session[:error] = "Try another username or ensure your passwords match."
    erb :register
  end
end

post "/logout" do 
  session.delete(:curr_user)
  session[:success] = "User signed out."
  redirect "/"
end
