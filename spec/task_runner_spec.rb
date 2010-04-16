require 'spec_helper'
require 'vcr/task_runner'

describe VCR::TaskRunner do
  describe '.migrate_cassettes' do
    temp_dir File.expand_path(File.dirname(__FILE__) + '/fixtures/task_runner')

    let(:file_name)      { '0.3.1_cassette.yml' }
    let(:orig_file_name) { File.dirname(__FILE__) + "/fixtures/#{RUBY_VERSION}/#{file_name}" }
    let(:test_dir)       { @temp_dir + '/migrate_cassettes' }

    def migrate
      VCR::TaskRunner.migrate_cassettes(test_dir)
    end

    before(:each) do
      FileUtils.mkdir_p(test_dir)
      FileUtils.cp(orig_file_name, test_dir)
    end

    it 'makes a backup of the directory' do
      migrate
      expected_backup_dir_name = test_dir + '-backup'
      expected_backup_file_name = expected_backup_dir_name + "/#{file_name}"
      File.exist?(expected_backup_dir_name).should be_true
      File.file?(expected_backup_file_name).should be_true
      File.read(expected_backup_file_name).should == File.read(orig_file_name)
    end

    it 'does not error out on yaml files with individual records' do
      YAML.should_receive(:load).and_return(VCR::Request.new(:get, 'http://example.com'))
      migrate
    end

    describe 'the structure serialized in the new 0.3.1_cassette_yml file' do
      subject do
        migrate
        YAML.load(File.read(test_dir + "/#{file_name}")).first
      end

      its(:request) { should be_instance_of(VCR::Request) }

      describe '.request' do
        def subject; super.request; end

        its(:method)  { should == :post }
        its(:uri)     { should == 'http://example.com:80/' }
        its(:body)    { should be_nil }
        its(:headers) { should be_nil }
      end

      it 'assigns the response using VCR::Response.from_net_http_response' do
        VCR::Response.should respond_to(:from_net_http_response)
        VCR::Response.should_receive(:from_net_http_response).with(an_instance_of(Net::HTTPOK)).and_return(:the_response)
        subject.response.should == :the_response
      end
    end
  end
end
