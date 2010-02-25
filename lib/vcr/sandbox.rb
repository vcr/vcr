require 'yaml'

module VCR
  class Sandbox
    attr_reader :name, :record_mode

    def initialize(name, options = {})
      @name = name
      @record_mode = options[:record] || :unregistered
      set_fakeweb_allow_net_connect
      load_recorded_responses
    end

    def destroy!
      write_recorded_responses_to_disk
      deregister_original_recorded_responses
      restore_fakeweb_allow_net_conect
    end

    def recorded_responses
      @recorded_responses ||= []
    end

    def store_recorded_response!(recorded_response)
      recorded_responses << recorded_response
    end

    def cache_file
      File.join(VCR::Config.cache_dir, "#{name.to_s.gsub(/[^\w\-]+/, '_')}.yml") if VCR::Config.cache_dir
    end

    private

    def new_recorded_responses
      recorded_responses - @original_recorded_responses
    end

    def should_allow_net_connect?
      [:unregistered, :all].include?(record_mode)
    end

    def set_fakeweb_allow_net_connect
      @orig_fakeweb_allow_connect = FakeWeb.allow_net_connect?
      FakeWeb.allow_net_connect = should_allow_net_connect?
    end

    def restore_fakeweb_allow_net_conect
      FakeWeb.allow_net_connect = @orig_fakeweb_allow_connect
    end

    def load_recorded_responses
      @original_recorded_responses = []
      return if record_mode == :all

      if cache_file
        @original_recorded_responses = @recorded_responses = File.open(cache_file, 'r') { |f| YAML.load(f.read) } if File.exist?(cache_file)
      end

      recorded_responses.each do |rr|
        FakeWeb.register_uri(rr.method, rr.uri, { :response => rr.response })
      end
    end

    def write_recorded_responses_to_disk
      if VCR::Config.cache_dir && new_recorded_responses.size > 0
        File.open(cache_file, 'w') { |f| f.write recorded_responses.to_yaml }
      end
    end

    def deregister_original_recorded_responses
      @original_recorded_responses.each do |rr|
        FakeWeb.remove_from_registry(rr.method, rr.uri)
      end
    end
  end
end