# typed: false
# frozen_string_literal: true

require "livecheck/strategy"

describe Homebrew::Livecheck::Strategy::Yaml do
  subject(:yaml) { described_class }

  let(:http_url) { "https://brew.sh/blog/" }
  let(:non_http_url) { "ftp://brew.sh/" }

  let(:regex) { /^v?(\d+(?:\.\d+)+)$/i }

  let(:content) {
    <<~EOS
      versions:
        - version: 1.1.2
        - version: 1.1.2b
        - version: 1.1.2a
        - version: 1.1.1
        - version: 1.1.0
        - version: 1.1.0-rc3
        - version: 1.1.0-rc2
        - version: 1.1.0-rc1
        - version: 1.0.x-last
        - version: 1.0.3
        - version: 1.0.3-rc3
        - version: 1.0.3-rc2
        - version: 1.0.3-rc1
        - version: 1.0.2
        - version: 1.0.2-rc1
        - version: 1.0.1
        - version: 1.0.1-rc1
        - version: 1.0.0
        - version: 1.0.0-rc1
        - other: version is omitted from this object for testing
    EOS
  }
  let(:content_simple) { "version: 1.2.3" }

  # This should produce a `Psych::SyntaxError` (`did not find expected comment
  # or line break while scanning a block scalar`)
  let(:content_invalid) { ">~" }

  let(:content_matches) { ["1.1.2", "1.1.1", "1.1.0", "1.0.3", "1.0.2", "1.0.1", "1.0.0"] }
  let(:content_simple_matches) { ["1.2.3"] }

  let(:find_versions_return_hash) {
    {
      matches: {
        "1.1.2" => Version.new("1.1.2"),
        "1.1.1" => Version.new("1.1.1"),
        "1.1.0" => Version.new("1.1.0"),
        "1.0.3" => Version.new("1.0.3"),
        "1.0.2" => Version.new("1.0.2"),
        "1.0.1" => Version.new("1.0.1"),
        "1.0.0" => Version.new("1.0.0"),
      },
      regex:   regex,
      url:     http_url,
    }
  }

  let(:find_versions_cached_return_hash) {
    find_versions_return_hash.merge({ cached: true })
  }

  describe "::match?" do
    it "returns true for an HTTP URL" do
      expect(yaml.match?(http_url)).to be true
    end

    it "returns false for a non-HTTP URL" do
      expect(yaml.match?(non_http_url)).to be false
    end
  end

  describe "::parse_yaml" do
    it "returns an object when given valid content" do
      expect(yaml.parse_yaml(content_simple)).to be_an_instance_of(Hash)
    end
  end

  describe "::versions_from_content" do
    it "returns an empty array when given a block but content is blank" do
      expect(yaml.versions_from_content("", regex) { "1.2.3" }).to eq([])
    end

    it "errors if provided content is not valid YAML" do
      expect { yaml.versions_from_content(content_invalid) { [] } }
        .to raise_error(RuntimeError, "Content could not be parsed as YAML.")
    end

    it "returns an array of version strings when given content and a block" do
      # Returning a string from block
      expect(yaml.versions_from_content(content_simple) { |yaml| yaml["version"] }).to eq(content_simple_matches)
      expect(yaml.versions_from_content(content_simple, regex) do |yaml|
        yaml["version"][regex, 1]
      end).to eq(content_simple_matches)

      # Returning an array of strings from block
      expect(yaml.versions_from_content(content, regex) do |yaml, regex|
        yaml["versions"].select { |item| item["version"]&.match?(regex) }
                        .map { |item| item["version"][regex, 1] }
      end).to eq(content_matches)
    end

    it "allows a nil return from a block" do
      expect(yaml.versions_from_content(content_simple, regex) { next }).to eq([])
    end

    it "errors if a block uses two arguments but a regex is not given" do
      expect { yaml.versions_from_content(content_simple) { |yaml, regex| yaml["version"][regex, 1] } }
        .to raise_error("Two arguments found in `strategy` block but no regex provided.")
    end

    it "errors on an invalid return type from a block" do
      expect { yaml.versions_from_content(content_simple, regex) { 123 } }
        .to raise_error(TypeError, Homebrew::Livecheck::Strategy::INVALID_BLOCK_RETURN_VALUE_MSG)
    end
  end

  describe "::find_versions?" do
    it "finds versions in provided_content using a block" do
      expect(yaml.find_versions(url: http_url, regex: regex, provided_content: content) do |yaml, regex|
        yaml["versions"].select { |item| item["version"]&.match?(regex) }
                        .map { |item| item["version"][regex, 1] }
      end).to eq(find_versions_cached_return_hash)

      # NOTE: A regex should be provided using the `#regex` method in a
      # `livecheck` block but we're using a regex literal in the `strategy`
      # block here simply to ensure this method works as expected when a
      # regex isn't provided.
      expect(yaml.find_versions(url: http_url, provided_content: content) do |yaml|
        regex = /^v?(\d+(?:\.\d+)+)$/i.freeze
        yaml["versions"].select { |item| item["version"]&.match?(regex) }
                        .map { |item| item["version"][regex, 1] }
      end).to eq(find_versions_cached_return_hash.merge({ regex: nil }))
    end

    it "errors if a block is not provided" do
      expect { yaml.find_versions(url: http_url, provided_content: content) }
        .to raise_error(ArgumentError, "Yaml requires a `strategy` block")
    end

    it "returns default match_data when url is blank" do
      expect(yaml.find_versions(url: "") { "1.2.3" })
        .to eq({ matches: {}, regex: nil, url: "" })
    end

    it "returns default match_data when content is blank" do
      expect(yaml.find_versions(url: http_url, provided_content: "") { "1.2.3" })
        .to eq({ matches: {}, regex: nil, url: http_url, cached: true })
    end
  end
end
