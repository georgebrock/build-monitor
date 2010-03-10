require 'rubygems'
require 'sinatra'
require 'erb'
require 'rexml/document'
require 'net/http'
require 'yaml'
require 'additional_checks'

set :public, File.dirname(__FILE__) + '/public'

def status_html
  status = erb :status, :locals => {:builds => CruiseStatus.builds}
end

get '/' do
  erb :index, :locals => {:status => status_html, :pager_urls => YAML.load(File.read(File.dirname(__FILE__) + '/config/pager.yaml'))}
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

    additional_checks.each do |checker|
      builds[checker.status.to_sym] << checker
    end

    builds
  end

  def get_xml(server)
    uri = URI.parse("http://#{server}/XmlStatusReport.aspx")
    http_result = Net::HTTP.start(uri.host, uri.port) {|http|
      http.get(uri.path)
    }

    if http_result
      dir = File.dirname(__FILE__) + '/public/cache/'+uri.host
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

  def additional_checks
    return @additional_checks if @additional_checks
    if File.exists?("config/additional_checks.yaml")
      @additional_checks = AdditionalChecks.new(YAML.load(File.read("config/additional_checks.yaml")))
      @additional_checks.start
    else
      @additional_checks = AdditionalChecks.new({})
    end
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
