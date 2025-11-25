# frozen_string_literal: true

Jekyll::Hooks.register :site, :post_write do |site|
  releases = site.data['versions']
                 .filter { |v| !v.key?('label') || v['label'] != 'dev' }
                 .map { |v| v['version'] }.to_json

  File.write "#{site.dest}/releases.json", releases
end
