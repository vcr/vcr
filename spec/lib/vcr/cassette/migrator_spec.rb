require 'tmpdir'
require 'vcr/cassette/migrator'
require 'yaml'

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
http_interactions:
- request:
    method: get
    uri: http://example.com/foo
    body:
      encoding: US-ASCII
      string: ""
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
    body:
      encoding: UTF-8
      string: Hello foo
    http_version: "1.1"
  recorded_at: Wed, 04 May 2011 12:30:00 GMT
- request:
    method: get
    uri: http://localhost:7777/bar
    body:
      encoding: US-ASCII
      string: ""
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
    body:
      encoding: UTF-8
      string: Hello bar
    http_version: "1.1"
  recorded_at: Wed, 04 May 2011 12:30:00 GMT
recorded_with: VCR #{VCR.version}
EOF
  }

  let(:dir) { './tmp/migrator' }

  before(:each) do
    # ensure the directory is empty
    FileUtils.rm_rf dir
    FileUtils.mkdir_p dir
  end

  before(:each) do
    # the encoding won't be set on rubies that don't support it
    updated_contents.gsub!(/^\s+encoding:.*$/, '')
  end unless ''.respond_to?(:encoding)

  # JRuby serializes YAML with some slightly different whitespace.
  before(:each) do
    [original_contents, updated_contents].each do |contents|
      contents.gsub!(/^(\s+)-/, '\1  -')
    end
    updated_contents.gsub!(/^(- |  )/, '  \1')
  end if RUBY_PLATFORM == 'java'

  # Use syck on all rubies for consistent results...
  around(:each) do |example|
    YAML::ENGINE.yamler = 'syck'
    begin
      example.call
    ensure
      YAML::ENGINE.yamler = 'psych'
    end
  end if defined?(YAML::ENGINE) && RUBY_VERSION.to_f < 2.0

  let(:filemtime) { Time.utc(2011, 5, 4, 12, 30) }
  let(:out_io)    { StringIO.new }
  let(:file_name) { File.join(dir, "example.yml") }
  let(:output)    { out_io.rewind; out_io.read }

  subject { described_class.new(dir, out_io) }

  before(:each) do
    allow(File).to receive(:mtime).with(file_name).and_return(filemtime)
  end

  it 'migrates a cassette from the 1.x to 2.x format' do
    File.open(file_name, 'w') { |f| f.write(original_contents) }
    subject.migrate!
    expect(YAML.load_file(file_name)).to eq(YAML.load(updated_contents))
    expect(output).to match(/Migrated example.yml/)
  end

  it 'ignores files that do not contain arrays' do
    File.open(file_name, 'w') { |f| f.write(true.to_yaml) }
    subject.migrate!
    expect(File.read(file_name)).to eq(true.to_yaml)
    expect(output).to match(/Ignored example.yml since it does not appear to be a valid VCR 1.x cassette/)
  end

  it 'ignores files that contain YAML arrays of other things' do
    File.open(file_name, 'w') { |f| f.write([{}, {}].to_yaml) }
    subject.migrate!
    expect(File.read(file_name)).to eq([{}, {}].to_yaml)
    expect(output).to match(/Ignored example.yml since it does not appear to be a valid VCR 1.x cassette/)
  end

  it 'ignores URIs that have sensitive data substitutions' do
    modified_contents = original_contents.gsub('example.com', '<HOST>')
    File.open(file_name, 'w') { |f| f.write(modified_contents) }
    subject.migrate!
    expect(YAML.load_file(file_name)).to eq(YAML.load(updated_contents.gsub('example.com', '<HOST>:80')))
  end

  it 'ignores files that are empty' do
    File.open(file_name, 'w') { |f| f.write('') }
    subject.migrate!
    expect(File.read(file_name)).to eq('')
    expect(output).to match(/Ignored example.yml since it could not be parsed as YAML/)
  end

  shared_examples_for "ignoring invalid YAML" do
    it 'ignores files that cannot be parsed as valid YAML (such as ERB cassettes)' do
      modified_contents = original_contents.gsub(/\A---/, "---\n<% 3.times do %>")
      modified_contents = modified_contents.gsub(/\z/, "<% end %>")
      File.open(file_name, 'w') { |f| f.write(modified_contents) }
      subject.migrate!
      expect(File.read(file_name)).to eq(modified_contents)
      expect(output).to match(/Ignored example.yml since it could not be parsed as YAML/)
    end
  end

  context 'with syck' do
    it_behaves_like "ignoring invalid YAML"
  end

  context 'with psych' do
    before(:each) do
      YAML::ENGINE.yamler = 'psych'
    end

    it_behaves_like "ignoring invalid YAML"
  end if defined?(YAML::ENGINE)
end

