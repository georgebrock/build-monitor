require 'rubygems'
require 'sinatra'
require 'erb'
require 'rexml/document'
require 'net/http'
require 'yaml'

set :public, File.dirname(__FILE__) + '/public'

get '/' do
  erb :index, :locals => {:builds => cruise_status}
end

def cruise_status
  builds = {:success => [], :failure => [], :building => []}
  servers.each do |server|
    xml = get_xml(server)
    doc = REXML::Document.new(xml)
    doc.elements.each('Projects/Project') do |p|
      status = p.attributes["activity"] == "Building" ? "building" : p.attributes["lastBuildStatus"].downcase
      builds[status.to_sym] << p.attributes["name"]
    end
  end
  builds
end

def get_xml(server)
  host, port = server.split(':')
  http_result = Net::HTTP.start(host, port) {|http|
    http.get('/XmlStatusReport.aspx')
  }
  http_result.body
end

def servers
  @servers ||= YAML.load(File.read(File.dirname(__FILE__) + '/config/servers.yaml'))
end
