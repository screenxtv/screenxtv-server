module RoutingSpecHelper

  def routing *routes
    routes.define_singleton_method :should, ->(dst){
      routes.each{|routing|routing.should dst}
    }
    routes.define_singleton_method :should_not, ->(dst){
      routes.each{|routing|routing.should_not dst}
    }
    routes
  end

end