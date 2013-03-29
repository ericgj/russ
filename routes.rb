Dir[File.expand_path('routes/**/*.rb', File.dirname(__FILE__))].each do |rb| 
  require rb
end

