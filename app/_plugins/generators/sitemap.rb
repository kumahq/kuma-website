module Sitemap
  class Generator < Jekyll::Generator # rubocop:disable Metrics/ClassLength
    priority :lowest

    def generate(site)
      # What's our latest version?
      latest = site.data['versions'].reject { |v| v['release'] == 'dev' }.last

      # Grab all pages that contain that version
      all_pages = []
      # Build a map of the latest available version of every URL
      site.pages.each do |page|
        next if is_versioned(page['url']) and !is_latest(page['url'], latest)
        all_pages << page
      end

      # Build a map of the latest available version of every URL
      site.posts.docs.each do |post|
       all_pages << {
        'url' => post.url
       }
      end

      # Save the data to generate a sitemap later
      site.data['sitemap_pages'] = build_sitemap(all_pages)
    end

    def build_sitemap(pages) # rubocop:disable Metrics/MethodLength
      # These files should NOT be in the sitemap
      blocked_from_sitemap = [
        '/_headers',
        '/_redirects',
        '/404.html'
      ]

      # Remove any pages that should not be in the sitemap
      pages = pages.filter do |p|
        next false if blocked_from_sitemap.any? { |blocked| p['url'] == blocked }
        true
      end

      # Set the frequency and priority values for the sitemap to use
      pages.map do |p|
        {
          'url' => p['url'],
          'changefreq' => 'weekly',
          'priority' => '1.0'
        }
      end
    end

    def is_versioned(url)
      versioned = [
        "/install/",
        "/docs/",
      ]
      versioned.each do |v|
        return true if url.include?(v)
      end
      false
    end

    def is_latest(url, latest)
      url.include?(latest['release'])
    end
  end
end