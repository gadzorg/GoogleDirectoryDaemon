require 'gorg_service'
class Application

  #Initialize running environment and dependencies
  # TODO Allow Logger overriding

  def consumer
    @consumer||=GorgService::Consumer.new
  end

  #Run the worker
  # Exit with Ctrl+C
  def run
    begin
      puts " [*] Running #{self.class.config[:application_name]} with pid #{Process.pid}"
      puts " [*] Running in #{self.class.env} environment"
      puts " [*] To exit press CTRL+C or send a SIGINT"
      self.start
      loop do
        sleep(1)
      end
    rescue SystemExit, Interrupt => _
      self.stop
    end
  end

  def start
    self.class.logger.info("Starting application")
    consumer.start
  end

  def stop
    self.class.logger.info("Stopping application")
    consumer.stop
  end

  class<<self
    def env_prefix(prefix)
      @env_prefix=prefix.upcase
    end

    def prefix
      @env_prefix
    end

    def env
      ENV["#{@env_prefix}_ENV"] || ENV["RAKE_ENV"] || "development"
    end

    def config
      @config||=Application::Configuration.new(env)
    end

    def root
      File.expand_path('../..', APP_PATH || __FILE__)
    end

    def logger
      unless @logger
        STDOUT.sync = true #Allow realtime logging in Heroku
        @logger = Logger.new(STDOUT)

        @logger.level = case (self.config[:logger_level]||"").downcase
                          when "debug"
                            Logger::DEBUG
                          when "info"
                            Logger::INFO
                          when "warn"
                            Logger::WARN
                          when "error"
                            Logger::ERROR
                          when "fatal"
                            Logger::FATAL
                          when "unknown"
                            Logger::UNKNOWN
                          else
                            Logger::DEBUG
                        end
      end
      @logger
    end
  end
end

class Application

  env_prefix 'GDD'

end

