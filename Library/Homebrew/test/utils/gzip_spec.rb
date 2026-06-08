# typed: true
# frozen_string_literal: true

require "utils/gzip"

RSpec.describe Utils::Gzip do
  include FileUtils

  describe "compress_with_options" do
    it "uses the explicitly specified mtime, orig_name and output path when passed" do
      mktmpdir do |path|
        mtime = Time.at(12345).utc
        orig_name = "someotherfile"
        output = path/"subdir/anotherfile.gz"
        file_content = "Hello world"
        expected_checksum = "df509051b519faa8a1143157d2750d1694dc5fe6373e493c0d5c360be3e61516"

        somefile = path/"somefile"
        File.write(somefile, file_content)
        mkdir path/"subdir"

        expect(described_class.compress_with_options(somefile, mtime:, orig_name:,
output:)).to eq(output)
        expect(Digest::SHA256.hexdigest(File.read(output))).to eq(expected_checksum)
      end
    end

    it "uses SOURCE_DATE_EPOCH as mtime when not explicitly specified" do
      mktmpdir do |path|
        ENV["SOURCE_DATE_EPOCH"] = "23456"
        file_content = "Hello world"
        expected_checksum = "a579be88ec8073391a5753b1df4d87fbf008aaec6b5a03f8f16412e2e01f119a"

        somefile = path/"somefile"
        File.write(somefile, file_content)

        expect(described_class.compress_with_options(somefile).to_s).to eq("#{somefile}.gz")
        expect(Digest::SHA256.hexdigest(File.read("#{somefile}.gz"))).to eq(expected_checksum)
      end
    end
  end
end
