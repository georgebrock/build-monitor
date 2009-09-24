require 'rubygems'
require 'sinatra'
require 'erb'
require 'rexml/document'
require 'net/http'

set :public, File.dirname(__FILE__) + '/public'

get '/' do
  erb :index, :locals => {:builds => builds}
end

def builds
  xml = get_xml
  doc, builds = REXML::Document.new(xml), []
  doc.elements.each('Projects/Project') do |p|
    builds << {
      :title => p.attributes["name"],
      :status => p.attributes["activity"] == "Building" ? "building" : p.attributes["lastBuildStatus"].downcase
    }
  end
  builds
end

def get_xml
  http_result = Net::HTTP.start('integration01', '3333') {|http|
    http.get('/XmlStatusReport.aspx')
  }
  http_result.body
end
