# frozen_string_literal: true

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::Inc do
  let(:version) { '2.9.1' }
  let(:release) { Jekyll::GeneratorSingleSource::Product::Release.new({ 'release' => version }) }
  let(:page) { { 'release' => release.to_liquid } }
  let(:environment) { { 'page' => page } }
  let(:registers) { { page: page } }
  let(:liquid_context) { Liquid::Context.new(environment, {}, registers) }

  shared_examples 'renders inc tag' do |if_version, params = [], golden_file|
    tag_params = [%W[some_value if_version='#{if_version}'], *params.to_a].join(' ')

    it "renders correctly for: {% inc #{tag_params} %} in context" do
      template = <<~LIQUID
        {% assign docs = "/docs/" | append: page.release %}
        {% assign link = docs | append: "/networking/transparent-proxying/" %}

        {% if_version #{if_version} %}
        ## Step {% inc #{tag_params} %}: Ensure the correct version of iptables.
        {% endif_version %}

        To prepare your service environment and start the data plane proxy,
        follow the [Installing Transparent Proxy]({{ link }})
        guide up to [Step {% inc #{tag_params} %}: Install the Transparent Proxy]({{ link }}).
      LIQUID

      processed = OpenStruct.new(content: template)
      Jekyll::Hooks.trigger(:pages, :pre_render, processed)

      output = Liquid::Template.parse(processed.content).render(liquid_context)

      GoldenFileManager.assert_output(output, golden_file, include_header: false)
    end
  end

  describe 'inc tag rendering' do
    [
      {
        if_version: 'gte:2.9.x',
        golden_file: 'spec/fixtures/inc-if-version.golden.html'
      },
      {
        if_version: 'lte:2.8.x',
        golden_file: 'spec/fixtures/inc-if-version-not-met.golden.html'
      },
      {
        if_version: 'gte:2.9.x',
        params: ['init_value=5'],
        golden_file: 'spec/fixtures/inc-if-version-init-value.golden.html'
      },
      {
        if_version: 'lte:2.8.x',
        params: ['init_value=5'],
        golden_file: 'spec/fixtures/inc-if-version-not-met-init-value.golden.html'
      },
      {
        if_version: 'gte:2.9.x',
        params: ['get_current'],
        golden_file: 'spec/fixtures/inc-if-version-get-current.golden.html'
      },
      {
        if_version: 'lte:2.8.x',
        params: ['get_current'],
        golden_file: 'spec/fixtures/inc-if-version-not-met-get-current.golden.html'
      },
      {
        if_version: 'gte:2.9.x',
        params: %w[get_current init_value=5],
        golden_file: 'spec/fixtures/inc-if-version-get-current-init-value.golden.html'
      },
      {
        if_version: 'lte:2.8.x',
        params: %w[get_current init_value=5],
        golden_file: 'spec/fixtures/inc-if-version-not-met-get-current-init-value.golden.html'
      }
    ].each do |test_case|
      include_examples 'renders inc tag', test_case[:if_version],
                       test_case[:params],
                       test_case[:golden_file]
    end
  end
end
