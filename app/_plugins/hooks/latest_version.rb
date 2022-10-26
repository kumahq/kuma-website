Jekyll::Hooks.register :site, :post_write do |site|
  latest = site.data['versions'].filter {|v| v['release'] != "dev"}.last
  File.write "#{site.dest}/latest_version", latest['version']
end 