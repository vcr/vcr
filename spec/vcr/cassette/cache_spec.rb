require 'vcr/cassette/cache'

module VCR
  class Cassette
    describe Cache do
      describe "#[]" do
        let(:content)   { "the file content" }
        let(:file_name) { "file.yml" }

        it 'only reads the file once' do
          File.stub(:exist?).with(file_name).and_return(true)
          File.should_receive(:read).with(file_name).once.and_return(content)
          subject[file_name].should eq(content)
          subject[file_name].should eq(content)
          subject[file_name].should eq(content)
        end
      end

      describe "#exists_with_content?" do
        context 'when the file exists with no content' do
          let(:file_name) { "zero_bytes.yml" }

          before(:each) do
            File.stub(:exist?).with(file_name).and_return(true)
            File.stub(:read).with(file_name).and_return("")
          end

          it 'returns false' do
            subject.exists_with_content?(file_name).should be_false
          end

          it 'does not read the file multiple times' do
            File.should_receive(:read).once
            subject.exists_with_content?(file_name)
            subject.exists_with_content?(file_name)
            subject.exists_with_content?(file_name)
          end

          it "does not check for the file's existence multiple times" do
            File.should_receive(:exist?).once
            subject.exists_with_content?(file_name)
            subject.exists_with_content?(file_name)
            subject.exists_with_content?(file_name)
          end
        end

        context 'when the file does not exist' do
          let(:file_name) { "non_existant_file.yml" }

          it 'returns false' do
            subject.exists_with_content?(file_name).should be_false
          end

          it 'does not attempt to read the file' do
            File.should_not_receive(:read)
            subject.exists_with_content?(file_name)
          end

          it "does not check for the file's existence multiple times" do
            File.should_receive(:exist?).once.with(file_name).and_return(false)
            subject.exists_with_content?(file_name)
            subject.exists_with_content?(file_name)
            subject.exists_with_content?(file_name)
          end
        end
      end
    end
  end
end
