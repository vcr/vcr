module VCR
  def create_cassette!(*args)
    warn "WARNING: VCR.create_cassette! is deprecated.  Instead, use: VCR.insert_cassette."
    insert_cassette(*args)
  end

  def destroy_cassette!(*args)
    warn "WARNING: VCR.destroy_cassette! is deprecated.  Instead, use: VCR.eject_cassette."
    eject_cassette(*args)
  end

  def with_cassette(*args, &block)
    warn "WARNING: VCR.with_cassette is deprecated.  Instead, use: VCR.use_cassette."
    use_cassette(*args, &block)
  end

  class Cassette
    def destroy!(*args)
      warn "WARNING: VCR::Cassette#destroy! is deprecated.  Instead, use: VCR::Cassette#eject."
      eject(*args)
    end

    def cache_file(*args)
      warn "WARNING: VCR::Cassette#cache_file is deprecated.  Instead, use: VCR::Cassette#file."
      file(*args)
    end

    def allow_real_http_requests_to?(uri)
      warn "WARNING: VCR::Cassette#allow_real_http_requests_to? is deprecated and should no longer be used."
      VCR.http_stubbing_adapter.ignore_localhost && %w(localhost 127.0.0.1).include?(uri.host)
    end

    private

    def deprecate_old_cassette_options(options)
      if @record_mode == :unregistered
        @record_mode = :new_episodes
        Kernel.warn "WARNING: VCR's :unregistered record mode is deprecated.  Instead, use: :new_episodes."
      end

      message = "VCR's :allow_real_http cassette option is deprecated.  Instead, use the ignore_localhost configuration option."
      if options[:allow_real_http] == :localhost
        @original_ignore_localhost = VCR.http_stubbing_adapter.ignore_localhost
        VCR.http_stubbing_adapter.ignore_localhost = true
        Kernel.warn "WARNING: #{message}"
      elsif options[:allow_real_http]
        raise ArgumentError.new(message)
      end
    end

    def restore_ignore_localhost_for_deprecation
      if defined?(@original_ignore_localhost)
        VCR.http_stubbing_adapter.ignore_localhost = @original_ignore_localhost
      end
    end
  end

  class Config
    def self.cache_dir(*args)
      warn "WARNING: VCR::Config.cache_dir is deprecated.  Instead, use: VCR::Config.cassette_library_dir."
      cassette_library_dir(*args)
    end

    def self.cache_dir=(value)
      warn "WARNING: VCR::Config.cache_dir= is deprecated.  Instead, use: VCR::Config.cassette_library_dir=."
      self.cassette_library_dir = value
    end

    def self.default_cassette_record_mode=(value)
      warn %Q{WARNING: #default_cassette_record_mode is deprecated.  Instead, use: "default_cassette_options = { :record => :#{value.to_s} }"}
      default_cassette_options.merge!(:record => value)
    end
  end
end
