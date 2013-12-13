class PhotosController < ApplicationController
  before_filter :require_current_user!, except: [:show]

  def new
    @photo = Photo.new
    @business = params[:business_id] ? Business.find(params[:business_id]) : nil
  end

  def create
    @photo = current_user.photos.new(params[:photo])
    fail
    if @photo.save
      if params[:business_id]
        redirect_to business_url(params[:business_id])
      else
        redirect_to user_url(current_user.id)
      end
    else
      @business = @photo.business_id ? Business.find(@photo.business_id) : nil
      flash[:errors] = @photo.errors.full_messages
      render :new
    end
  end

  def biz_show
    @photo = Photo.new
    @business = params[:business_id] ? Business.find(params[:business_id]) : nil
    @photos = @business.photos
    @select_id = @photos.index(Photo.find(params[:photo_id]))
    render :show
  end

  def user_show
    @photo = Photo.new
    @user = User.find(params[:id])
    @photos = @business.photos
    @select_id = @photos.index(Photo.find(params[:photo_id]))
    render :show
  end

  def destroy

  end

  def edit
    @photo = Photos.find(params[:id])
  end

  def update
    @photo = Photos.find(params[:id])
  end
end