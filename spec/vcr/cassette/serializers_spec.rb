require 'vcr/cassette/serializers'
require 'multi_json'
begin
  require 'psych' # ensure psych is loaded for these tests if its available
rescue LoadError
end

module VCR
  class Cassette
    describe Serializers do
      shared_examples_for "encoding error handling" do |name, string, error_class|
        context "the #{name} serializer" do
          it 'appends info about the :preserve_exact_body_bytes option to the error' do
            expect {
              result = serializer.serialize("a" => string)
              serializer.deserialize(result)
            }.to raise_error(error_class, /preserve_exact_body_bytes/)
          end
        end
      end

      shared_examples_for "a serializer" do |name, file_extension, lazily_loaded|
        let(:serializer) { subject[name] }

        context "the #{name} serializer" do
          it 'lazily loads the serializer' do
            serializers = subject.instance_variable_get(:@serializers)
            serializers.should_not have_key(name)
            subject[name].should_not be_nil
            serializers.should have_key(name)
          end if lazily_loaded

          it "returns '#{file_extension}' as the file extension" do
            serializer.file_extension.should eq(file_extension)
          end

          it "can serialize and deserialize a hash" do
            hash = { "a" => 7, "nested" => { "hash" => [1, 2, 3] }}
            serialized = serializer.serialize(hash)
            serialized.should_not eq(hash)
            serialized.should be_a(String)
            deserialized = serializer.deserialize(serialized)
            deserialized.should eq(hash)
          end
        end
      end

      it_behaves_like "a serializer", :yaml,  "yml",  :lazily_loaded do
        it_behaves_like "encoding error handling", :yaml, "\xFA".force_encoding("UTF-8"), ArgumentError do
          before { ::YAML::ENGINE.yamler = 'psych' }
        end #if test_psych_encoding_errors
      end

      it_behaves_like "a serializer", :syck,  "yml",  :lazily_loaded do
        it_behaves_like "encoding error handling", :syck, "\xFA".force_encoding("UTF-8"), ArgumentError
      end

      it_behaves_like "a serializer", :psych, "yml",  :lazily_loaded do
        it_behaves_like "encoding error handling", :psych, "\xFA".force_encoding("UTF-8"), ArgumentError
      end if RUBY_VERSION =~ /1.9/

      it_behaves_like "a serializer", :json,  "json", :lazily_loaded do
        engines = { :yajl => ::MultiJson::DecodeError }

        if RUBY_VERSION =~ /1.9/
          engines[:json_gem] = EncodingError
          engines[:json_pure] = EncodingError
        end

        engines.each do |engine, error|
          context "when MultiJson is configured to use #{engine.inspect}" do
            before { MultiJson.engine = engine }
            it_behaves_like "encoding error handling", :json, "\xFA", error
          end
        end
      end

      context "a custom :ruby serializer" do
        let(:custom_serializer) do
          Object.new.tap do |obj|
            def obj.file_extension
              "rb"
            end

            def obj.serialize(hash)
              hash.inspect
            end

            def obj.deserialize(string)
              eval(string)
            end
          end
        end

        before(:each) do
          subject[:ruby] = custom_serializer
        end

        it_behaves_like "a serializer", :ruby, "rb", false
      end

      describe "#[]=" do
        context 'when there is already a serializer registered for the given name' do
          before(:each) do
            subject[:foo] = :old_serializer
            subject.stub :warn
          end

          it 'overrides the existing serializer' do
            subject[:foo] = :new_serializer
            subject[:foo].should be(:new_serializer)
          end

          it 'warns that there is a name collision' do
            subject.should_receive(:warn).with(
              /WARNING: There is already a VCR cassette serializer registered for :foo\. Overriding it/
            )
            subject[:foo] = :new_serializer
          end
        end
      end

      describe "#[]" do
        it 'raises an error when given an unrecognized serializer name' do
          expect { subject[:foo] }.to raise_error(ArgumentError)
        end

        it 'returns the named serializer' do
          subject[:yaml].should be(VCR::Cassette::Serializers::YAML)
        end
      end

      # see https://gist.github.com/815769
      problematic_syck_string = "1\n \n2"

      describe "psych serializer" do
        it 'serializes things using pysch even if syck is configured as the default YAML engine' do
          ::YAML::ENGINE.yamler = 'syck'
          serialized = subject[:psych].serialize(problematic_syck_string)
          subject[:psych].deserialize(serialized).should eq(problematic_syck_string)
        end if defined?(::Psych)

        it 'raises an error if psych cannot be loaded' do
          expect { subject[:psych] }.to raise_error(LoadError)
        end unless defined?(::Psych)
      end

      describe "syck serializer" do
        it 'forcibly serializes things using syck even if psych is the currently configured YAML engine' do
          ::YAML::ENGINE.yamler = 'psych'
          serialized = subject[:syck].serialize(problematic_syck_string)
          subject[:syck].deserialize(serialized).should_not eq(problematic_syck_string)
        end if defined?(::Psych)
      end
    end
  end
end

