# frozen_string_literal: true

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::SchemaViewer do
  shared_examples 'schema viewer rendering' do |schema_name, schema_type, golden_file|
    it "renders correctly for #{schema_name} type=#{schema_type}" do
      site = Jekyll::Site.new(Jekyll.configuration({
                                                     mesh_raw_generated_paths: ['app/assets']
                                                   }))
      context = Liquid::Context.new({}, {}, {
                                      page: {
                                        'edition' => 'kuma',
                                        'release' => Jekyll::GeneratorSingleSource::Product::Release.new({
                                                                                                           'release' => 'dev',
                                                                                                           'edition' => 'kuma'
                                                                                                         })
                                      },
                                      site: site
                                    })

      tag = "{% schema_viewer #{schema_name} type=#{schema_type} %}"
      template = Liquid::Template.parse(tag)
      output = template.render(context)

      GoldenFileManager.assert_output(output, golden_file, include_header: true)
    end
  end

  describe 'rendering tests' do
    include_examples 'schema viewer rendering',
                     'Mesh',
                     'proto',
                     'spec/fixtures/schema-viewer-mesh.golden.html'

    include_examples 'schema viewer rendering',
                     'MeshTimeouts',
                     'policy',
                     'spec/fixtures/schema-viewer-meshtimeouts.golden.html'
  end

  describe 'error handling' do
    it 'returns error div for missing schema' do
      site = Jekyll::Site.new(Jekyll.configuration({
                                                     mesh_raw_generated_paths: ['app/assets']
                                                   }))
      context = Liquid::Context.new({}, {}, {
                                      page: {
                                        'edition' => 'kuma',
                                        'release' => Jekyll::GeneratorSingleSource::Product::Release.new({
                                                                                                           'release' => 'dev',
                                                                                                           'edition' => 'kuma'
                                                                                                         })
                                      },
                                      site: site
                                    })

      tag = '{% schema_viewer NonExistentSchema type=proto %}'
      template = Liquid::Template.parse(tag)
      output = template.render(context)

      expect(output).to include('schema-viewer-error')
      expect(output).to include('Error loading schema')
    end
  end
end
