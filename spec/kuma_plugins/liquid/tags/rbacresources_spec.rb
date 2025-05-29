RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::RbacResources do
  shared_examples 'rbac resources rendering' do |input_file, golden_file|
    it "renders correctly for #{input_file}" do
      site = Jekyll::Site.new(Jekyll.configuration({}))
      context = Liquid::Context.new({}, {}, {
        :page => {
          'edition' => 'kuma',
          'release' => Jekyll::GeneratorSingleSource::Product::Release.new({ 'release' => '2.11.x', 'edition' => 'kuma' })
        },
        :site => site
      })

      tag = "{% rbacresources filename=#{input_file} %}"
      template = Liquid::Template.parse(tag)
      output = template.render(context)

      GoldenFileManager.assert_output(output, golden_file, include_header: true)
    end
  end

  describe 'rendering test' do
    include_examples 'rbac resources rendering',
                     'spec/fixtures/rbac.yaml',
                     'spec/fixtures/rbac.golden.html'
  end
end
