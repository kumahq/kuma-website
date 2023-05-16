module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class PolicySchema < ::Liquid::Tag
          def initialize(tag_name, markup, options)
            super

            @markup = markup.strip
          end

          def render(context)
            release = context.registers[:page]['release']

            <<~TIP
              <div id='markdown_html'></div>

              <script type="text/javascript">
              document.addEventListener("DOMContentLoaded", function(){
                  const schema = fetch("/docs/#{release}/generated/#{@markup}.json")
                  .then(response => response.json())
                  .then(schema => {
                    // create an instance of JSONSchemaMarkdown
                    const Doccer = new JSONSchemaMarkdown();

                    // don't include the path of the field in the output
                    Doccer.writePath = function() {};

                    // Don't error if `properties` isn't present
                    // See https://github.com/BrianWendt/json-schema-md-doc/pull/18
                    Doccer.typeObject = function (name, data, level, path) {
                      const required = data.required ?? [];
                      const properties = data.properties || {};
                      this.writeAdditionalProperties(data.additionalProperties, level);

                      if (this.notEmpty(data.minProperties) || this.notEmpty(data.maxProperties)) {
                          this.indent(level);
                          this.markdown += "Property Count: ";
                          this.writeMinMax(data.minProperties, data.maxProperties);
                      }

                      this.writePropertyNames(data.propertyNames, level);
                      this.writeSectionName("Properties", level, path);
                      path += "/properties";
                      for (var propName in properties) {
                          var propPath = path + this.pathDivider + propName;
                          var property = properties[propName];
                          var isRequired = (required.indexOf(propName) > -1);
                          this.writePropertyName(propName, level + 1, propPath, isRequired);
                          this.generateChildren(propName, property, level + 2, propPath);
                      }
                    }

                    Doccer.load(schema.properties.spec);
                    Doccer.generate();

                    const converter = new showdown.Converter();

                    // use the converter to make html from the markdown
                    document.getElementById('markdown_html').innerHTML = converter.makeHtml(Doccer.markdown);
                  });
              });
              </script>
            TIP
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('policy_schema', Jekyll::KumaPlugins::Liquid::Tags::PolicySchema)
