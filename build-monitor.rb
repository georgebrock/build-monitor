require 'rubygems'
require 'sinatra'
require 'erb'
require 'rexml/document'
require 'net/http'
require 'yaml'

set :public, File.dirname(__FILE__) + '/public'

def status_html
  status = erb :status, :locals => {:builds => CruiseStatus.builds}
end

get '/' do
  erb :index, :locals => {:status => status_html}
end

get '/status' do
  status_html
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

    if http_result
      dir = File.dirname(__FILE__) + '/public/cache/'+host
      Dir.mkdir(dir) unless File.exists?(dir)
      f = File.open(dir+'/XmlStatusReport.aspx', 'w')
      f.write(http_result.body)
      f.close
    end

    REXML::Document.new(http_result.body)
  end

  def servers
    @servers ||= YAML.load(File.read(File.dirname(__FILE__) + '/config/servers.yaml'))
  end

  def timeout_or_nil(value)
    Timeout::timeout(10) do
      return yield
    end
  rescue
    return nil
  end

  extend self
end
