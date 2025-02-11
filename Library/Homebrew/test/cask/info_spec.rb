# typed: false
# frozen_string_literal: true

require "utils"

describe Cask::Info, :cask do
  it "displays some nice info about the specified Cask" do
    expect {
      described_class.info(Cask::CaskLoader.load("local-transmission"))
    }.to output(<<~EOS).to_stdout
      ==> local-transmission: 2.61
      https://transmissionbt.com/
      Not installed
      From: https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/local-transmission.rb
      ==> Name
      Transmission
      ==> Description
      BitTorrent client
      ==> Artifacts
      Transmission.app (App)
    EOS
  end

  it "prints auto_updates if the Cask has `auto_updates true`" do
    expect {
      described_class.info(Cask::CaskLoader.load("with-auto-updates"))
    }.to output(<<~EOS).to_stdout
      ==> with-auto-updates: 1.0 (auto_updates)
      https://brew.sh/autoupdates
      Not installed
      From: https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/with-auto-updates.rb
      ==> Name
      AutoUpdates
      ==> Description
      None
      ==> Artifacts
      AutoUpdates.app (App)
    EOS
  end

  it "prints caveats if the Cask provided one" do
    expect {
      described_class.info(Cask::CaskLoader.load("with-caveats"))
    }.to output(<<~EOS).to_stdout
      ==> with-caveats: 1.2.3
      https://brew.sh/
      Not installed
      From: https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/with-caveats.rb
      ==> Name
      None
      ==> Description
      None
      ==> Artifacts
      Caffeine.app (App)
      ==> Caveats
      Here are some things you might want to know.

      Cask token: with-caveats

      Custom text via puts followed by DSL-generated text:
      To use with-caveats, you may need to add the /custom/path/bin directory
      to your PATH environment variable, e.g. (for Bash shell):
        export PATH=/custom/path/bin:"$PATH"

    EOS
  end

  it 'does not print "Caveats" section divider if the caveats block has no output' do
    expect {
      described_class.info(Cask::CaskLoader.load("with-conditional-caveats"))
    }.to output(<<~EOS).to_stdout
      ==> with-conditional-caveats: 1.2.3
      https://brew.sh/
      Not installed
      From: https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/with-conditional-caveats.rb
      ==> Name
      None
      ==> Description
      None
      ==> Artifacts
      Caffeine.app (App)
    EOS
  end

  it "prints languages specified in the Cask" do
    expect {
      described_class.info(Cask::CaskLoader.load("with-languages"))
    }.to output(<<~EOS).to_stdout
      ==> with-languages: 1.2.3
      https://brew.sh/
      Not installed
      From: https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/with-languages.rb
      ==> Name
      None
      ==> Description
      None
      ==> Languages
      zh, en-US
      ==> Artifacts
      Caffeine.app (App)
    EOS
  end

  it 'does not print "Languages" section divider if the languages block has no output' do
    expect {
      described_class.info(Cask::CaskLoader.load("without-languages"))
    }.to output(<<~EOS).to_stdout
      ==> without-languages: 1.2.3
      https://brew.sh/
      Not installed
      From: https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/without-languages.rb
      ==> Name
      None
      ==> Description
      None
      ==> Artifacts
      Caffeine.app (App)
    EOS
  end
end
