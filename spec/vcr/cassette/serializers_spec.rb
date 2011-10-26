require 'vcr/cassette/serializers'

module VCR
  class Cassette
    describe Serializers do

      shared_examples_for "a serializer" do |name, file_extension, lazily_loaded|
        context "the #{name} serializer" do
          let(:serializer) { subject[name] }

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
            deserialized = serializer.deserialize(serialized)
            deserialized.should eq(hash)
          end
        end
      end

      it_behaves_like "a serializer", :yaml, "yml", :lazily_loaded

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
    end
  end
end

