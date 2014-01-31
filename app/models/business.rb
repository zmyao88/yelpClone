class Business < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks

  self.include_root_in_json = false

  mapping do
    indexes :name, boost: 100

    indexes :neighborhood_id, type: "integer", index: :not_analyzed
    indexes :price_range_avg, type: "integer", index: :not_analyzed
    indexes :latitude, type: "float", index: :not_analyzed
    indexes :longitude, type: "float", index: :not_analyzed


    indexes :business_features do
      indexes :feature_id, type: "integer", index: :not_analyzed
    end

    indexes :business_categories do
      indexes :category_id, type: "integer", index: :not_analyzed
      indexes :main_category_id, type: "integer", index: :not_analyzed
    end

    indexes :reviews do
      indexes :body
    end

    indexes :top_review do
      indexes :body
    end
  end

  attr_accessible :country_id ,:name ,:address1 ,:address2 ,:city ,:state ,:zip_code ,:phone_number ,:website, :neighborhood_id, :category_ids, :latitude, :longitude
  attr_accessible :rating_avg, :store_front_id, :reviews_count, :photos_count, :price_range_avg

  validates :name, :country_id, presence: true
  validates :country_id, :neighborhood_id, numericality: true
  validates :store_front_id, numericality: true, allow_nil: true

  geocoded_by :full_street_address
  after_validation :geocode

  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode

  before_validation :set_neighborhood
  after_touch { tire.update_index }

  belongs_to(
    :country,
    class_name: "Country",
    primary_key: :id,
    foreign_key: :country_id
  )

  has_many(
    :reviews,
    class_name: "Review",
    primary_key: :id,
    foreign_key: :business_id,
    inverse_of: :business,
    dependent: :destroy
  )

  has_one(
    :top_review,
    class_name: "Review",
    primary_key: :id,
    foreign_key: :business_id,
    order: "rating DESC",
    include: :user
  )

  has_many(
    :business_categories,
    class_name: "BusinessCategory",
    primary_key: :id,
    foreign_key: :business_id,
    dependent: :destroy
  )

  has_many :categories, through: :business_categories, source: :category

  has_many(
    :business_features,
    class_name: "BusinessFeature",
    primary_key: :id,
    foreign_key: :business_id
  )

  has_many :features, through: :business_features, source: :feature

  belongs_to(
    :store_front_photo,
    class_name: "Photo",
    primary_key: :id,
    foreign_key: :store_front_id
  )

  belongs_to(
    :neighborhood,
    class_name: "Neighborhood",
    primary_key: :id,
    foreign_key: :neighborhood_id
  )

  has_many(
    :photos,
    class_name: "Photo",
    primary_key: :id,
    foreign_key: :business_id
  )

  has_many(
    :main_photos,
    class_name: "Photo",
    primary_key: :id,
    foreign_key: :business_id,
    order: "helpful_sum DESC"
  )

  has_many :photo_details, through: :photos, source: :photo_details

  has_many(
    :tips,
    class_name: "Tip",
    primary_key: :id,
    foreign_key: :business_id,
    dependent: :destroy
  )

  has_many(
    :bookmarks,
    class_name: "Bookmark",
    primary_key: :id,
    foreign_key: :business_id,
    dependent: :destroy
  )

  has_many :bookmarkers, through: :bookmarks, source: :user

  has_many(
    :business_hours,
    class_name: "BusinessHour",
    primary_key: :id,
    foreign_key: :business_id,
    order: :day_id,
    dependent: :destroy
  )

  def store_front_count(size)
    photos.select("photos.id, COUNT(CASE WHEN photo_details.store_front THEN 1 ELSE null END) AS photo_count")
          .joins("LEFT JOIN photo_details ON photo_details.photo_id = photos.id")
          .group("photos.id")
          .order("photo_count DESC, photos.id DESC")
          .limit(size).all
  end

  def full_street_address
    a1 = address1 || ""
    a2 = address2 || ""
    c1 = city || ""
    s1 = state || ""
    z1 = zip_code || ""

    "#{a1} #{a2} #{c1}, #{s1} #{z1}"
  end

  def set_neighborhood
    self.neighborhood_id = Neighborhood.random_neighborhood(1) unless self.neighborhood_id
  end

  def address=(arg)
    addr = arg.split(",").map { |a| a.strip }
    self.address1 = addr[0]
    self.city = addr[1]
    self.state = addr[2].split(" ")[0]
    self.zip_code = addr[2].split(" ")[1].to_i
  end

  def <=>(otherBiz)
    return 1 if otherBiz.rating < rating
    return -1 if otherBiz.rating > rating
    0
  end

  def self.recent(num)
    Business.limit(num).includes(:neighborhood, :photos)
  end

  def gps
    { lat: latitude, lng: longitude }
  end

  def avatar(size = nil)
    return "/assets/temp/default_house.jpg" unless store_front_id

    if photos.loaded?
      photos.select { |p| p.id == store_front_id }[0].url(size)
    elsif store_front_photo
      store_front_photo.url(size)
    else
      Photo.find(store_front_id).url(size)
    end
  end

  def get_highlight_reviews(amount)
    @highlight_reviews ||= self.reviews.order("rating DESC").first(4)
  end

  def missing_store_front?
    self.store_front_id.nil?
  end

  def rating
    self.rating_avg
  end

  def rating_string
    return "0" if self.rating < 1
    l,r = rating_avg.round(1).to_s.split(".")

    r = r.to_i < 5 ? "0" : "5"

    l + r
  end

  def now_hours
    # Sunday is 0
    d = if business_hours.loaded?
        business_hours.select { |d| d.day_id == Time.now.wday}[0]
      else
        business_hours.where(day_id: Time.now.wday)[0]
      end

    d ? d.open_hours : ""
  end

  def is_open?
    d = business_hours.where(day_id: Time.now.wday)[0]

    time_now = Time.now.hour.hours + Time.now.min.minutes
    return true if d && (d.time_open..d.time_close) === time_now

    false
  end

  def creation_transaction(review_params, photo_params)
    trans_errors = []

    self.transaction do
      photo = nil
      review = nil
      unless review_params[:body].blank?
        review = self.reviews.build(review_params)

        if photo_params[:file]
          photo = review.photos.build(photo_params)
        end
      end

      save

      trans_errors += photo.errors.full_messages if photo
      trans_errors += review.errors.full_messages if review
      trans_errors += self.errors.full_messages
    end

    trans_errors
  end

  def location
    [{ type: "point", lat: latitude, lon: longitude }]
  end

  def as_json(options={})
    if options.empty?
      super(methods: [:avatar, :rating_string, :top_review ], include: [:categories, :business_features, neighborhood: { include: :area } ])
    else
      super options
    end
  end

  def to_indexed_json
    to_json( include: { categories: { only: [:id, :name, :main_category_id] }, 
                        neighborhood: { include: :area },
                        business_features: { only: [:feature_id] },
                        reviews: { only: [:id, :body] }
                      },
              methods: [:avatar, :rating_string, :location],
              only: [:name, :id, :address1 ,:address2, :neighborhood_id, :city, :zip_code, :price_range_avg]
            )
  end

  def self.es_suggest(input_text)

    Business.search do
      suggest :suggest_title do
        text input_text

        term :name, size: 3, sort: 'frequency'
      end

      suggest :phrase_suggest_title do
        text input_text

        phrase :name, size: 3 do
          # Optinally, configure the `smoothing` option...
          #
          smoothing :stupid_backoff, discount: 0.5

          # ...or the `generator` option.
          # generator :name, min_word_len: 1
        end
      end



    end
  end

  def self.es_query(search_string, distance, center, options = {})
    options ||= {}

    p = options[:price_range]
    n = options[:neighborhood_id]
    f = options[:feature_id]
    c = options[:category_id]
    m = options[:main_category_id]

    Business.search do
      query { match [:name, "top_review.body"], search_string } unless search_string.blank?

      filter :terms, price_range_avg: p if p
      filter :terms, neighborhood_id: n if n
      filter :terms, "business_features.feature_id" => f if f
      filter :terms, "categories.id" => c if c
      filter :terms, "categories.main_category_id" => m if m
      highlight "name", "top_review.body", options: { tag: '<strong class="highlight-text">', fragment_size: 200 }
    end
  end


  def self.es_query2(search_string, distance, center, options = {})
    options ||= {}

    p = options[:price_range]
    n = options[:neighborhood_id]
    f = options[:feature_id]
    c = options[:category_id]
    m = options[:main_category_id]
    bounds = GoogleMap.determine_bounds(center, distance.to_f) if distance

    Business.search do
      # query { match :name, search_string } unless search_string.blank?
      # query { string search_string } unless search_string.blank?
      # query { multi_match :search_string, :body}
      # filter :range do
      #   latitude: [gte: bounds[0], lte: bounds[2]]
      #   longitude: [gte: bounds[1], lte: bounds[3]]
      # end
      query do
        nested :path => 'top_review' do
          query do
            match "top_review.body", search_string
          end
        end
      end

      filter :terms, price_range_avg: p if p
      filter :terms, neighborhood_id: n if n
      filter :terms, "business_features.feature_id" => f if f
      filter :terms, "categories.id" => c if c
      filter :terms, "categories.main_category_id" => m if m


      # sort do
      #   by :updated_at, :desc
      #   by :num_comments, :desc
      # end


      #name not really working...
      highlight "name", "top_review.body"
    end
  end
end
