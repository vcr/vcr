# A sample Guardfile
# More info at http://github.com/guard/guard#readme

guard 'rspec', :version => 2 do
  watch('^spec/(.*)_spec.rb')
  watch('^lib/vcr.rb')                                { "spec/vcr_spec.rb" }
  watch('^lib/vcr/(.*)\.rb')                          { |m| "spec/#{m[1]}_spec.rb" }
  watch('^spec/spec_helper.rb')                       { "spec" }
end

guard 'cucumber' do
  watch('^features/(.*).feature')
  watch('^features/support')                       { 'features' }
  watch('^features/step_definitions')              { 'features' }
end
