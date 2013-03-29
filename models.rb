Dir[File.expand_path('models/**/*.rb', File.dirname(__FILE__))].each do |rb| 
  require rb
end

