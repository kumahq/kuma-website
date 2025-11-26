# frozen_string_literal: true

require 'json'
require 'yaml'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class JsonSchema < ::Liquid::Tag
          def initialize(tag_name, markup, options)
            super
            name, *params_list = @markup.split
            params = { 'type' => 'policy' }
            params_list.each do |item|
              sp = item.split('=')
              params[sp[0]] = sp[1] unless sp[1] == ''
            end
            @load = create_loader(params['type'], name)
          end

          # TODO: refactor to reduce method length
          def render(context)
            release = context.registers[:page]['release']
            base_paths = context.registers[:site].config.fetch(PATHS_CONFIG, DEFAULT_PATHS)
            begin
              data = @load.call(base_paths, release)
              <<~TIP
                <div id="markdown_html"></div>

                <script defer src="https://cdnjs.cloudflare.com/ajax/libs/showdown/1.9.0/showdown.min.js"></script>
                <script defer src="https://brianwendt.github.io/json-schema-md-doc/json-schema-md-doc.min.js"></script>
                <script type="text/javascript">
                const data = #{JSON.dump(data)};
                document.addEventListener("DOMContentLoaded", function() {
                  function removeNewlinesFromDescriptions(obj) {
                    for (const key in obj) {
                      if (typeof obj[key] === 'object') {
                        // Recursively process nested objects
                        removeNewlinesFromDescriptions(obj[key]);
                      } else if (key === 'description' && typeof obj[key] === 'string') {
                        // Replace newlines in description values
                        obj[key] = obj[key].replace(/\\n/g, '');
                      }
                    }
                  }

                  // create an instance of JSONSchemaMarkdown
                  const Doccer = new JSONSchemaMarkdownDoc();
                  // don't include the path of the field in the output
                  Doccer.writePath = function() {};
                  // remove new lines in description
                  removeNewlinesFromDescriptions(data)

                  Doccer.load(data);

                  const converter = new showdown.Converter();
                  // use the converter to make html from the markdown
                  document.getElementById("markdown_html").innerHTML = converter.makeHtml(Doccer.generate());
                });
                </script>
              TIP
            rescue StandardError => e
              Jekyll.logger.warn('Failed reading jsonschema', e)
              nil
            end
          end
        end
      end
    end
  end
end

PATHS_CONFIG = 'mesh_raw_generated_paths'
DEFAULT_PATHS = ['app/assets'].freeze
def read_file(paths, file_name)
  paths.each do |path|
    file_path = File.join(path, file_name)
    return File.open(file_path) if File.readable? file_path
  end
  raise "couldn't read #{file_name} in none of these paths:#{paths}"
end

# TODO: refactor to reduce complexity
def create_loader(type, name)
  case type
  when 'proto'
    l = lambda do |paths, release|
      JSON.parse(read_file(paths, File.join(release.to_s, 'raw', 'protos', "#{name}.json")))
    end
  when 'crd'
    l = lambda do |paths, release|
      d = YAML.load(read_file(paths, File.join(release.to_s, 'raw', 'crds', "#{name}.yaml")))
      d['spec']['versions'][0]['schema']['openAPIV3Schema']
    end
  when 'policy'
    l = lambda do |paths, release|
      d = YAML.load(read_file(paths, File.join(release.to_s, 'raw', 'crds', "kuma.io_#{name.downcase}.yaml")))
      d['spec']['versions'][0]['schema']['openAPIV3Schema']['properties']['spec']
    end
  else
    raise "Invalid type: #{type}"
  end
  l
end
Liquid::Template.register_tag('json_schema', Jekyll::KumaPlugins::Liquid::Tags::JsonSchema)
