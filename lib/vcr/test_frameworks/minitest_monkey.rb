class MiniTest::Spec
  before :each do |example|
    if metadata[:vcr]
      test_info = example.class.name.split("::").map {|e| e.underscore}.reject(&:empty?)
      name = spec_name.underscore.gsub(/[^\w\/]+/, "_")
      path = "test/cassettes/" + [(test_info[0] + "_test"), test_info[1]].join("/")
      FileUtils.mkdir_p(path) unless File.exists?(path)
      VCR.configure do |c|
        c.cassette_library_dir = path
      end
      VCR.insert_cassette name
    end
  end

  after :each do
    if metadata[:vcr]
      VCR.eject_cassette
      VCR.configure do |c|
        c.cassette_library_dir = 'test/cassettes'
      end
    end
  end
end
