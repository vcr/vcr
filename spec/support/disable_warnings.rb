module DisableWarnings
  def disable_warnings
    before(:all) do
      @orig_std_err = $stderr
      $stderr = StringIO.new
    end

    after(:all) do
      $stderr = @orig_std_err
    end
  end
end