module SearchesHelper

  def split_string
    word_spaced = search_params[:find].split(" ")

    words = []
    word_spaced.each do |w|
      if w.index(",")
        word += w.split(",")
      else
        words << w
      end
    end

    words
  end

  def make_query(search_params, search_string, search_location)
    #search elements
    # find, near
    # sort, distance
    # neighborhood_id, price_range, feature_id, category_id

    where_q = []
    where_v = []
    order_q = "relevence DESC"
    select_q = ""

    joins = []
    poss_joins = {
      reviews: "JOIN reviews ON businesses.id = reviews.business_id",
      feature_id: "JOIN business_features ON businesses.id = business_features.business_id",
      category_id: "JOIN business_categories ON businesses.id = business_categories.business_id"
    }


    unless search_string.nil? || search_string == ""
      #words = split_words(search_params[:find])
      where_q << "LOWER(businesses.name) LIKE ?"
      where_v << "%#{search_params[:find].downcase}%"
    end

    search_params[:neighborhood_id] && search_params[:neighborhood_id].each do |n|
      where_v << n.to_i
      where_q << "neighborhood_id = ?"
    end

    search_params[:feature_id] && search_params[:feature_id].each do |f|
      if poss_joins[:feature_id]
        joins << poss_joins[:feature_id]
        poss_joins.delete(:feature_id)
      end

      where_v << f.to_i
      where_q << "feature_id = ?"
    end

    search_params[:category_id] && search_params[:category_id].each do |c|
      if poss_joins[:category_id]
        joins << poss_joins[:category_id]
        poss_joins.delete(:category_id)
      end

      where_v << c.to_i
      where_q << "category_id = ?"
    end

    # search_params[:price_range] do |p|
    #   if poss[:reviews]
    #     joins << poss[:reviews]
    #     poss.delete(:reviews)
    #   end
    #
    #   where_v << search_params[:price_range]
    #   where_q << "price_range = ?"
    # end

    # near = ""
    # if search_params[:near]
    #
    # end
    #
    # distance = ""
    # #figure out after google maps and business have gps coord
    # # if search_params[:distance]
    # #   distance = "WHERE location BETWEEN ( AND )"
    # # end
    #
    if search_params[:sort] == "rated"
      if poss_joins[:reviews]
        joins << poss_joins[:reviews]
        poss_joins.delete(:reviews)
      end
      select_q = ", AVG(reviews.rating) AS rating_avg"
      order_q = "rating_avg DESC, " + order_q
    elsif search_params[:sort] == "reviewed"
      if poss_joins[:reviews]
        joins << poss_joins[:reviews]
        poss_joins.delete(:reviews)
      end
      # end
      # "ORDER BY COUNT() AS review_count"
    else
      ""
    end




    s_join = joins.join(' ') if joins.any?
    s_where = where_q.any? ? "WHERE #{where_q.join(' OR ')}" : ""
    #w = "JOIN business_features ON businesses.id = business_features.business_id WHERE business_features.id = ?"
    s_sort = ""

    sql = <<-SQL
      SELECT businesses.*, COUNT(businesses.id) AS relevence #{select_q}
      FROM businesses
      #{s_join}
      #{s_where}
      GROUP BY businesses.id
      ORDER BY #{order_q}
    SQL

    sql_param = [sql] + where_v
    Business.find_by_sql(sql_param)
  end

  def recursive_join(i,sql_part)
    if i < 2
      "JOIN (SELECT business.* FROM businesses #{sql_part}) as b_#{i} ON businesses.id = b_#{i}.id"
    else
      result = recursive_join(i-1, sql_part)
      "JOIN (SELECT business.* FROM businesses #{sql_part}) as b_#{i} ON businesses.id = b_#{i}.id " + result
    end
  end

end
