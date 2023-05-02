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
