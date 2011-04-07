require 'spec_helper'

describe VCR::Cassette do
  describe '#file' do
    it 'combines the cassette_library_dir with the cassette name' do
      cassette = VCR::Cassette.new('the_file')
      cassette.file.should == File.join(VCR::Config.cassette_library_dir, 'the_file.yml')
    end

    it 'strips out disallowed characters so that it is a valid file name with no spaces' do
      cassette = VCR::Cassette.new("\nthis \t!  is-the_13212_file name")
      cassette.file.should =~ /#{Regexp.escape('_this_is-the_13212_file_name.yml')}$/
    end

    it 'keeps any path separators' do
      cassette = VCR::Cassette.new("dir/file_name")
      cassette.file.should =~ /#{Regexp.escape('dir/file_name.yml')}$/
    end

    it 'returns nil if the cassette_library_dir is not set' do
      VCR::Config.cassette_library_dir = nil
      cassette = VCR::Cassette.new('the_file')
      cassette.file.should be_nil
    end
  end

  describe '#record_http_interaction' do
    it 'adds the interaction to #new_recorded_interactions' do
      cassette = VCR::Cassette.new(:test_cassette)
      cassette.new_recorded_interactions.should == []
      cassette.record_http_interaction(:the_interaction)
      cassette.new_recorded_interactions.should == [:the_interaction]
    end
  end

  describe '#match_requests_on' do
    before(:each) { VCR::Config.default_cassette_options.merge!(:match_requests_on => [:uri, :method]) }

    it "returns the provided options" do
      c = VCR::Cassette.new('example', :match_requests_on => [:uri])
      c.match_requests_on.should == [:uri]
    end

    it "returns a the default #match_requests_on when it has not been specified for the cassette" do
      c = VCR::Cassette.new('example')
      c.match_requests_on.should == [:uri, :method]
    end
  end

  describe '.new' do
    it 'raises an error with a helpful message when loading an old unsupported cassette' do
      VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}"
      expect { VCR::Cassette.new('0_3_1_cassette') }.to raise_error(/The VCR cassette 0_3_1_cassette.yml uses an old format that is now deprecated/)
    end

    it "raises an error if given an invalid record mode" do
      expect { VCR::Cassette.new(:test, :record => :not_a_record_mode) }.to raise_error(ArgumentError)
    end

    it 'raises an error if given invalid options' do
      expect {
        VCR::Cassette.new(:test, :invalid => :option)
      }.to raise_error(ArgumentError)
    end

    it 'does not raise an error in the case of an empty file' do
      VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
      VCR::Cassette.new('empty', :record => :none).recorded_interactions.should == []
    end

    it 'creates a stubs checkpoint on the http_stubbing_adapter' do
      cassette = nil

      VCR.http_stubbing_adapter.should_receive(:create_stubs_checkpoint) do |c|
        cassette = c
      end

      VCR::Cassette.new('example').should equal(cassette)
    end

    describe "reading the file from disk" do
      before(:each) do
        File.stub(:size? => true)
      end

      it 'reads the appropriate file from disk using a VCR::Cassette::Reader' do
        VCR::Cassette::Reader.should_receive(:new).with(
          "#{VCR::Config.cassette_library_dir}/foo.yml", anything
        ).and_return(mock('reader', :read => VCR::YAML.dump([])))

        VCR::Cassette.new('foo', :record => :new_episodes)
      end

      [true, false, nil, { }].each do |erb|
        it "passes #{erb.inspect} to the VCR::Cassette::Reader when given as the :erb option" do
          # test that it overrides the default
          VCR::Config.default_cassette_options = { :erb => true }

          VCR::Cassette::Reader.should_receive(:new).with(
            anything, erb
          ).and_return(mock('reader', :read => VCR::YAML.dump([])))

          VCR::Cassette.new('foo', :record => :new_episodes, :erb => erb)
        end

        it "passes #{erb.inspect} to the VCR::Cassette::Reader when it is the default :erb option and none is given" do
          VCR::Config.default_cassette_options = { :erb => erb }

          VCR::Cassette::Reader.should_receive(:new).with(
            anything, erb
          ).and_return(mock('reader', :read => VCR::YAML.dump([])))

          VCR::Cassette.new('foo', :record => :new_episodes)
        end
      end
    end

    VCR::Cassette::VALID_RECORD_MODES.each do |record_mode|
      http_connections_allowed = (record_mode != :none)
      stub_requests = (record_mode != :all)

      context "when VCR::Config.default_cassette_options[:record] is :#{record_mode}" do
        before(:each) { VCR::Config.default_cassette_options = { :record => record_mode } }

        it "defaults the record mode to #{record_mode} when VCR::Config.default_cassette_options[:record] is #{record_mode}" do
          cassette = VCR::Cassette.new(:test)
          cassette.record_mode.should == record_mode
        end
      end

      context "when :#{record_mode} is passed as the record option" do
        if record_mode == :none
          it 'does not allow http connections when there is an existing cassette file with recorded interactions' do
            VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
            VCR.http_stubbing_adapter.should_receive(:http_connections_allowed=).with(false)
            c = VCR::Cassette.new('example', :record => :once)
            File.should exist(c.file)
            File.size?(c.file).should be_true
          end

          it 'allows http connections when there is an empty existing cassette file' do
            VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
            VCR.http_stubbing_adapter.should_receive(:http_connections_allowed=).with(true)
            c = VCR::Cassette.new('empty', :record => :once)
            File.should exist(c.file)
            File.size?(c.file).should be_false
          end

          it 'allows http connections when there is not an existing cassette file' do
            VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
            VCR.http_stubbing_adapter.should_receive(:http_connections_allowed=).with(true)
            c = VCR::Cassette.new('non_existant_file', :record => :once)
            File.should_not exist(c.file)
          end
        end

        unless record_mode == :all
          let(:interaction_1) { VCR::HTTPInteraction.new(VCR::Request.new(:get, 'http://example.com/'), VCR::Response.new(VCR::ResponseStatus.new)) }
          let(:interaction_2) { VCR::HTTPInteraction.new(VCR::Request.new(:get, 'http://example.com/'), VCR::Response.new(VCR::ResponseStatus.new)) }
          let(:interactions)  { [interaction_1, interaction_2] }
          before(:each) { VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec" }

          it 'updates the content_length headers when given :update_content_length_header => true' do
            VCR::YAML.stub(:load => interactions)
            interaction_1.response.should_receive(:update_content_length_header)
            interaction_2.response.should_receive(:update_content_length_header)

            VCR::Cassette.new('example', :record => record_mode, :update_content_length_header => true)
          end

          [nil, false].each do |val|
            it "does not update the content_lenth headers when given :update_content_length_header => #{val.inspect}" do
              VCR::YAML.stub(:load => interactions)
              interaction_1.response.should_not_receive(:update_content_length_header)
              interaction_2.response.should_not_receive(:update_content_length_header)

              VCR::Cassette.new('example', :record => record_mode, :update_content_length_header => val)
            end
          end

          context "and re_record_interval is 7.days" do
            let(:file_name) { File.join(VCR::Config.cassette_library_dir, "cassette_name.yml") }
            subject { VCR::Cassette.new(File.basename(file_name).gsub('.yml', ''), :record => record_mode, :re_record_interval => 7.days) }

            context 'when the cassette file does not exist' do
              before(:each) { File.stub(:exist?).with(file_name).and_return(false) }

              it "has :#{record_mode} for the record mode" do
                subject.record_mode.should == record_mode
              end
            end

            context 'when the cassette file does exist' do
              before(:each) do
                File.stub(:exist?).with(file_name).and_return(true)
                File.stub(:read).with(file_name).and_return(VCR::YAML.dump([]))
              end

              context 'and the file was last modified less than 7 days ago' do
                before(:each) { File.stub(:stat).with(file_name).and_return(stub(:mtime => Time.now - 7.days + 60)) }

                it "has :#{record_mode} for the record mode" do
                  subject.record_mode.should == record_mode
                end
              end

              context 'and the file was last modified more than 7 days ago' do
                before(:each) { File.stub(:stat).with(file_name).and_return(stub(:mtime => Time.now - 7.days - 60)) }

                it "has :all for the record mode when there is an internet connection available" do
                  VCR::InternetConnection.stub(:available? => true)
                  subject.record_mode.should == :all
                end

                it "has :#{record_mode} for the record mode when there is no internet connection available" do
                  VCR::InternetConnection.stub(:available? => false)
                  subject.record_mode.should == record_mode
                end
              end
            end
          end
        end

        it "sets http_connections_allowed to #{http_connections_allowed} on the http stubbing adapter" do
          VCR.http_stubbing_adapter.should_receive(:http_connections_allowed=).with(http_connections_allowed)
          VCR::Cassette.new(:name, :record => record_mode)
        end

        it 'does not load ignored interactions' do
          VCR::Config.stub(:uri_should_be_ignored?) do |uri|
            uri.to_s !~ /example\.com/
          end

          VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
          cassette = VCR::Cassette.new('with_localhost_requests', :record => record_mode)
          cassette.recorded_interactions.map { |i| URI.parse(i.uri).host }.should == %w[example.com]
        end

        it "loads the recorded interactions from the library yml file" do
          VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
          cassette = VCR::Cassette.new('example', :record => record_mode)

          cassette.should have(3).recorded_interactions

          i1, i2, i3 = *cassette.recorded_interactions

          i1.request.method.should == :get
          i1.request.uri.should == 'http://example.com:80/'
          i1.response.body.should =~ /You have reached this web page by typing.+example\.com/

          i2.request.method.should == :get
          i2.request.uri.should == 'http://example.com:80/foo'
          i2.response.body.should =~ /foo was not found on this server/

          i3.request.method.should == :get
          i3.request.uri.should == 'http://example.com:80/'
          i3.response.body.should =~ /Another example\.com response/
        end

        if stub_requests
          it 'invokes the appropriately tagged before_playback hooks' do
            VCR::Config.should_receive(:invoke_hook).with(
              :before_playback,
              :foo,
              an_instance_of(VCR::HTTPInteraction),
              an_instance_of(VCR::Cassette)
            ).exactly(3).times

            cassette = VCR::Cassette.new('example', :record => record_mode, :tag => :foo)
            cassette.should have(3).recorded_interactions
          end

          it 'does not playback any interactions that are ignored in a before_playback hook' do
            VCR.config do |c|
              c.before_playback { |i| i.ignore! if i.request.uri =~ /foo/ }
            end

            VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
            cassette = VCR::Cassette.new('example', :record => record_mode)
            cassette.should have(2).recorded_interactions
          end

          it "stubs the recorded requests with the http stubbing adapter" do
            VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
            VCR.http_stubbing_adapter.should_receive(:stub_requests).with([an_instance_of(VCR::HTTPInteraction)]*3, anything)
            cassette = VCR::Cassette.new('example', :record => record_mode)
          end

          it "passes the :match_request_on option to #stub_requests" do
            VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
            VCR.http_stubbing_adapter.should_receive(:stub_requests).with(anything, [:body, :headers])
            cassette = VCR::Cassette.new('example', :record => record_mode, :match_requests_on => [:body, :headers])
          end
        else
          it "does not stub the recorded requests with the http stubbing adapter" do
            VCR::Config.cassette_library_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
            VCR.http_stubbing_adapter.should_not_receive(:stub_requests)
            cassette = VCR::Cassette.new('example', :record => record_mode)
          end
        end
      end
    end
  end

  describe '#eject' do
    [true, false].each do |orig_http_connections_allowed|
      it "resets #{orig_http_connections_allowed} on the http stubbing adapter if it was originally #{orig_http_connections_allowed}" do
        VCR.http_stubbing_adapter.should_receive(:http_connections_allowed?).and_return(orig_http_connections_allowed)
        cassette = VCR::Cassette.new(:name)
        VCR.http_stubbing_adapter.should_receive(:http_connections_allowed=).with(orig_http_connections_allowed)
        cassette.eject
      end
    end

    it "writes the recorded interactions to disk as yaml" do
      recorded_interactions = [
        VCR::HTTPInteraction.new(:req_sig_1, :response_1),
        VCR::HTTPInteraction.new(:req_sig_2, :response_2),
        VCR::HTTPInteraction.new(:req_sig_3, :response_3)
      ]

      cassette = VCR::Cassette.new(:eject_test)
      cassette.stub!(:new_recorded_interactions).and_return(recorded_interactions)

      expect { cassette.eject }.to change { File.exist?(cassette.file) }.from(false).to(true)
      saved_recorded_interactions = VCR::YAML.load_file(cassette.file)
      saved_recorded_interactions.should == recorded_interactions
    end

    it 'invokes the appropriately tagged before_record hooks' do
      interactions = [
        VCR::HTTPInteraction.new(:req_sig_1, :response_1),
        VCR::HTTPInteraction.new(:req_sig_2, :response_2)
      ]

      cassette = VCR::Cassette.new('example', :tag => :foo)
      cassette.stub!(:new_recorded_interactions).and_return(interactions)

      interactions.each do |i|
        VCR::Config.should_receive(:invoke_hook).with(
          :before_record,
          :foo,
          i,
          cassette
        ).ordered
      end

      cassette.eject
    end

    it 'does not record interactions that have been ignored' do
      interaction_1 = VCR::HTTPInteraction.new(:request_1, :response_1)
      interaction_2 = VCR::HTTPInteraction.new(:request_2, :response_2)

      interaction_1.ignore!

      cassette = VCR::Cassette.new('test_cassette')
      cassette.stub!(:new_recorded_interactions).and_return([interaction_1, interaction_2])
      cassette.eject

      saved_recorded_interactions = VCR::YAML.load_file(cassette.file)
      saved_recorded_interactions.should == [interaction_2]
    end

    it 'does not write the cassette to disk if all interactions have been ignored' do
      interaction_1 = VCR::HTTPInteraction.new(:request_1, :response_1)
      interaction_1.ignore!

      cassette = VCR::Cassette.new('test_cassette')
      cassette.stub!(:new_recorded_interactions).and_return([interaction_1])
      cassette.eject

      File.should_not exist(cassette.file)
    end

    it "writes the recorded interactions to a subdirectory if the cassette name includes a directory" do
      recorded_interactions = [VCR::HTTPInteraction.new(:the_request, :the_response)]
      cassette = VCR::Cassette.new('subdirectory/test_cassette')
      cassette.stub!(:new_recorded_interactions).and_return(recorded_interactions)

      expect { cassette.eject }.to change { File.exist?(cassette.file) }.from(false).to(true)
      saved_recorded_interactions = VCR::YAML.load_file(cassette.file)
      saved_recorded_interactions.should == recorded_interactions
    end

    [:all, :none, :new_episodes].each do |record_mode|
      context "for a :record => :#{record_mode} cassette with previously recorded interactions" do
        subject { VCR::Cassette.new('example', :record => record_mode, :match_requests_on => [:uri]) }

        before(:each) do
          base_dir = "#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/cassette_spec"
          FileUtils.cp(base_dir + "/example.yml", VCR::Config.cassette_library_dir + "/example.yml")
        end

        it "restore the stubs checkpoint on the http stubbing adapter" do
          VCR.http_stubbing_adapter.should_receive(:restore_stubs_checkpoint).with(subject)
          subject.eject
        end

        it "does not re-write to disk the previously recorded interactions if there are no new ones" do
          yaml_file = subject.file
          File.should_not_receive(:open).with(subject.file, 'w')
          expect { subject.eject }.to_not change { File.mtime(yaml_file) }
        end

        context 'when some new interactions have been recorded' do
          let(:new_interaction_1) { VCR::HTTPInteraction.new(VCR::Request.new, :response_1) }
          let(:new_interaction_2) { VCR::HTTPInteraction.new(VCR::Request.new, :response_2) }
          let(:new_interaction_3) { VCR::HTTPInteraction.new(VCR::Request.new, :response_3) }

          let(:old_interaction_1) { subject.recorded_interactions[0] }
          let(:old_interaction_2) { subject.recorded_interactions[1] }
          let(:old_interaction_3) { subject.recorded_interactions[2] }

          let(:saved_recorded_interactions) { VCR::YAML.load_file(subject.file) }

          def stub_matcher_for(interaction, matcher)
            # There are issues with serializing an object stubbed w/ rspec-mocks using Psych.
            # So we manually define the method here.
            class << interaction.request; self; end.class_eval do
              define_method(:matcher) { |*a| matcher }
            end
          end

          before(:each) do
            stub_matcher_for(old_interaction_1, :matcher_c)
            stub_matcher_for(old_interaction_2, :matcher_d)
            stub_matcher_for(old_interaction_3, :matcher_c)

            stub_matcher_for(new_interaction_1, :matcher_a)
            stub_matcher_for(new_interaction_2, :matcher_b)
            stub_matcher_for(new_interaction_3, :matcher_c)

            [new_interaction_1, new_interaction_2, new_interaction_3].each do |i|
              subject.record_http_interaction(i)
            end
          end

          if record_mode == :all
            it 'removes the old interactions that match new requests, and saves the new interactions follow the old ones' do
              subject.eject

              saved_recorded_interactions.should == [
                old_interaction_2,
                new_interaction_1,
                new_interaction_2,
                new_interaction_3
              ]
            end

            it "matches old requests to new ones using the cassette's match attributes" do
              pending("Need to fix this to work with Psych", :if => defined?(::Psych)) do
                [
                  old_interaction_1, old_interaction_2, old_interaction_3,
                  new_interaction_1, new_interaction_2, new_interaction_3
                ].each do |i|
                  i.request.should_receive(:matcher).with(subject.match_requests_on).and_return(:the_matcher)
                end

                subject.eject
              end
            end
          else
            it 'saves the old interactions followed by the new ones to disk' do
              subject.eject

              saved_recorded_interactions.should == [
                old_interaction_1,
                old_interaction_2,
                old_interaction_3,
                new_interaction_1,
                new_interaction_2,
                new_interaction_3
              ]
            end
          end
        end
      end
    end
  end
end
