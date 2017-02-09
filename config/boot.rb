
#Add App and Lib directories to load path
$LOAD_PATH.unshift File.expand_path('../../app', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require File.expand_path("../application",__FILE__)

require File.expand_path("../configuration",__FILE__)
Dir[File.expand_path("../../config/initializers/*.rb",__FILE__)].each {|file|require file}

Dir[File.expand_path("#{Application.root}/app/**/*.rb",__FILE__)].each {|file| require file }