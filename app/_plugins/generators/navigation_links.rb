# frozen_string_literal: true

module Jekyll
  class NavigationLinks < Jekyll::Generator
    priority :medium

    def generate(site)
      site.pages.each_with_index do |page, index|
        next unless page.relative_path.start_with? 'docs'
        next if page.path == 'docs/index.md'
        # remove docs/<version>/ prefix and `.md` and the end
        page_url = page.path.gsub(/docs\/[^\/]+\//, '/').gsub('.md', '/')

        pages = pages_from_items(page.data["nav_items"])
        page_index = pages.index { |u| u['url'] == page_url }
        if page_index
            page.data['prev'] = pages[page_index - 1] if page_index != 0
            page.data['next'] = pages[page_index + 1] if page_index != pages.length - 1
        end
      end
    end

    def pages_from_items(items)
      items.each_with_object([]) do |i, array|
        if i.key?('url') && URI(i.fetch('url')).fragment.nil?
          array << { 'url' => i.fetch('url'), 'text' => i.fetch('text'), 'absolute_url' => i.fetch('absolute_url', false) }
        end

        if i.key?('items')
          array << pages_from_items(i.fetch('items'))
        end
      end.flatten
    end
  end
end
