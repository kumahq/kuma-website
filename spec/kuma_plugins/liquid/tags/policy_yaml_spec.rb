require 'jekyll'
require_relative '../../../../jekyll-kuma-plugins/lib/jekyll/kuma-plugins/liquid/tags/policyyaml'
require_relative '../../../../app/_plugins/tags/tabs/tabs'
require_relative '../../../support/golden_file_manager'

# Register the tab and tabs tags from the Jekyll tabs plugin
Liquid::Template.register_tag('tab', Jekyll::Tabs::TabBlock)
Liquid::Template.register_tag('tabs', Jekyll::Tabs::TabsBlock)

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml do
  let(:input_file) { 'spec/fixtures/input.yaml' }
  let(:golden_file) { 'spec/fixtures/output.html.golden' }

  # Load input YAML content from the file
  let(:content) { GoldenFileManager.load_input(input_file) }

  # Set up the Jekyll site and context for testing
  let(:site) { Jekyll::Site.new(Jekyll.configuration) }
  let(:page) { { 'version' => '2.9.1' } }  # This sets the version key for testing
  let(:registers) { { :page => page, :site => site } }
  let(:context) { Liquid::Context.new({}, {}, registers) }

  it 'renders universal and kubernetes versions correctly' do
    # Parse the Liquid template that uses the policy_yaml tag
    template = Liquid::Template.parse("{% policy_yaml my-tabs %}#{content}{% endpolicy_yaml %}")

    # Render the template with the given context
    output = template.render(context)

    # Log the rendered output for debugging
    puts "Output from render: #{output}"

    # Use GoldenFileManager to assert the output
    GoldenFileManager.assert_output(output, golden_file)
  end
end
