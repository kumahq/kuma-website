# frozen_string_literal: true

module Jekyll
  class NavigationLinks < Jekyll::Generator
    priority :low

    def generate(site)
      site.pages.each_with_index do |page, _index|
        next unless page.relative_path.start_with? 'docs'
        next if page.path == 'docs/index.md'
        next unless page.data.key? 'nav_items'

        # remove docs/<version>/ prefix and `.md` and the end
        page_url = page.path.gsub(%r{docs/[^/]+/}, '/').gsub('.md', '/')

        pages = pages_from_items(page.data['nav_items'])
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
          array << { 'url' => i.fetch('url'), 'text' => i.fetch('text'),
                     'absolute_url' => i.fetch('absolute_url', false) }
        end

        array << pages_from_items(i.fetch('items')) if i.key?('items')
      end.flatten
    end
  end
end
