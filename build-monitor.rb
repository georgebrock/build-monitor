require 'rubygems'
require 'sinatra'
require 'erb'
require 'rexml/document'
require 'net/http'
require 'yaml'

set :public, File.dirname(__FILE__) + '/public'

get '/' do
  erb :index, :locals => {:builds => CruiseStatus.builds}
end

module CruiseStatus

  def builds
    @last_cruise_status ||= {}

    builds = {:success => [], :failure => [], :building => [], :update_failed => []}

    servers.each do |server|
      unless doc = timeout_or_nil(30){ get_xml(server) }
        builds[:update_failed] << server
        return builds unless doc = @last_cruise_status[server]
      end

      doc.elements.each('Projects/Project') do |p|
        status = p.attributes["activity"] == "Building" ? "building" : p.attributes["lastBuildStatus"].downcase
        builds[status.to_sym] << p.attributes["name"]
      end

      @last_cruise_status[server] = doc
    end

    builds
  end

  def get_xml(server)
    host, port = server.split(':')
    http_result = Net::HTTP.start(host, port) {|http|
      http.get('/XmlStatusReport.aspx')
    }
    REXML::Document.new(http_result.body)
  end

  def servers
    @servers ||= YAML.load(File.read(File.dirname(__FILE__) + '/config/servers.yaml'))
  end

  def timeout_or_nil(value)
    Timeout::timeout(10) do
      return yield
    end
  rescue Timeout::Error
    return nil
  end

  extend self
end
