# A sample Guardfile
# More info at http://github.com/guard/guard#readme

guard 'rspec', :version => 2 do
  watch(%r|^spec/(.*)_spec.rb|)
  watch(%r|^lib/(.*)\.rb|)           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r|^spec/spec_helper.rb|)    { "spec" }
end

guard 'cucumber' do
  watch(%r|^features/(.*).feature|)
  watch(%r|^features/support|)                       { 'features' }
  watch(%r|^features/step_definitions|)              { 'features' }
end
