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
      sha256 "047a3511ccfa6ee357cf88ec57c9f4c6a8ae7588b70f26cd03535eace2314257"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-darwin-arm64.tar.gz"
      sha256 "9c5a902c8daf5f07d825fd1dd765e429fe1d95667d448f704e08aae50a101da2"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-linux-amd64.tar.gz"
      sha256 "6b55a94d4d8f5d4f8d7428e7f87db62304b9405bb8fd0fc5a73406b0a9e66450"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-linux-arm64.tar.gz"
      sha256 "027d84c18df44f3e27c4b7ad158b4ffd8847d5325bdcd5d5a579534f5cfb0de1"
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

