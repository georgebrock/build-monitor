require 'rubygems'
require 'sinatra'
require 'erb'
require 'rexml/document'

set :public, File.dirname(__FILE__) + '/public'

get '/' do
  erb :index, :locals => {:builds => builds}
end

def builds
  xml = File.read('/Users/georgebrocklehurst/Downloads/XmlStatusReport.aspx')
  doc, builds = REXML::Document.new(xml), []
  doc.elements.each('Projects/Project') do |p|
    builds << {
      :title => p.attributes["name"],
      :status => p.attributes["activity"] == "Building" ? "building" : p.attributes["lastBuildStatus"].downcase
    }
  end
  builds
end
