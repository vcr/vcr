require 'tmpdir'
require 'vcr/cassette/migrator'

describe VCR::Cassette::Migrator do
  let(:original_contents) { <<-EOF
--- 
- !ruby/struct:VCR::HTTPInteraction 
  request: !ruby/struct:VCR::Request 
    method: :get
    uri: http://example.com:80/foo
    body: 
    headers: 
  response: !ruby/struct:VCR::Response 
    status: !ruby/struct:VCR::ResponseStatus 
      code: 200
      message: OK
    headers: 
      content-type: 
      - text/html;charset=utf-8
      content-length: 
      - "9"
    body: Hello foo
    http_version: "1.1"
- !ruby/struct:VCR::HTTPInteraction 
  request: !ruby/struct:VCR::Request 
    method: :get
    uri: http://localhost:7777/bar
    body: 
    headers: 
  response: !ruby/struct:VCR::Response 
    status: !ruby/struct:VCR::ResponseStatus 
      code: 200
      message: OK
    headers: 
      content-type: 
      - text/html;charset=utf-8
      content-length: 
      - "9"
    body: Hello bar
    http_version: "1.1"
EOF
  }

  let(:updated_contents) { <<-EOF
--- 
- request: 
    method: get
    uri: http://example.com/foo
    body: ""
    headers: {}

  response: 
    status: 
      code: 200
      message: OK
    headers: 
      Content-Type: 
      - text/html;charset=utf-8
      Content-Length: 
      - "9"
    body: Hello foo
    http_version: "1.1"
- request: 
    method: get
    uri: http://localhost:7777/bar
    body: ""
    headers: {}

  response: 
    status: 
      code: 200
      message: OK
    headers: 
      Content-Type: 
      - text/html;charset=utf-8
      Content-Length: 
      - "9"
    body: Hello bar
    http_version: "1.1"
EOF
  }

  attr_accessor :dir

  around(:each) do |example|
    Dir.mktmpdir do |dir|
      self.dir = dir
      example.run
    end
  end

  # Use syck on all rubies for consistent results...
  before(:each) do
    YAML::ENGINE.yamler = 'syck' if defined?(YAML::ENGINE)
  end

  after(:each) do
    YAML::ENGINE.yamler = 'psych' if defined?(YAML::ENGINE)
  end

  let(:out_io)    { StringIO.new }
  let(:file_name) { File.join(dir, "example.yml") }
  let(:output)    { out_io.rewind; out_io.read }

  subject { described_class.new(dir, out_io) }

  it 'migrates a cassette from the 1.x to 2.x format' do
    File.open(file_name, 'w') { |f| f.write(original_contents) }
    subject.migrate!
    File.read(file_name).should eq(updated_contents)
    output.should match(/Migrated example.yml/)
  end

  it 'ignores files that do not contain arrays' do
    File.open(file_name, 'w') { |f| f.write(true.to_yaml) }
    subject.migrate!
    File.read(file_name).should eq(true.to_yaml)
    output.should match(/Ignored example.yml since it does not appear to be a valid VCR 1.x cassette/)
  end

  it 'ignores files that contain YAML arrays of other things' do
    File.open(file_name, 'w') { |f| f.write([{}, {}].to_yaml) }
    subject.migrate!
    File.read(file_name).should eq([{}, {}].to_yaml)
    output.should match(/Ignored example.yml since it does not appear to be a valid VCR 1.x cassette/)
  end

  it 'ignores URIs that have sensitive data substitutions' do
    modified_contents = original_contents.gsub('example.com', '<HOST>')
    File.open(file_name, 'w') { |f| f.write(modified_contents) }
    subject.migrate!
    File.read(file_name).should eq(updated_contents.gsub('example.com', '<HOST>:80'))
  end

  it 'ignores files that are empty' do
    File.open(file_name, 'w') { |f| f.write('') }
    subject.migrate!
    File.read(file_name).should eq('')
    output.should match(/Ignored example.yml since it could not be parsed as YAML/)
  end

  shared_examples_for "ignoring invalid YAML" do
    it 'ignores files that cannot be parsed as valid YAML (such as ERB cassettes)' do
      modified_contents = original_contents.gsub(/\A---/, "---\n<% 3.times do %>")
      modified_contents = modified_contents.gsub(/\z/, "<% end %>")
      File.open(file_name, 'w') { |f| f.write(modified_contents) }
      subject.migrate!
      File.read(file_name).should eq(modified_contents)
      output.should match(/Ignored example.yml since it could not be parsed as YAML/)
    end
  end

  context 'with syck' do
    it_behaves_like "ignoring invalid YAML"
  end

  context 'with psych' do
    before(:each) do
      pending "psych not available" unless defined?(YAML::ENGINE)
      YAML::ENGINE.yamler = 'psych'
    end

    it_behaves_like "ignoring invalid YAML"
  end
end

