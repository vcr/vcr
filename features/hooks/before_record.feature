Feature: before_record hook

  The `before_record` hook is called before a cassette is written to disk.
  This can be used to modify the HTTP interaction before it is recorded.

  Your block should accept up to 2 arguments.  The first argument will be
  the HTTP interaction that is about to be written to disk.  The second
  argument will be the current cassette.

  If you wish to prevent VCR from recording the HTTP interaction you can call
  `#ignore!` on the interaction.

  If you don't want your hook to apply to all cassettes, you can use tags to
  select which cassettes a given hook applies to.  Consider this code:

      VCR.configure do |c|
        c.before_record(:twitter) { ... } # modify the interactions somehow
      end

      VCR.use_cassette('cassette_1', :tag => :twitter) { ... }
      VCR.use_cassette('cassette_2') { ... }

  In this example, the hook would apply to the first cassette but not the
  second cassette.

  Scenario: Modify recorded response
    Given a file named "before_record_example.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello Earth" }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'

        c.before_record do |i|
          i.response.body.sub!('Earth', 'World')
        end
      end

      VCR.use_cassette('recording_example') do
        Net::HTTP.get_response('localhost', '/', $server.port)
      end
      """
    When I run `ruby before_record_example.rb`
    Then the file "cassettes/recording_example.yml" should contain "Hello World"
     And the file "cassettes/recording_example.yml" should not contain "Earth"

  Scenario: Modify recorded response based on the cassette
    Given a file named "before_record_example.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello Earth" }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'

        c.before_record do |interaction, cassette|
          interaction.response.body << " (#{cassette.name})"
        end
      end

      VCR.use_cassette('recording_example') do
        Net::HTTP.get_response('localhost', '/', $server.port)
      end
      """
    When I run `ruby before_record_example.rb`
    Then the file "cassettes/recording_example.yml" should contain "Hello Earth (recording_example)"

  Scenario: Prevent recording by ignoring interaction in before_record hook
    Given a file named "before_record_ignore.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello World" }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
        c.before_record { |i| i.ignore! }
      end

      VCR.use_cassette('recording_example') do
        response = Net::HTTP.get_response('localhost', '/', $server.port)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby before_record_ignore.rb`
    Then it should pass with "Response: Hello World"
    And the file "cassettes/recording_example.yml" should not exist

  Scenario: Multiple hooks are run in order
    Given a file named "multiple_hooks.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello World" }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'

        c.before_record { puts "In before_record hook 1" }
        c.before_record { puts "In before_record hook 2" }
      end

      VCR.use_cassette('example', :record => :new_episodes) do
        response = Net::HTTP.get_response('localhost', '/', $server.port)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby multiple_hooks.rb`
    Then it should pass with:
      """
      Response: Hello World
      In before_record hook 1
      In before_record hook 2
      """

  Scenario: Use tagging to apply hook to only certain cassettes
    Given a file named "tagged_hooks.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello World" }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'

        c.before_record(:tag_1) do
          puts "In before_record hook for tag_1"
        end
      end

      [:tag_1, :tag_2, nil].each do |tag|
        puts
        puts "Using tag: #{tag.inspect}"

        VCR.use_cassette('example', :record => :new_episodes, :tag => tag) do
          response = Net::HTTP.get_response('localhost', '/', $server.port)
          puts "Response: #{response.body}"
        end
      end
      """
    When I run `ruby tagged_hooks.rb`
    Then it should pass with:
      """
      Using tag: :tag_1
      Response: Hello World
      In before_record hook for tag_1

      Using tag: :tag_2
      Response: Hello World

      Using tag: nil
      Response: Hello World
      """

