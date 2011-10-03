require 'spec_helper'

describe VCR::Cassette::Reader do
  describe '#read' do
    def read(*args)
      described_class.new(*args).read
    end

    let(:no_vars_content) { '<%= 3 + 4 %>. Some ERB' }
    let(:vars_content) { '<%= var1 %>. ERB with Vars! <%= var2 %>' }

    before(:each) do
      File.stub(:read) do |name|
        case name
          when 'no_vars'; no_vars_content
          when 'vars'; vars_content
          else raise ArgumentError.new("Unexpected file name: #{name}")
        end
      end
    end

    context 'when ERB is disabled' do
      it 'reads the raw file content' do
        read('no_vars', false).should eq(no_vars_content)
        read('no_vars', nil).should eq(no_vars_content)
      end
    end

    context 'when ERB is enabled but no variables are passed' do
      it 'renders the file content as ERB' do
        read('no_vars', true).should eq("7. Some ERB")
      end

      it 'raises an appropriate error when the ERB template needs variables' do
        expect {
          read('vars', true)
        }.to raise_error(VCR::Errors::MissingERBVariableError,
          %{The ERB in the vars cassette file references undefined variable var1.  } +
          %{Pass it to the cassette using :erb => #{ {:var1=>"some value"}.inspect }.}
        )
      end
    end

    context 'when ERB is enabled and variables are passed' do
      it 'renders the file content as ERB with the passed variables' do
        read('vars', :var1 => 'foo', :var2 => 'bar').should eq('foo. ERB with Vars! bar')
      end

      it 'raises an appropriate error when one or more of the needed variables are not passed' do
        expect {
          read('vars', :var1 => 'foo')
        }.to raise_error(VCR::Errors::MissingERBVariableError,
          %{The ERB in the vars cassette file references undefined variable var2.  } +
          %{Pass it to the cassette using :erb => #{ {:var1 => "foo", :var2 => "some value"}.inspect }.}
        )
      end
    end
  end
end
