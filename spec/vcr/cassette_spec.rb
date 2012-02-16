require 'spec_helper'

describe VCR::Cassette do
  def http_interaction
    request = VCR::Request.new(:get)
    response = VCR::Response.new
    response.status = VCR::ResponseStatus.new
    VCR::HTTPInteraction.new(request, response).tap { |i| yield i if block_given? }
  end

  describe '#file' do
    it 'combines the cassette_library_dir with the cassette name' do
      cassette = VCR::Cassette.new('the_file')
      cassette.file.should eq(File.join(VCR.configuration.cassette_library_dir, 'the_file.yml'))
    end

    it 'uses the file extension from the serializer' do
      VCR.cassette_serializers[:custom] = stub(:file_extension => "custom")
      cassette = VCR::Cassette.new('the_file', :serialize_with => :custom)
      cassette.file.should =~ /\.custom$/
    end

    it 'strips out disallowed characters so that it is a valid file name with no spaces' do
      cassette = VCR::Cassette.new("\nthis \t!  is-the_13212_file name")
      cassette.file.should =~ /#{Regexp.escape('_this_is-the_13212_file_name.yml')}$/
    end

    it 'keeps any path separators' do
      cassette = VCR::Cassette.new("dir/file_name")
      cassette.file.should =~ /#{Regexp.escape('dir/file_name.yml')}$/
    end

    VCR::Cassette::VALID_RECORD_MODES.each do |mode|
      it "returns nil if the cassette_library_dir is not set (when the record mode is :#{mode})" do
        VCR.configuration.cassette_library_dir = nil
        cassette = VCR::Cassette.new('the_file', :record => mode)
        cassette.file.should be_nil
      end
    end
  end

  describe '#tags' do
    it 'returns a blank array if no tag has been set' do
      VCR::Cassette.new("name").tags.should eq([])
    end

    it 'converts a single :tag to an array' do
      VCR::Cassette.new("name", :tag => :foo).tags.should eq([:foo])
    end

    it 'accepts an array as the :tags option' do
      VCR::Cassette.new("name", :tags => [:foo]).tags.should eq([:foo])
    end
  end

  describe '#record_http_interaction' do
    let(:the_interaction) { stub(:request => stub(:method => :get).as_null_object).as_null_object }

    it 'adds the interaction to #new_recorded_interactions' do
      cassette = VCR::Cassette.new(:test_cassette)
      cassette.new_recorded_interactions.should eq([])
      cassette.record_http_interaction(the_interaction)
      cassette.new_recorded_interactions.should eq([the_interaction])
    end
  end

  describe "#serializable_hash" do
    subject { VCR::Cassette.new("foo") }
    let(:interaction_1) { http_interaction { |i| i.request.body = 'req body 1'; i.response.body = 'res body 1' } }
    let(:interaction_2) { http_interaction { |i| i.request.body = 'req body 2'; i.response.body = 'res body 2' } }
    let(:interactions)  { [interaction_1, interaction_2] }

    before(:each) do
      interactions.each do |i|
        subject.record_http_interaction(i)
      end
    end

    let(:metadata) { subject.serializable_hash.reject { |k,v| k == "http_interactions" } }

    it 'includes the hash form of all recorded interactions' do
      interaction_1.stub(:to_hash => { "i" => 1, 'body' => '' })
      interaction_2.stub(:to_hash => { "i" => 2, 'body' => '' })
      subject.serializable_hash.should include('http_interactions' => [{ "i" => 1, 'body' => '' }, { "i" => 2, 'body' => '' }])
    end

    it 'includes additional metadata about the cassette' do
      metadata.should eq("recorded_with" => "VCR #{VCR.version}")
    end
  end

  describe "#recording?" do
    [:all, :new_episodes].each do |mode|
      it "returns true when the record mode is :#{mode}" do
        cassette = VCR::Cassette.new("foo", :record => mode)
        cassette.should be_recording
      end
    end

    it "returns false when the record mode is :none" do
      cassette = VCR::Cassette.new("foo", :record => :none)
      cassette.should_not be_recording
    end

    context 'when the record mode is :once' do
      before(:each) do
        VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
      end

      it 'returns false when there is an existing cassette file with content' do
        cassette = VCR::Cassette.new("example", :record => :once)
        File.should exist(cassette.file)
        File.size?(cassette.file).should be_true
        cassette.should_not be_recording
      end

      it 'returns true when there is an empty existing cassette file' do
        cassette = VCR::Cassette.new("empty", :record => :once)
        File.should exist(cassette.file)
        File.size?(cassette.file).should be_false
        cassette.should be_recording
      end

      it 'returns true when there is no existing cassette file' do
        cassette = VCR::Cassette.new("non_existant_file", :record => :once)
        File.should_not exist(cassette.file)
        cassette.should be_recording
      end
    end
  end

  describe '#match_requests_on' do
    before(:each) { VCR.configuration.default_cassette_options.merge!(:match_requests_on => [:uri, :method]) }

    it "returns the provided options" do
      c = VCR::Cassette.new('example', :match_requests_on => [:uri])
      c.match_requests_on.should eq([:uri])
    end

    it "returns a the default #match_requests_on when it has not been specified for the cassette" do
      c = VCR::Cassette.new('example')
      c.match_requests_on.should eq([:uri, :method])
    end
  end

  describe "reading the file from disk" do
    before(:each) do
      File.stub(:size? => true)
    end

    let(:empty_cassette_yaml) { YAML.dump("http_interactions" => []) }

    it 'reads the appropriate file from disk using a VCR::Cassette::Reader' do
      VCR::Cassette::Reader.should_receive(:new).with(
        "#{VCR.configuration.cassette_library_dir}/foo.yml", anything
      ).and_return(mock('reader', :read => empty_cassette_yaml))

      VCR::Cassette.new('foo', :record => :new_episodes).http_interactions
    end

    [true, false, nil, { }].each do |erb|
      it "passes #{erb.inspect} to the VCR::Cassette::Reader when given as the :erb option" do
        # test that it overrides the default
        VCR.configuration.default_cassette_options = { :erb => true }

        VCR::Cassette::Reader.should_receive(:new).with(
          anything, erb
        ).and_return(mock('reader', :read => empty_cassette_yaml))

        VCR::Cassette.new('foo', :record => :new_episodes, :erb => erb).http_interactions
      end

      it "passes #{erb.inspect} to the VCR::Cassette::Reader when it is the default :erb option and none is given" do
        VCR.configuration.default_cassette_options = { :erb => erb }

        VCR::Cassette::Reader.should_receive(:new).with(
          anything, erb
        ).and_return(mock('reader', :read => empty_cassette_yaml))

        VCR::Cassette.new('foo', :record => :new_episodes).http_interactions
      end
    end

    it 'raises a friendly error when the cassette file is in the old VCR 1.x format' do
      VCR.configuration.cassette_library_dir = 'spec/fixtures/cassette_spec'
      expect {
        VCR::Cassette.new('1_x_cassette').http_interactions
      }.to raise_error(VCR::Errors::InvalidCassetteFormatError)
    end
  end

  describe '.new' do
    it "raises an error if given an invalid record mode" do
      expect { VCR::Cassette.new(:test, :record => :not_a_record_mode) }.to raise_error(ArgumentError)
    end

    it 'raises an error if given invalid options' do
      expect {
        VCR::Cassette.new(:test, :invalid => :option)
      }.to raise_error(ArgumentError)
    end

    it 'does not raise an error in the case of an empty file' do
      VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
      VCR::Cassette.new('empty', :record => :none).send(:previously_recorded_interactions).should eq([])
    end

    VCR::Cassette::VALID_RECORD_MODES.each do |record_mode|
      stub_requests = (record_mode != :all)

      context "when VCR.configuration.default_cassette_options[:record] is :#{record_mode}" do
        before(:each) { VCR.configuration.default_cassette_options = { :record => record_mode } }

        it "defaults the record mode to #{record_mode} when VCR.configuration.default_cassette_options[:record] is #{record_mode}" do
          cassette = VCR::Cassette.new(:test)
          cassette.record_mode.should eq(record_mode)
        end
      end

      context "when :#{record_mode} is passed as the record option" do
        def stub_old_interactions(interactions)
          hashes = interactions.map(&:to_hash)
          VCR.cassette_serializers[:yaml].stub(:deserialize => { 'http_interactions' => hashes })
          VCR::HTTPInteraction.stub(:from_hash) do |hash|
            interactions[hashes.index(hash)]
          end
        end

        unless record_mode == :all
          let(:interaction_1) { http_interaction { |i| i.request.uri = 'http://example.com/foo' } }
          let(:interaction_2) { http_interaction { |i| i.request.uri = 'http://example.com/bar' } }
          let(:interactions)  { [interaction_1, interaction_2] }
          before(:each) { VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec" }

          it 'updates the content_length headers when given :update_content_length_header => true' do
            stub_old_interactions(interactions)
            interaction_1.response.should_receive(:update_content_length_header)
            interaction_2.response.should_receive(:update_content_length_header)

            VCR::Cassette.new('example', :record => record_mode, :update_content_length_header => true).http_interactions
          end

          [nil, false].each do |val|
            it "does not update the content_lenth headers when given :update_content_length_header => #{val.inspect}" do
              stub_old_interactions(interactions)
              interaction_1.response.should_not_receive(:update_content_length_header)
              interaction_2.response.should_not_receive(:update_content_length_header)

              VCR::Cassette.new('example', :record => record_mode, :update_content_length_header => val).http_interactions
            end
          end

          context "and re_record_interval is 7.days" do
            let(:file_name) { File.join(VCR.configuration.cassette_library_dir, "cassette_name.yml") }
            subject { VCR::Cassette.new(File.basename(file_name).gsub('.yml', ''), :record => record_mode, :re_record_interval => 7.days) }

            context 'when the cassette file does not exist' do
              before(:each) { File.stub(:exist?).with(file_name).and_return(false) }

              it "has :#{record_mode} for the record mode" do
                subject.record_mode.should eq(record_mode)
              end
            end

            context 'when the cassette file does exist' do
              before(:each) do
                interactions = timestamps.map do |ts|
                  http_interaction { |i| i.recorded_at = ts }.to_hash
                end
                yaml = YAML.dump("http_interactions" => interactions)

                File.stub(:exist?).with(file_name).and_return(true)
                File.stub(:size?).with(file_name).and_return(true)
                File.stub(:read).with(file_name).and_return(yaml)
              end

              context 'and the earliest recorded interaction was recorded less than 7 days ago' do
                let(:timestamps) do [
                  Time.now - 6.days + 60,
                  Time.now - 7.days + 60,
                  Time.now - 5.days + 60
                ] end

                it "has :#{record_mode} for the record mode" do
                  subject.record_mode.should eq(record_mode)
                end
              end

              context 'and the earliest recorded interaction was recorded more than 7 days ago' do
                let(:timestamps) do [
                  Time.now - 6.days - 60,
                  Time.now - 7.days - 60,
                  Time.now - 5.days - 60
                ] end

                it "has :all for the record mode when there is an internet connection available" do
                  VCR::InternetConnection.stub(:available? => true)
                  subject.record_mode.should eq(:all)
                end

                it "has :#{record_mode} for the record mode when there is no internet connection available" do
                  VCR::InternetConnection.stub(:available? => false)
                  subject.record_mode.should eq(record_mode)
                end
              end
            end
          end
        end

        it 'does not load ignored interactions' do
          VCR.request_ignorer.stub(:ignore?) do |request|
            request.uri !~ /example\.com/
          end

          VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
          cassette = VCR::Cassette.new('with_localhost_requests', :record => record_mode)
          cassette.send(:previously_recorded_interactions).map { |i| URI.parse(i.request.uri).host }.should eq(%w[example.com])
        end

        it "loads the recorded interactions from the library yml file" do
          VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
          cassette = VCR::Cassette.new('example', :record => record_mode)

          cassette.should have(3).previously_recorded_interactions

          i1, i2, i3 = *cassette.send(:previously_recorded_interactions)

          i1.request.method.should eq(:get)
          i1.request.uri.should eq('http://example.com/')
          i1.response.body.should =~ /You have reached this web page by typing.+example\.com/

          i2.request.method.should eq(:get)
          i2.request.uri.should eq('http://example.com/foo')
          i2.response.body.should =~ /foo was not found on this server/

          i3.request.method.should eq(:get)
          i3.request.uri.should eq('http://example.com/')
          i3.response.body.should =~ /Another example\.com response/
        end

        [true, false].each do |value|
          it "instantiates the http_interactions with allow_playback_repeats = #{value} if given :allow_playback_repeats => #{value}" do
            VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
            cassette = VCR::Cassette.new('example', :record => record_mode, :allow_playback_repeats => value)
            cassette.http_interactions.allow_playback_repeats.should eq(value)
          end
        end

        it "instantiates the http_interactions with parent_list set to a null list if given :exclusive => true" do
          VCR.stub(:http_interactions => stub)
          VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
          cassette = VCR::Cassette.new('example', :record => record_mode, :exclusive => true)
          cassette.http_interactions.parent_list.should be(VCR::Cassette::HTTPInteractionList::NullList)
        end

        it "instantiates the http_interactions with parent_list set to VCR.http_interactions if given :exclusive => false" do
          VCR.stub(:http_interactions => stub)
          VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
          cassette = VCR::Cassette.new('example', :record => record_mode, :exclusive => false)
          cassette.http_interactions.parent_list.should be(VCR.http_interactions)
        end

        if stub_requests
          it 'invokes the before_playback hooks' do
            VCR.configuration.should_receive(:invoke_hook).with(
              :before_playback,
              an_instance_of(VCR::HTTPInteraction::HookAware),
              an_instance_of(VCR::Cassette)
            ).exactly(3).times

            cassette = VCR::Cassette.new('example', :record => record_mode)
            cassette.should have(3).previously_recorded_interactions
          end

          it 'does not playback any interactions that are ignored in a before_playback hook' do
            VCR.configure do |c|
              c.before_playback { |i| i.ignore! if i.request.uri =~ /foo/ }
            end

            VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
            cassette = VCR::Cassette.new('example', :record => record_mode)
            cassette.should have(2).previously_recorded_interactions
          end

          it 'instantiates the http_interactions with the loaded interactions and the request matchers' do
            VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
            cassette = VCR::Cassette.new('example', :record => record_mode, :match_requests_on => [:body, :headers])
            cassette.http_interactions.interactions.should have(3).interactions
            cassette.http_interactions.request_matchers.should eq([:body, :headers])
          end
        else
          it 'instantiates the http_interactions with the no interactions and the request matchers' do
            VCR.configuration.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
            cassette = VCR::Cassette.new('example', :record => record_mode, :match_requests_on => [:body, :headers])
            cassette.http_interactions.interactions.should have(0).interactions
            cassette.http_interactions.request_matchers.should eq([:body, :headers])
          end
        end
      end
    end
  end

  describe '#eject' do
    it "writes the serializable_hash to disk as yaml" do
      cassette = VCR::Cassette.new(:eject_test)
      cassette.record_http_interaction http_interaction # so it has one
      cassette.should respond_to(:serializable_hash)
      cassette.stub(:serializable_hash => { "http_interactions" => [1, 3, 5] })

      expect { cassette.eject }.to change { File.exist?(cassette.file) }.from(false).to(true)
      saved_stuff = YAML.load_file(cassette.file)
      saved_stuff.should eq("http_interactions" => [1, 3, 5])
    end

    it 'invokes the appropriately tagged before_record hooks' do
      interactions = [
        http_interaction { |i| i.request.uri = 'http://foo.com/'; i.response.body = 'res 1' },
        http_interaction { |i| i.request.uri = 'http://bar.com/'; i.response.body = 'res 2' }
      ]

      cassette = VCR::Cassette.new('example', :tag => :foo)
      cassette.stub!(:new_recorded_interactions).and_return(interactions)

      VCR.configuration.stub(:invoke_hook).and_return([false])

      interactions.each do |i|
        VCR.configuration.should_receive(:invoke_hook).with(
          :before_record,
          an_instance_of(VCR::HTTPInteraction::HookAware),
          cassette
        ).ordered
      end

      cassette.eject
    end

    it 'does not record interactions that have been ignored' do
      interaction_1 = http_interaction { |i| i.request.uri = 'http://foo.com/'; i.response.body = 'res 1' }
      interaction_2 = http_interaction { |i| i.request.uri = 'http://bar.com/'; i.response.body = 'res 2' }

      hook_aware_interaction_1 = interaction_1.hook_aware
      interaction_1.stub(:hook_aware => hook_aware_interaction_1)
      hook_aware_interaction_1.ignore!

      cassette = VCR::Cassette.new('test_cassette')
      cassette.stub!(:new_recorded_interactions).and_return([interaction_1, interaction_2])
      cassette.eject

      saved_recorded_interactions = ::YAML.load_file(cassette.file)
      saved_recorded_interactions["http_interactions"].should eq([interaction_2.to_hash])
    end

    it 'does not write the cassette to disk if all interactions have been ignored' do
      interaction_1 = http_interaction { |i| i.request.uri = 'http://foo.com/'; i.response.body = 'res 1' }

      hook_aware_interaction_1 = interaction_1.hook_aware
      interaction_1.stub(:hook_aware => hook_aware_interaction_1)
      hook_aware_interaction_1.ignore!

      cassette = VCR::Cassette.new('test_cassette')
      cassette.stub!(:new_recorded_interactions).and_return([interaction_1])
      cassette.eject

      File.should_not exist(cassette.file)
    end

    it "writes the recorded interactions to a subdirectory if the cassette name includes a directory" do
      recorded_interactions = [http_interaction { |i| i.response.body = "subdirectory response" }]
      cassette = VCR::Cassette.new('subdirectory/test_cassette')
      cassette.stub(:new_recorded_interactions => recorded_interactions)

      expect { cassette.eject }.to change { File.exist?(cassette.file) }.from(false).to(true)
      saved_recorded_interactions = YAML.load_file(cassette.file)
      saved_recorded_interactions["http_interactions"].should eq(recorded_interactions.map(&:to_hash))
    end

    [:all, :none, :new_episodes].each do |record_mode|
      context "for a :record => :#{record_mode} cassette with previously recorded interactions" do
        subject { VCR::Cassette.new('example', :record => record_mode, :match_requests_on => [:uri]) }

        before(:each) do
          base_dir = "#{VCR::SPEC_ROOT}/fixtures/cassette_spec"
          FileUtils.cp(base_dir + "/example.yml", VCR.configuration.cassette_library_dir + "/example.yml")
        end

        it "does not re-write to disk the previously recorded interactions if there are no new ones" do
          yaml_file = subject.file
          File.should_not_receive(:open).with(subject.file, 'w')
          expect { subject.eject }.to_not change { File.mtime(yaml_file) }
        end

        context 'when some new interactions have been recorded' do
          def interaction(response_body, request_attributes)
            http_interaction do |interaction|
              interaction.response.body = response_body
              request_attributes.each do |key, value|
                interaction.request.send("#{key}=", value)
              end
            end
          end

          let(:interaction_foo_1) { interaction("foo 1", :uri => 'http://foo.com/') }
          let(:interaction_foo_2) { interaction("foo 2", :uri => 'http://foo.com/') }
          let(:interaction_bar)   { interaction("bar", :uri => 'http://bar.com/') }

          let(:saved_recorded_interactions) { YAML.load_file(subject.file)['http_interactions'].map { |h| VCR::HTTPInteraction.from_hash(h) } }
          let(:now) { Time.utc(2011, 6, 11, 12, 30) }

          before(:each) do
            Time.stub(:now => now)
            subject.stub(:previously_recorded_interactions => [interaction_foo_1])
            subject.record_http_interaction(interaction_foo_2)
            subject.record_http_interaction(interaction_bar)
            subject.eject
          end

          if record_mode == :all
            it 'replaces previously recorded interactions with new ones when the requests match' do
              saved_recorded_interactions.first.should eq(interaction_foo_2)
              saved_recorded_interactions.should_not include(interaction_foo_1)
            end

            it 'appends new recorded interactions that do not match existing ones' do
              saved_recorded_interactions.last.should eq(interaction_bar)
            end
          else
            it 'appends new recorded interactions after existing ones' do
              saved_recorded_interactions.should eq([interaction_foo_1, interaction_foo_2, interaction_bar])
            end
          end
        end
      end
    end
  end
end
