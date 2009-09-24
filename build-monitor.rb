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
  builds = []
  ['integration01', 'integration02'].each do |host|
    xml = get_xml(host)
    doc = REXML::Document.new(xml)
    doc.elements.each('Projects/Project') do |p|
      builds << {
        :title => p.attributes["name"],
        :status => p.attributes["activity"] == "Building" ? "building" : p.attributes["lastBuildStatus"].downcase
      }
    end
  end
  builds
end

def get_xml(host)
  http_result = Net::HTTP.start(host, '3333') {|http|
    http.get('/XmlStatusReport.aspx')
  }
  http_result.body
end
