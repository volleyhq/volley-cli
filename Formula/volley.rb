class Volley < Formula
  desc "Volley CLI - Webhook forwarding for local development"
  homepage "https://github.com/volleyhq/volley-cli"
  url "https://github.com/volleyhq/volley-cli/archive/refs/tags/v0.1.1.tar.gz"
  sha256 ""
  license "MIT"
  version "0.1.1"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-darwin-amd64.tar.gz"
      sha256 "6bcb155f53e4c7565e6d6efba2ab10213ebfe569bf36d2ddfc6e10caf26148cd"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-darwin-arm64.tar.gz"
      sha256 "4d2c146bbb50aec2d579b9d35040e2f4e8a43e19e2590c9327dd86007c5d2815"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-linux-amd64.tar.gz"
      sha256 "95915db74708db92f0faaae1113ba51d807df3ecb20bf2d68fa524d9eb0f488b"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-linux-arm64.tar.gz"
      sha256 "0c78fbbfe8f9acb4bb907b0a907ab8432b9ad698ec691a63db3471e6b970ea3a"
    end
  end

  def install
    if OS.mac?
      if Hardware::CPU.intel?
        bin.install "volley-darwin-amd64" => "volley"
      else
        bin.install "volley-darwin-arm64" => "volley"
      end
    else
      if Hardware::CPU.intel?
        bin.install "volley-linux-amd64" => "volley"
      else
        bin.install "volley-linux-arm64" => "volley"
      end
    end
  end

  test do
    system "#{bin}/volley", "--version"
  end
end

