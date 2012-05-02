require 'spec_helper'

describe VCR::Cassette::ERBRenderer do
  describe '#render' do
    def render(*args)
      described_class.new(*args).render
    end

    let(:no_vars_content) { '<%= 3 + 4 %>. Some ERB' }
    let(:vars_content) { '<%= var1 %>. ERB with Vars! <%= var2 %>' }

    context 'when ERB is disabled' do
      it 'returns the given template' do
        render(no_vars_content, false).should eq(no_vars_content)
        render(no_vars_content, nil).should eq(no_vars_content)
      end
    end

    context 'when ERB is enabled but no variables are passed' do
      it 'renders the file content as ERB' do
        render(no_vars_content, true).should eq("7. Some ERB")
      end

      it 'raises an appropriate error when the ERB template needs variables' do
        expect {
          render(vars_content, true, "vars")
        }.to raise_error(VCR::Errors::MissingERBVariableError,
          %{The ERB in the vars cassette file references undefined variable var1.  } +
          %{Pass it to the cassette using :erb => #{ {:var1=>"some value"}.inspect }.}
        )
      end

      it 'gracefully handles the template being nil' do
        render(nil, true).should be_nil
      end
    end

    context 'when ERB is enabled and variables are passed' do
      it 'renders the file content as ERB with the passed variables' do
        render(vars_content, :var1 => 'foo', :var2 => 'bar').should eq('foo. ERB with Vars! bar')
      end

      it 'raises an appropriate error when one or more of the needed variables are not passed' do
        expect {
          render(vars_content, { :var1 => 'foo' }, "vars")
        }.to raise_error(VCR::Errors::MissingERBVariableError,
          %{The ERB in the vars cassette file references undefined variable var2.  } +
          %{Pass it to the cassette using :erb => #{ {:var1 => "foo", :var2 => "some value"}.inspect }.}
        )
      end
    end
  end
end
