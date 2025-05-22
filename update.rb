#!/usr/bin/env nix-shell
#!nix-shell -i ruby
#
# Usage: ./update.rb '[GLOB_PATTERN]'
#
# Example: ./update.rb 'hashicorp/*'
#
# By default the pattern is '*/*'
#

require "json"
require "yaml"
require "net/http"
require "open-uri"
require "fileutils"

ARCH_TO_NIX = {
  "amd64" => "x86_64",
  "arm64" => "aarch64",
}

OS_TO_NIX = {
  "linux" => "linux",
  "darwin" => "darwin",
}

def http_get(path)
  retries = 3
  delay = 3

  begin
    YAML.load URI.open("https://raw.githubusercontent.com/kubernetes-sigs/krew-index/master/plugins/#{path}.yaml").read
  rescue OpenURI::HTTPError => e
    fail "All retries are exhausted" if retries == 0
    puts "Error well trying to open url: #{retries -= 1}"
    sleep delay
    retry
  end
end

def get_sources(data)
  if data["files"]
    {
      url: data["uri"],
      sha256: data["sha256"],
      bin: data["bin"],
      files: data["files"],
    }
  else
    {
      url: data["uri"],
      sha256: data["sha256"],
      bin: data["bin"],
      files: [
        {
          from: "*",
          to: ".",
        },
      ],
    }
  end
end

# Get the latest version of the provider and write it to the file
def update_provider(file, plugin)
  content = http_get("#{plugin}")["spec"]
  version = content["version"]
  homepage = content["homepage"]

  archSrc = content["platforms"].inject({}) do |sum, data|
    if data["selector"]["matchLabels"]
      arch = data["selector"]["matchLabels"]["arch"]
      os = data["selector"]["matchLabels"]["os"]
      nix_arch = ARCH_TO_NIX[arch]
      nix_os = OS_TO_NIX[os]
      if nix_arch && nix_os
        sum["#{nix_arch}-#{nix_os}"] = get_sources(data)
      end
      sum
    elsif data["selector"]["matchExpressions"]
      data["selector"]["matchExpressions"][0]["values"].each do |os|
        sum["#{ARCH_TO_NIX["amd64"]}-#{OS_TO_NIX[os]}"] = get_sources(data)
        sum["#{ARCH_TO_NIX["arm64"]}-#{OS_TO_NIX[os]}"] = get_sources(data)
      end
      sum
    end
  end.sort_by { |k, v| k }.to_h

  description = ""

  if content["description"]
    description = content["description"]
  end

  data = {
    plugin: plugin,
    version: "#{version}",
    homepage: homepage,
    description: description,
    archSrc: archSrc,
  }

  prev_data = JSON.load(File.read(file)) rescue {}
  if prev_data["version"] != "#{data[:version]}"
    puts "#{prev_data["version"]} => #{data[:version]}"
    File.write(file, "#{JSON.pretty_generate(data)}\n")
  else
    puts "no update"
  end
end

Dir.chdir("#{__dir__}/plugins") do
  Dir.glob(ARGV[0] || "*").select { |f| File.directory? f }.sort.each do |path|
    $stdout.write "Updating #{path}: "
    update_provider File.join(path, "default.json"), *path.split("/")
  end
end
