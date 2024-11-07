RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml do
  # Set up the Jekyll site and context for testing

  shared_examples 'policy yaml rendering' do |input_file, golden_file, tag_options, page|
    it "renders correctly for #{input_file}" do
      page = { 'release' => '2.9.x', 'edition' => "kuma" } unless page # This sets the version key for testing
      site = Jekyll::Site.new(Jekyll.configuration({mesh_namespace: "kuma-demo"}))
      context = Liquid::Context.new({}, {}, { :page => page, :site => site})
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
      {
        input_file: 'spec/fixtures/mhr-port.yaml',
        golden_file: 'spec/fixtures/mhr-port.golden.html',
        tag_options: 'use_meshservice=true'
      },
      {
        input_file: 'spec/fixtures/mhr-port.yaml',
        golden_file: 'spec/fixtures/mhr-port_edition.golden.html',
        tag_options: 'use_meshservice=true',
        page: { 'release' => '2.10.x', 'edition' => 'mesh' }
      },
    ]

    test_cases.each do |test_case|
      include_examples 'policy yaml rendering',
                       test_case[:input_file],
                       test_case[:golden_file],
                       test_case[:tag_options],
                       test_case[:page]
    end
  end
end
