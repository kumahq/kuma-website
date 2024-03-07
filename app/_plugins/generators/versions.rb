# frozen_string_literal: true

module Jekyll
  class Versions < Jekyll::Generator
    priority :high

    def generate(site)
      latest_version = latest_version(site.data['versions'])
      site.data['latest_version'] = latest_version

      # Add a `version` property to every versioned page
      # TODO: Also create aliases under /latest/ for all x.x.x doc pages
      site.pages.each do |page|
        next unless page.url.start_with?('/docs/')

        release = release_for(page)

        page.data['nav_items'] = {}

        next unless release

        page.data['doc'] = true
        page.data['has_version'] = true

        page.data['release'] ||= release.to_liquid
        page.data['version'] ||= release.default_version
        page.data['version_data'] = release.to_h
        page.data['latest_version'] = edition(site).latest_release.to_h

        # This will be removed once jekyll-single-site-generator stops discarding very new versions when use `{%version  lte:unreleasedVersion %}`
        page.data['nav_items'] = site.data["docs_nav_kuma_#{release.value.gsub(/\./, '')}"]

        # Clean up nav_items for generated pages as there's an
        # additional level of nesting
        page.data['nav_items'] = page.data['nav_items']['items'] if page.data['nav_items'].is_a?(Hash)
      end
    end

    private

    def latest_version(versions)
        latest_versions = versions.select {|v| v['latest']}
        if latest_versions.size != 1
          raise "Exactly one entry in app/_data/versions.yml must be marked as 'latest: true' (#{latest_versions.size} found)"
        end
        return latest_versions.first
    end

    def edition(site)
      @edition ||= Jekyll::GeneratorSingleSource::Product::Edition
        .new(edition: 'kuma', site: site)
    end

    def release_for(page)
      parts = Pathname(page.url).each_filename.to_a

      edition(page.site).releases.detect { |r| r.to_s == parts[1] }
    end
  end
end
