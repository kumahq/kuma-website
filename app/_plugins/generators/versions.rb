# frozen_string_literal: true

module Jekyll
  class Versions < Jekyll::Generator
    priority :high

    def generate(site)
      latest_version = site.data['versions'].reject { |v| v['release'] == 'dev' }.last
      site.data['latest_version'] = latest_version

      # Add a `version` property to every versioned page
      # TODO: Also create aliases under /latest/ for all x.x.x doc pages
      site.pages.each do |page|
        next unless page.relative_path.start_with? 'docs'

        parts = Pathname(page.relative_path).each_filename.to_a

        latest = site.data['versions'].detect { |v| v['release'] == parts[1] }

        page.data['doc'] = true
        page.data['has_version'] = true
        page.data['version'] = parts[1]

        if latest
          page.data['latest_version'] = latest['version']
          page.data['latest_release'] = latest['release']
        end

        page.data['nav_items'] = site.data["docs_nav_kuma_#{parts[1].gsub(/\./, '')}"]

        # Clean up nav_items for generated pages as there's an
        # additional level of nesting
        page.data['nav_items'] = page.data['nav_items']['items'] if page.data['nav_items'].is_a?(Hash)
      end
    end
  end
end
