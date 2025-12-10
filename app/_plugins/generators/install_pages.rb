# frozen_string_literal: true

module Jekyll
  class InstallPages < Jekyll::Generator
    priority :low

    def generate(site)
      latest_page = site.pages.detect { |p| p.relative_path == 'install/latest.md' }
      latest_page.data['release'] = site.data['latest_version']['release']
      latest_page.data['has_version'] = true

      site.data['versions'].each do |version|
        site.pages << InstallPage.new(site, version)
      end
    end
  end

  class InstallPage < Jekyll::Page
    def initialize(site, version)
      super(site, site.source, 'install', 'latest.md')

      # Override name to be version-specific while keeping content from latest.md
      @name = "#{version['release']}.md"
      @basename = version['release']

      @data['release'] = version['release']
      @data['has_version'] = true
    end
  end
end
