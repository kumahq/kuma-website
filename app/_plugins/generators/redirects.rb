# frozen_string_literal: true

module Jekyll
  class Redirects < Jekyll::Generator
    priority :low

    def generate(site)
      active_versions = site.data['versions'].filter { |v| !v.key?('label') || v['label'] != 'dev' }

      # Generate redirects for the latest version
      latest_release = site.data['latest_version']['release']

      kuma_redirects = existing_redirects(latest_release).join("\n")
      common_redirects = common_redirects(latest_release).join("\n")

      # Generate redirects for specific versions
      version_specific_redirects = active_versions.each_with_object([]) do |v, redirects|
        next unless Gem::Version.correct?(v['version'])

        vp = v['version'].split('.').map(&:to_i)

        # Generate redirects for x.y.0, x.y.1, x.y.2 etc
        # Until we hit the actual version stored in versions.yml
        (0..vp[2]).each do |idx|
          current = "#{vp[0]}.#{vp[1]}.#{idx}"
          redirects << "/docs/#{current}/*  /docs/#{v['release']}/:splat  301"
          redirects << "/install/#{current}/*  /install/#{v['release']}/:splat  301"
        end
      end.join("\n")

      # Add all hand-crafted redirects
      redirects = <<~RDR
        # Specific version to release
        #{version_specific_redirects}

        # _redirects file:
        #{kuma_redirects}

        # _common_redirects file:
        #{common_redirects}
      RDR

      write_file(site, '_redirects', redirects)
    end

    def write_file(site, path, content)
      page = PageWithoutAFile.new(site, __dir__, '', path)
      page.content = content
      page.data['layout'] = nil
      site.pages << page
    end

    private

    def existing_redirects(latest_release)
      @existing_redirects ||= File.readlines(
        'app/_redirects',
        chomp: true
      ).map { |l| l.gsub('/LATEST_RELEASE/', "/#{latest_release}/") }
    end

    def common_redirects(latest_release)
      @common_redirects ||= File.readlines(
        'app/_common_redirects',
        chomp: true
      ).map { |l| l.gsub('/LATEST_RELEASE/', "/#{latest_release}/") }
    end
  end
end
