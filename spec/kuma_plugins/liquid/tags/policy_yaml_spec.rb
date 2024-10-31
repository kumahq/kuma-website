require 'jekyll'
require_relative '../../../../jekyll-kuma-plugins/lib/jekyll/kuma-plugins/liquid/tags/policyyaml'
require_relative '../../../../app/_plugins/tags/tabs/tabs'
require_relative '../../../support/golden_file_manager'

# Register the tab and tabs tags from the Jekyll tabs plugin
Liquid::Template.register_tag('tab', Jekyll::Tabs::TabBlock)
Liquid::Template.register_tag('tabs', Jekyll::Tabs::TabsBlock)

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml do


  # Set up the Jekyll site and context for testing
  let(:site) { Jekyll::Site.new(Jekyll.configuration({mesh_namespace: "kuma-demo"})) }
  let(:page) { { 'version' => '2.9.1' } }  # This sets the version key for testing
  let(:registers) { { :page => page, :site => site } }
  let(:context) { Liquid::Context.new({}, {}, registers) }

  shared_examples 'policy yaml rendering' do |input_file, golden_file, tag_options|
    it "renders correctly for #{input_file}" do
      content = GoldenFileManager.load_input(input_file)
      tag_content = tag_options ? "{% policy_yaml my-tabs #{tag_options} %}" : "{% policy_yaml my-tabs %}"
      template = Liquid::Template.parse("#{tag_content}#{content}{% endpolicy_yaml %}")
      output = template.render(context)
      GoldenFileManager.assert_output(output, golden_file, include_header: true)
    end
  end

  describe 'rendering tests' do
    test_cases = [
      {
        input_file: 'spec/fixtures/mt-with-from-and-meshservice-in-to.yaml',
        golden_file: 'spec/fixtures/mt-with-from-and-meshservice-in-to.golden.html',
        tag_options: 'use_meshservice=true'
      },
      {
        input_file: 'spec/fixtures/mhr-and-mtr.yaml',
        golden_file: 'spec/fixtures/mhr-and-mtr.golden.html',
        tag_options: 'use_meshservice=true'
      },
      {
        input_file: 'spec/fixtures/mt-with-from-and-to.yaml',
        golden_file: 'spec/fixtures/mt-with-from-and-to.golden.html',
        tag_options: nil
      },
      {
        input_file: 'spec/fixtures/mtr.yaml',
        golden_file: 'spec/fixtures/mtr.golden.html',
        tag_options: 'use_meshservice=true'
      },
    ]

    test_cases.each do |test_case|
      include_examples 'policy yaml rendering',
                       test_case[:input_file],
                       test_case[:golden_file],
                       test_case[:tag_options]
    end
  end
end
