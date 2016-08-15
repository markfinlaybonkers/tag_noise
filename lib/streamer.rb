require 'pusher'
require 'sentimental'

module Streamer
  class TimerStop < StandardError;
  end

  class Stream
    def initialize

      configure_pusher
      configure_twitter
      configure_analyser

      run

    end

    def configure_pusher
      Pusher.app_id = ' '
      Pusher.key = ' '
      Pusher.secret = ' '
      Pusher.cluster = 'eu'
      Pusher.logger = Rails.logger
      Pusher.encrypted = true
    end

    def configure_analyser
      @analyzer = Sentimental.new
      @analyzer.load_defaults
      @analyzer.threshold = 0.1
    end

    def configure_twitter
      @client = Twitter::Streaming::Client.new do |config|
        config.consumer_key = ' '
        config.consumer_secret = ' '
        config.access_token = ' '
        config.access_token_secret = ' '
      end
    end

    def run
      loop do
        begin
          puts 'starting'
          stream
        rescue => e
          sleep(5)
          puts 'Starting Again'
        end
      end
    end

    def stream
      timer = Time.now
      tags = Tag.all.collect(&:name).join(',')
      puts "tracking: #{tags}"
      @client.filter(track: tags) do |object|
        print '.'
        if object.is_a?(Twitter::Tweet)
          sentiment = @analyzer.sentiment object.text
          score = @analyzer.score object.text
          Pusher.trigger('test_channel', 'my_event', {
              message: [object.text, sentiment.upcase, score.round(3)].join('  ')
          })
        end
        raise if (timer + 1.minute + 5.seconds) < Time.now
      end
    end
  end
end
