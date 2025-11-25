# frozen_string_literal: true

require_relative 'lib/jekyll/kuma-plugins/version'

Gem::Specification.new do |spec|
  spec.name = 'jekyll-kuma-plugins'
  spec.version = Jekyll::KumaPlugins::VERSION
  spec.authors = ['Charly Molter']
  spec.email = ['charly.molter@konghq.com']

  spec.summary = 'A Set of Jekyll plugins to use in kuma-website'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/kumahq/kuma-website'
  spec.required_ruby_version = '>= 3.1.2'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'jekyll', '>= 4.2', '< 5.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
