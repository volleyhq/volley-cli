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
      sha256 "fd6d6129882e1a93b190340f0d8ed69cfc33969a7ac2c0a5f39eb9cff335a480"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-darwin-arm64.tar.gz"
      sha256 "d5c60b6f49046cef58c687d1828e272aac40af9518d75261394efa3d5881b3bd"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-linux-amd64.tar.gz"
      sha256 "5e9588cdec444133ea8842eb72a47a46f631580c30d684e2ada9f266765b6b62"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-linux-arm64.tar.gz"
      sha256 "f8283b9ad017094b1cc4962d12e1052fb5e92ae2244b98c38c86ef36cbfbe1bf"
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

