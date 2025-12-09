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
      sha256 "9531d4ced8eddc2028d0e184c2c07776ee3e76612ae7406223265a46840eb0b7"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-darwin-arm64.tar.gz"
      sha256 "e480eada14f07ebfd2f6af819f6b9a96330b4c731b70329f2bec474415715570"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-linux-amd64.tar.gz"
      sha256 "370a942f84828ac7f8ba8af0f435261c49fb21441e556f4676b276d265c8ed7f"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.2/volley-linux-arm64.tar.gz"
      sha256 "55c37d6690f6fcdae516e1e5c230bfed7f653946a52055c8609591c9d08e40c0"
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

