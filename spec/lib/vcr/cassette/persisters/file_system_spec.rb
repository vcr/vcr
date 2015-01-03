require 'spec_helper'
require 'vcr/cassette/persisters/file_system'

module VCR
  class Cassette
    class Persisters
      describe FileSystem do
        before { FileSystem.storage_location = VCR.configuration.cassette_library_dir }

        describe "#[]" do
          it 'reads from the given file, relative to the configured storage location' do
            File.open(FileSystem.storage_location + '/foo.txt', 'w') { |f| f.write('1234') }
            expect(FileSystem["foo.txt"]).to eq("1234")
          end

          it 'handles directories in the given file name' do
            FileUtils.mkdir_p FileSystem.storage_location + '/a'
            File.open(FileSystem.storage_location + '/a/b', 'w') { |f| f.write('1234') }
            expect(FileSystem["a/b"]).to eq("1234")
          end

          it 'returns nil if the file does not exist' do
            expect(FileSystem["non_existant_file"]).to be_nil
          end
        end

        describe "#[]=" do
          it 'writes the given file contents to the given file name' do
            expect(File.exist?(FileSystem.storage_location + '/foo.txt')).to be false
            FileSystem["foo.txt"] = "bar"
            expect(File.read(FileSystem.storage_location + '/foo.txt')).to eq("bar")
          end

          it 'creates any needed intermediary directories' do
            expect(File.exist?(FileSystem.storage_location + '/a')).to be false
            FileSystem["a/b"] = "bar"
            expect(File.read(FileSystem.storage_location + '/a/b')).to eq("bar")
          end
        end

        describe "#absolute_path_to_file" do
          it "returns the absolute path to the given relative file based on the storage location" do
            expected = File.join(FileSystem.storage_location, "bar/bazz.json")
            expect(FileSystem.absolute_path_to_file("bar/bazz.json")).to eq(expected)
          end

          it "returns nil if the storage_location is not set" do
            FileSystem.storage_location = nil
            expect(FileSystem.absolute_path_to_file("bar/bazz.json")).to be_nil
          end

          it "sanitizes the file name" do
            expected = File.join(FileSystem.storage_location, "_t_i-t_1_2_f_n.json")
            expect(FileSystem.absolute_path_to_file("\nt \t!  i-t_1.2_f n.json")).to eq(expected)

            expected = File.join(FileSystem.storage_location, "a_1/b")
            expect(FileSystem.absolute_path_to_file("a 1/b")).to eq(expected)
          end

          it 'handles files with no extensions (even when there is a dot in the path)' do
            expected = File.join(FileSystem.storage_location, "/foo_bar/baz_qux")
            expect(FileSystem.absolute_path_to_file("/foo.bar/baz qux")).to eq(expected)
          end
        end
      end
    end
  end
end

