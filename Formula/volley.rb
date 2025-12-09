class Volley < Formula
  desc "Volley CLI - Webhook forwarding for local development"
  homepage "https://github.com/volleyhq/volley-cli"
  url "https://github.com/volleyhq/volley-cli/archive/refs/tags/v0.1.2.tar.gz"
  sha256 ""
  license "MIT"
  version "0.1.2"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-darwin-amd64.tar.gz"
      sha256 "900f86785e5f970927a1a18ae8a6adf2d4050de0e25bf00c98da294697be62ee"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-darwin-arm64.tar.gz"
      sha256 "5efc751d2fae5e43660e124cc7cc3e942c67b039ba21af11752686fc476dbfb5"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-linux-amd64.tar.gz"
      sha256 "8709ff1bcdf7206b6691865be9b4f8a8e7f33938d5cf7022e778b7444424d61d"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-linux-arm64.tar.gz"
      sha256 "5006e44d3b2561caf1036b4f378051b88f5c4fe17816afd8eab473b7e55684a3"
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

