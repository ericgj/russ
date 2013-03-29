Dir[File.expand_path('lib/**/*.rb', File.dirname(__FILE__))].each do |rb| 
  require rb
end

