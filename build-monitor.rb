require 'rubygems'
require 'sinatra'
require 'erb'
require 'rexml/document'
require 'net/http'

set :public, File.dirname(__FILE__) + '/public'

get '/' do
  builds = cruise_status
  if builds[:failure].empty? && builds[:building].empty?
    erb :ok
  else
    erb :index, :locals => {:builds => builds}
  end
end

def cruise_status
  builds = {:success => [], :failure => [], :building => []}
  ['integration01', 'integration02'].each do |host|
    xml = get_xml(host)
    doc = REXML::Document.new(xml)
    doc.elements.each('Projects/Project') do |p|
      status = p.attributes["activity"] == "Building" ? "building" : p.attributes["lastBuildStatus"].downcase
      builds[status.to_sym] << p.attributes["name"]
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
