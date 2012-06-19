require 'spec_helper'
require 'vcr/cassette/persisters/file_system_gzipped'

module VCR
  class Cassette
    class Persisters
      describe FileSystemGzipped do
        before { FileSystemGzipped.storage_location = VCR.configuration.cassette_library_dir }

        describe "#[]" do
          it 'reads from the given compressed file, stored with .gz extension' do
            file_path = FileSystemGzipped.storage_location + '/foo.txt.gz'
            Zlib::GzipWriter.open(file_path) do |gz|
              gz.write('12345')
            end
            FileSystemGzipped["foo.txt"].should eq("12345")
          end

          it 'handles directories in the given file name' do
            base_location = FileSystemGzipped.storage_location + '/a'
            FileUtils.mkdir_p base_location
            Zlib::GzipWriter.open(base_location + '/b.gz') do |gz|
              gz.write('1234')
            end
            FileSystemGzipped["a/b"].should eq("1234")
          end

          it 'returns nil if the file does not exist' do
            FileSystemGzipped["non_existant_file"].should be_nil
          end
        end

        describe "#[]=" do
          it 'writes the given file gzipped contents to the given file name with .gz extension' do
            file_path = FileSystemGzipped.storage_location + '/foo.txt.gz'
            File.exist?(file_path).should be_false
            FileSystemGzipped["foo.txt"] = "bar"
            Zlib::GzipReader.open(file_path) { |gz| gz.read.should eq("bar") }
          end

          it 'creates any needed intermediary directories' do
            File.exist?(FileSystemGzipped.storage_location + '/a').should be_false
            FileSystemGzipped["a/b"] = "bar"
            file_path = FileSystemGzipped.storage_location + '/a/b.gz'
            Zlib::GzipReader.open(file_path) { |gz| gz.read.should eq("bar") }
          end
        end

        describe "#absolute_path_to_file" do
          it "returns the absolute path to file relative to the storage location with .gz extension" do
            expected = File.join(FileSystemGzipped.storage_location, "bar/bazz.json.gz")
            FileSystemGzipped.absolute_path_to_file("bar/bazz.json").should eq(expected)
          end

          it "returns nil if the storage_location is not set" do
            FileSystemGzipped.storage_location = nil
            FileSystemGzipped.absolute_path_to_file("bar/bazz.json").should be_nil
          end

          it "sanitizes the file name before adding .gz extension" do
            expected = File.join(FileSystemGzipped.storage_location, "_t_i-t_1_2_f_n.json.gz")
            FileSystemGzipped.absolute_path_to_file("\nt \t!  i-t_1.2_f n.json").should eq(expected)

            expected = File.join(FileSystemGzipped.storage_location, "a_1/b.gz")
            FileSystemGzipped.absolute_path_to_file("a 1/b").should eq(expected)
          end
        end
      end
    end
  end
end

