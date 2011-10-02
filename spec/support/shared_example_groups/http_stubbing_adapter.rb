shared_examples_for "an http stubbing adapter" do |*args|
  supported_http_libraries = args.shift
  other = args

  subject { described_class }

  Array(supported_http_libraries).each do |library|
    it_behaves_like 'an http library', library, *other
  end
end

