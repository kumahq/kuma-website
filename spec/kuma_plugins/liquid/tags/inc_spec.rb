RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::Inc do
  let(:version) { '2.9.1' }
  let(:site) { Jekyll::Site.new(Jekyll.configuration({ mesh_namespace: "kuma-demo" })) }
  # If we ever upgrade jekyll-generator-single-source we will have to change below to:
  # let(:release) { Jekyll::GeneratorSingleSource::Product::Release.new({ 'release' => version }) }
  # let(:page) { { 'release' => release.to_liquid } }
  let(:page) { { 'version' => version } }
  let(:environment) { { 'page' => page } }
  let(:registers) { { page: page, site: site } }
  let(:liquid_context) { Liquid::Context.new(environment, {}, registers) }

  shared_examples 'renders inc tag' do |golden_file, params = []|
    tag_params = ["some_value", *params].join(' ')

    it "renders correctly for parameters: #{tag_params}" do
      template = "{% inc #{tag_params} %}"
      processed = OpenStruct.new(content: template)
      Jekyll::Hooks.trigger(:pages, :pre_render, processed)

      output = Liquid::Template.parse(processed.content).render(liquid_context)
      GoldenFileManager.assert_output(output, golden_file, include_header: false)
    end
  end

  describe 'rendering tests' do
    [
      { golden_file: 'spec/fixtures/inc.golden' },
      {
        golden_file: 'spec/fixtures/inc-if-version.golden',
        parameters: ['if_version=gte:2.9.x'],
      },
      {
        golden_file: 'spec/fixtures/inc-if-version-not-met.golden',
        parameters: ['if_version=gte:2.10.x'],
      },
      {
        golden_file: 'spec/fixtures/inc-init-value.golden',
        parameters: ['init_value=5'],
      },
      {
        golden_file: 'spec/fixtures/inc-init-value-if-version.golden',
        parameters: %w[if_version=gte:2.9.x init_value=5],
      },
      {
        golden_file: 'spec/fixtures/inc-init-value-if-version-not-met.golden',
        parameters: %w[if_version=lte:2.8.x init_value=5],
      },
      {
        golden_file: 'spec/fixtures/inc-get-current.golden',
        parameters: ['get_current'],
      },
      {
        golden_file: 'spec/fixtures/inc-get-current-init-value.golden',
        parameters: %w[get_current init_value=22],
      },
      {
        golden_file: 'spec/fixtures/inc-get-current-init-value-if-version.golden',
        parameters: %w[get_current init_value=333 if_version=gte:2.9.x],
      },
      {
        golden_file: 'spec/fixtures/inc-get-current-init-value-if-version-not-met.golden',
        parameters: %w[get_current init_value=4444 if_version=gte:2.10.x],
      },
    ].each do |test_case|
      include_examples 'renders inc tag',
                       test_case[:golden_file],
                       test_case[:parameters]
    end
  end
end
