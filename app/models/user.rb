class User < ActiveRecord::Base
  attr_accessible :birthdate, :email, :first_name, :last_name, :nickname, :session_token, :password, :img_url
  attr_accessible :year, :month, :day
  attr_reader :password

  validates :email, :session_token, :first_name, :last_name, presence: true
  validates :password_digest, presence: { message: "Password cannot be blank." }
  validates :password, length: { minimum: 6 }, on: :create
  before_validation :ensure_token

  has_one(
    :bio,
    class_name: "UserBio",
    primary_key: :id,
    foreign_key: :user_id
  )

  has_many(
    :reviews,
    class_name: "Review",
    primary_key: :id,
    foreign_key: :user_id
  )

  #--temporary placeholders until associations can be made
  def friends
    [1,2,3,4,5,6,7,8]
  end

  def self.random_token
    SecureRandom::urlsafe_base64(16)
  end

  def self.verify_credentials(email, secret)
    user = User.find_by_email(email)

    if user && user.pw_matches?(secret)
      user
    else
      nil
    end
  end

  def set_avatar(new_url)
    return if new_url.blank?

    self.img_url = new_url
    self.save!
  end

  def password=(secret)
    @password = secret
    self.password_digest = BCrypt::Password.create(secret)
  end

  def pw_matches?(secret)
    BCrypt::Password.new(self.password_digest).is_password?(secret)
  end

  def reset_token
    self.session_token = self.class.random_token
    self.save!
  end


  def name
    "#{self.first_name} #{self.last_name[0]}."
  end


  private

  def ensure_token
    self.session_token ||= self.class.random_token
  end

end
