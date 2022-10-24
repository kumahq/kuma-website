# frozen_string_literal: true

module Jekyll
  class Alias < Jekyll::Generator
    priority :lowest

    def generate(site)
      content = File.read('app/_redirects')

      page = PageWithoutAFile.new(site, __dir__, '', '_redirects')
      page.content = content
      page.data['layout'] = nil
      site.pages << page
    end
  end
end
