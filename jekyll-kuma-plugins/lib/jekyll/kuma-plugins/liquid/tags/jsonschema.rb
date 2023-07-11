require 'json'
require 'yaml'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class JsonSchema < ::Liquid::Tag
          def initialize(tag_name, markup, options)
            super
            name, *params_list = @markup.split(' ')
            params = {'type' => 'policy'}
            params_list.each do |item|
                sp = item.split('=')
                params[sp[0]] = sp[1] unless sp[1] == ''
            end
            @type = create_loader(params['type'], name)
          end

          def render(context)
            release = context.registers[:page]['release']
            base_path = context.registers[:site].config.fetch('mesh_raw_generated_path', 'app/docs')
            data = @type.load("#{base_path}/#{release}")

            <<~TIP
              <div id="markdown_html"></div>

              <script defer src="https://brianwendt.github.io/json-schema-md-doc/lib/JSONSchemaMarkdown.js"></script>
              <script type="text/javascript">
              const data = #{JSON.dump(data)};
              document.addEventListener("DOMContentLoaded", function() {
                // create an instance of JSONSchemaMarkdown
                const Doccer = new JSONSchemaMarkdown();

                // don't include the path of the field in the output
                Doccer.writePath = function() {};

                Doccer.load(data);
                Doccer.generate();

                const converter = new showdown.Converter();

                // use the converter to make html from the markdown
                document.getElementById("markdown_html").innerHTML = converter.makeHtml(Doccer.markdown);
              });
              </script>
            TIP
          end
        end
      end
    end
  end
end

class ProtoReader
    def initialize(name)
        @name = name
    end
    def load(base_path)
        path = "#{base_path}/protos/#{@name}.json"
        file = File.open(path) rescue begin
            Jekyll.logger.warn("Failed reading proto", path)
            return
        end
        d = JSON.load(file)
        return d
    end
end
class CrdReader
    def initialize(name)
        @name = name
    end
    def load(base_path)
        path = "#{base_path}/crds/#{@name}.yaml"
        file = File.open(path) rescue begin
            Jekyll.logger.warn("Failed reading crd", path)
            return
        end
        d = YAML.load(file)
        return d['spec']['versions'][0]['schema']['openAPIV3Schema']
    end
end
class PolicyReader
    def initialize(name)
        @name = name
    end
    def load(base_path)
        path = "#{base_path}/crds/kuma.io_#{@name.downcase}.yaml"
        file = File.open(path) rescue begin
            Jekyll.logger.warn("Failed reading policy", path)
            return
        end
        d = YAML.load(file)
        return d['spec']['versions'][0]['schema']['openAPIV3Schema']['properties']['spec']
    end
end
def create_loader(type, name)
    case type
    when 'proto'
        ProtoReader.new(name)
    when 'crd'
        CrdReader.new(name)
    when 'policy'
        PolicyReader.new(name)
    else
      raise "Invalid type: #{type}"
    end
end
Liquid::Template.register_tag('json_schema', Jekyll::KumaPlugins::Liquid::Tags::JsonSchema)
