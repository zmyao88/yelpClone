# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # load "#{Rails.root}/db/test_seeds.rb"
  config.include FactoryGirl::Syntax::Methods
  
  config.include NavigationHelpers, type: :feature

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end

def setup_db
  User.create!( email: "guest@example.com", password: "123456", first_name: "Guest", last_name: "Gusterson" )
  Country.create(name: "USA")
  MainCategory.create!(name: "Restaurants")
  City.create!(name: "New York")

  Area.create!(name: "Manhattan", city_id: 1)
  Neighborhood.create!(name: "Harlem", area_id: 1)
  Category.create(main_category_id: 1, name: "Afghan")
  Category.create(main_category_id: 1, name: "American")
  Category.create(main_category_id: 1, name: "Italian")

  PriceRange.create!([
    {name: "$", description: "$5-10"},
    {name: "$$", description: "$11-30"},
    {name: "$$$", description: "$31-60"},
    {name: "$$$$", description: "$61+"}
  ])

  FeatureCategory.create!([
    {name: "General Features", input_type: 1},
    {name: "Alcohol", input_type: 2},
    {name: "Meals Served", input_type: 2},
    {name: "Music", input_type: 1},
    {name: "Parking", input_type: 2},
    {name: "Wi-Fi", input_type: 1},
    {name: "Smoking", input_type: 1},
    {name: "Ambience", input_type: 2},
    {name: "Attire", input_type: 1},
    {name: "Noise Level", input_type: 1}
  ])
  
end


def signupUser(username)
  visit "/users/new"

  fill_in "user_first_name", with: "Charlie"
  fill_in "user_last_name", with: "Guest"
  fill_in "user_email", with: username
  fill_in "user_password", with: "123456"

  click_button "signup-user"
end

def loginGuest
  visit "/"

  click_button "login-guest"
end

def makeBusiness(biz_name)
  visit("/businesses/new")

    # save_and_open_page

  fill_in "business_name", with: biz_name
  fill_in "business_address1", with: "770 Broadway Ave"
  fill_in "business_city", with: "New York City"
  fill_in "business_state", with: "NY"
  fill_in "business_zip_code", with: "10003"
  select "Afghan", from: "business[category_ids][]"

  click_button "add-business"
end