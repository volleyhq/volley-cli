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
      sha256 "83bd9d1b9f5d4ed9d6477159e1b2d671ffd6fe57f2415c58a0a19ffe968092d5"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.0/volley-darwin-arm64.tar.gz"
      sha256 "c490fa15f71cbd8f9ceff8d5ac9f7663253b66d18c2da29a9b908ba3b04bd817"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.0/volley-linux-amd64.tar.gz"
      sha256 "23eb48df61dea3f5ab981cc639104ab6f61f4389c809d352c52fd88993961519"
    end
    if Hardware::CPU.arm?
      url "https://github.com/volleyhq/volley-cli/releases/download/v0.1.0/volley-linux-arm64.tar.gz"
      sha256 "9c08959b167e9345c4806ed50bbd58f9588f231326703b740bdd1be2127230dc"
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

