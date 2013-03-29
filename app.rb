require 'cuba/render'

require_relative 'libs'
require_relative 'models'
require_relative 'routes'

Cuba.plugin Cuba::Render

Cuba.settings[:render][:template_engine] = 'slim'

Cuba.define do

  on default do
    run UserRoutes
  end

end

