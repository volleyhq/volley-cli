class Volley < Formula
  desc "Volley CLI - Webhook forwarding for local development"
  homepage "https://github.com/volleyhq/volley-cli"
  url "https://github.com/volleyhq/volley-cli/archive/refs/tags/v0.1.0.tar.gz"
  sha256 ""
  license "MIT"
  version "0.1.0"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.0/volley-darwin-amd64.tar.gz"
      sha256 ""
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.0/volley-darwin-arm64.tar.gz"
      sha256 ""
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.0/volley-linux-amd64.tar.gz"
      sha256 ""
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.0/volley-linux-arm64.tar.gz"
      sha256 ""
    end
  end

  def install
    bin.install "volley"
  end

  test do
    system "#{bin}/volley", "--version"
  end
end

