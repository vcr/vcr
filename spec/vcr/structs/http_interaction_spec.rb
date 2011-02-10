require 'spec_helper'

describe VCR::HTTPInteraction do
  %w( uri method ).each do |attr|
    it "delegates :#{attr} to the request signature" do
      sig = mock('request signature')
      sig.should_receive(attr).and_return(:the_value)
      instance = described_class.new(sig, nil)
      instance.send(attr).should == :the_value
    end
  end

  describe '#ignored?' do
    it 'returns false by default' do
      should_not be_ignored
    end

    it 'returns true when #ignore! has been called' do
      subject.ignore!
      should be_ignored
    end
  end

  describe '#filter!' do
    let(:response_status) { VCR::ResponseStatus.new(200, "OK foo") }
    let(:body) { "The body foo this is (foo-Foo)" }
    let(:headers) do {
      'x-http-foo' => ['bar23', '23foo'],
      'x-http-bar' => ['foo23', '18']
    } end

    let(:response) do
      VCR::Response.new(
        response_status,
        headers.dup,
        body.dup,
        '1.1'
      )
    end

    let(:request) do
      VCR::Request.new(
        :get,
        'http://example-foo.com:80/foo/',
        body.dup,
        headers.dup
      )
    end

    let(:interaction) { VCR::HTTPInteraction.new(request, response) }

    subject { interaction.filter!('foo', 'AAA') }

    it 'does nothing when given a blank argument' do
      expect {
        interaction.filter!(nil, 'AAA')
        interaction.filter!('foo', nil)
        interaction.filter!("", 'AAA')
        interaction.filter!('foo', "")
      }.not_to change { interaction }
    end

    [:request, :response].each do |part|
      it "replaces the sensitive text in the #{part} header keys and values" do
        subject.send(part).headers.should == {
          'x-http-AAA' => ['bar23', '23AAA'],
          'x-http-bar' => ['AAA23', '18']
        }
      end

      it "replaces the sensitive text in the #{part} body" do
        subject.send(part).body.should == "The body AAA this is (AAA-Foo)"
      end
    end

    it 'replaces the sensitive text in the response status' do
      subject.response.status.message.should == 'OK AAA'
    end

    it 'replaces sensitive text in the request URI' do
      subject.request.uri.should == 'http://example-AAA.com:80/AAA/'
    end
  end
end
