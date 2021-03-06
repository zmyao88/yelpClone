# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

random_reviews = File.readlines("app/assets/images/random_reviews.txt").to_a
# open_times = [6.hours, 7.5.hours.to_i, 8.hours, 9.hours, 7.5.hours.to_i]
# close_times = [17.hours, 18.5.hours.to_i, 19.hours, 19.5.hours.to_i]
user1_id = User.order("id ASC").first.id

1100.times do |i|
  rand1 = rand(1..30)
  rand2 = rand(31..60)
  rand3 = rand(61..100)

  b = Business.create!( {  name: Faker::Company.name,
                          country_id: 1,
                          phone_number: Faker::PhoneNumber.phone_number,
                          neighborhood_id: rand(1..50),
                          latitude: Area.rand_lat,
                          longitude: Area.rand_long,
                          category1_id: rand1,
                          category2_id: rand2,
                          category3_id: rand3
                        } )

  

  # BusinessCategory.create!([
  #   { business_id: b.id, category_id: rand1 },
  #   { business_id: b.id, category_id: rand2 },
  #   { business_id: b.id, category_id: rand3 }
  # ])

  # avail_days = [0,1,2,3,4,5,6]


  Photo.create!(user_id: rand(user1_id..(user1_id+50)), business_id: i+3, file: open("https://s3.amazonaws.com/yolp_seed_images/store_#{rand(1..43)}.jpg"))
end


total_businesses = Business.count
all_users = User.all

1200.times do |i|
  business_id = rand(1..total_businesses)

  start_index = rand(random_reviews.length-21)


  review = Review.create!(
                  rating: rand(5)+1,
                  user_id: all_users.shuffle.last.id,
                  business_id: business_id,
                  body: random_reviews[start_index, rand(2..10)].join("\n"),
                  price_range: rand(5)
                )

  if rand(4) == 2
  ReviewCompliment.create!(  compliment_id: rand(1..11),
                            review_id: review.id,
                            user_id: rand(1..20),
                            body: Faker::Lorem.sentence
                          )
  end

  f_categories = FeatureCategory.all.shuffle[0,rand(3)]

  f_categories.each do |category|
    features = Feature.where(feature_category_id: category.id)
    feat_cnt = rand(features.length / 2)
    features = features.shuffle[0,feat_cnt]

    features.each do |feat|
      feat = features.shuffle!.pop

      val = if category.input_type == 1
        (rand(2) == 1 ? true : false)
      else
        true
      end

      BusinessFeature.create!(business_id: business_id, feature_id: feat.id, value: true, review_id: review.id)
    end

  end
end
