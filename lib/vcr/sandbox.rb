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
      restore_fakeweb_allow_net_conect
    end

    def recorded_responses
      @recorded_responses ||= []
    end

    def store_recorded_response!(recorded_response)
      recorded_responses << recorded_response
    end

    private

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
      if VCR::Config.cache_dir
        yaml_file = File.join(VCR::Config.cache_dir, "#{name}.yml")
        @recorded_responses = File.open(yaml_file, 'r') { |f| YAML.load(f.read) } if File.exist?(yaml_file)
      end
    end

    def write_recorded_responses_to_disk
      if VCR::Config.cache_dir && recorded_responses.size > 0
        yaml_file = File.join(VCR::Config.cache_dir, "#{name}.yml")
        File.open(yaml_file, 'w') { |f| f.write recorded_responses.to_yaml }
      end
    end
  end
end