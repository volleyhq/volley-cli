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
      sha256 "bfcca844608fdd418152b191de41c69c621ce7fa48b659992cafc8f8af140389"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-darwin-arm64.tar.gz"
      sha256 "80442e53ca4311486db6eeb3d5d1fd93f8bdb37211ed0ca635213e0f9c546cc4"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-linux-amd64.tar.gz"
      sha256 "a37a333ee05db034d00149ffae56aba99c73af51d8e9f47c11eaf7daeef5b836"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.1/volley-linux-arm64.tar.gz"
      sha256 "e087d462c9fd449128cbab6507778712b34143fc466166ba59ef882e56f84f5b"
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

