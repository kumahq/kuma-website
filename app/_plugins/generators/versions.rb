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
        version_data = version_from_page_url(page.url, site.data['versions'])
        page.data['doc'] = true
        page.data['has_version'] = true
        page.data['version'] = version_data['release']
        page.data['latest_version'] = version_data['version']
        page.data['version_data'] = version_data
        # This will be removed once jekyll-single-site-generator stops discarding very new versions when use `{%version  lte:unreleasedVersion %}`
        page.data['latest_released_version'] = site.data['latest_version']['release']
        page.data['nav_items'] = site.data["docs_nav_kuma_#{version_data['release'].gsub(/\./, '')}"]

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

    def version_from_page_url(url, versions)
          parts = Pathname(url).each_filename.to_a
          return versions.detect { |v| v['release'] == parts[1] }
    end
  end
end
