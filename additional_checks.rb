class AdditionalChecks
  class Checker
    attr_reader :name, :id, :last_run_data
    def initialize(id, name, command, interval)
      @id, @name, @command, @interval = id.to_sym, name, command, interval
      @last_status = :building
      @last_run_data = "Not yet run"
    end

    def start
      @thread = Thread.start{ update_loop }
    end

    def update_loop
      while true
        update
        sleep @interval
      end
    end

    def update
      IO.popen(@command){|f| @last_run_data = f.read }
      if $?.success?
        @last_status = :success
      else
        @last_status = :failure
      end
      puts "AdditionalChecks[#{name.inspect}] Updated to #{@last_status.inspect}"
      puts @last_run_data
    rescue Object => e
      p e
    end

    def status
      @last_status
    end
  end

  def initialize(config)
    @checkers = {}
    config.each do |id, settings|
      @checkers[id.to_sym] = Checker.new(id, settings["name"] || id, settings["command"], (settings["interval"] || 60).to_i)
    end
  end

  def each(&block)
    @checkers.values.each(&block)
  end

  def [](k)
    @checkers[k]
  end

  def start
    @checkers.values.each{|c| c.start }
  end
end
