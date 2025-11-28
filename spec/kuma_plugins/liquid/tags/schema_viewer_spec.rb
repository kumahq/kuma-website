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

    include_examples 'schema viewer rendering',
                     'MeshCircuitBreakers',
                     'policy',
                     'spec/fixtures/schema-viewer-meshcircuitbreakers.golden.html'
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

  describe 'parameter filtering' do
    it 'parses filter parameters with dot notation' do
      tag = Liquid::Template.parse('{% schema_viewer TestSchema targetRef.kind=Mesh,MeshService %}').root.nodelist.first
      filters = tag.instance_variable_get(:@filters)
      expect(filters).to have_key('targetRef.kind')
      expect(filters['targetRef.kind']).to eq(%w[Mesh MeshService])
    end

    it 'handles parameter values with multiple = signs' do
      tag = Liquid::Template.parse('{% schema_viewer TestSchema key=value=with=equals %}').root.nodelist.first
      filters = tag.instance_variable_get(:@filters)
      expect(filters).to be_empty
    end

    it 'separates filter parameters from regular parameters' do
      tag = Liquid::Template.parse('{% schema_viewer TestSchema type=policy targetRef.kind=Mesh %}').root.nodelist.first
      filters = tag.instance_variable_get(:@filters)
      expect(filters).to have_key('targetRef.kind')
      expect(filters['targetRef.kind']).to eq(['Mesh'])
    end

    it 'handles comma-separated values without spaces' do
      tag = Liquid::Template.parse('{% schema_viewer TestSchema path.field=Value1,Value2,Value3 %}').root.nodelist.first
      filters = tag.instance_variable_get(:@filters)
      expect(filters['path.field']).to eq(%w[Value1 Value2 Value3])
    end

    it 'strips whitespace from comma-separated values' do
      tag = Liquid::Template.parse('{% schema_viewer TestSchema path.field=Value1,Value2,Value3 %}').root.nodelist.first
      filters = tag.instance_variable_get(:@filters)
      filters['path.field'].each do |value|
        expect(value).not_to match(/^\s|\s$/)
      end
    end

    it 'parses exclude parameter' do
      tag = Liquid::Template.parse('{% schema_viewer TestSchema exclude=from %}').root.nodelist.first
      excluded_fields = tag.instance_variable_get(:@excluded_fields)
      expect(excluded_fields).to eq(['from'])
    end

    it 'parses exclude parameter with multiple fields' do
      tag = Liquid::Template.parse('{% schema_viewer TestSchema exclude=from,rules %}').root.nodelist.first
      excluded_fields = tag.instance_variable_get(:@excluded_fields)
      expect(excluded_fields).to eq(%w[from rules])
    end

    it 'handles multiple excluded fields' do
      tag = Liquid::Template.parse('{% schema_viewer TestSchema exclude=from,rules,to %}').root.nodelist.first
      excluded_fields = tag.instance_variable_get(:@excluded_fields)
      expect(excluded_fields).to eq(%w[from rules to])
    end
  end

  describe Jekyll::KumaPlugins::Liquid::Tags::SchemaViewerComponents::Renderer do
    describe '#apply_filters' do
      let(:schema) do
        {
          'enum' => %w[Mesh MeshService MeshGateway],
          'oneOf' => [
            { 'enum' => ['Mesh'] },
            { 'enum' => ['MeshService'] }
          ],
          'anyOf' => [
            { 'const' => 'Value1' },
            { 'const' => 'Value2' }
          ]
        }
      end

      it 'filters enum values to allowed list' do
        filters = { 'targetRef.kind' => %w[Mesh MeshService] }
        renderer = described_class.new({ 'properties' => {} }, filters)
        filtered = renderer.send(:apply_filters, schema, %w[targetRef kind])

        expect(filtered['enum']).to eq(%w[Mesh MeshService])
        expect(filtered['enum']).not_to include('MeshGateway')
      end

      it 'filters oneOf alternatives based on enum values' do
        filters = { 'targetRef.kind' => ['Mesh'] }
        renderer = described_class.new({ 'properties' => {} }, filters)
        filtered = renderer.send(:apply_filters, schema, %w[targetRef kind])

        expect(filtered['oneOf'].length).to eq(1)
        expect(filtered['oneOf'][0]['enum']).to eq(['Mesh'])
      end

      it 'filters anyOf alternatives based on const values' do
        filters = { 'field.path' => ['Value1'] }
        renderer = described_class.new({ 'properties' => {} }, filters)
        filtered = renderer.send(:apply_filters, schema, %w[field path])

        expect(filtered['anyOf'].length).to eq(1)
        expect(filtered['anyOf'][0]['const']).to eq('Value1')
      end

      it 'deletes empty oneOf after filtering' do
        filters = { 'targetRef.kind' => ['NonExistent'] }
        renderer = described_class.new({ 'properties' => {} }, filters)
        filtered = renderer.send(:apply_filters, schema, %w[targetRef kind])

        expect(filtered).not_to have_key('oneOf')
      end

      it 'deletes empty anyOf after filtering' do
        filters = { 'field.path' => ['NonExistent'] }
        renderer = described_class.new({ 'properties' => {} }, filters)
        filtered = renderer.send(:apply_filters, schema, %w[field path])

        expect(filtered).not_to have_key('anyOf')
      end

      it 'returns unchanged schema when no filters match path' do
        filters = { 'other.path' => ['Value'] }
        renderer = described_class.new({ 'properties' => {} }, filters)
        filtered = renderer.send(:apply_filters, schema, %w[targetRef kind])

        expect(filtered['enum']).to eq(schema['enum'])
        expect(filtered['oneOf']).to eq(schema['oneOf'])
      end

      it 'returns unchanged schema when filters are empty' do
        renderer = described_class.new({ 'properties' => {} }, {})
        filtered = renderer.send(:apply_filters, schema, %w[targetRef kind])

        expect(filtered).to eq(schema)
      end

      it 'does not mutate original schema' do
        original_enum = schema['enum'].dup
        filters = { 'targetRef.kind' => ['Mesh'] }
        renderer = described_class.new({ 'properties' => {} }, filters)
        renderer.send(:apply_filters, schema, %w[targetRef kind])

        expect(schema['enum']).to eq(original_enum)
      end
    end

    describe '#filter_alternatives' do
      let(:renderer) { described_class.new({ 'properties' => {} }, {}) }

      it 'filters alternatives with matching enum values' do
        alternatives = [
          { 'enum' => %w[Mesh MeshService] },
          { 'enum' => ['MeshGateway'] }
        ]
        allowed = ['Mesh']
        result = renderer.send(:filter_alternatives, alternatives, allowed)

        expect(result.length).to eq(1)
        expect(result[0]['enum']).to include('Mesh')
      end

      it 'filters alternatives with matching const values' do
        alternatives = [
          { 'const' => 'Value1' },
          { 'const' => 'Value2' }
        ]
        allowed = ['Value1']
        result = renderer.send(:filter_alternatives, alternatives, allowed)

        expect(result.length).to eq(1)
        expect(result[0]['const']).to eq('Value1')
      end

      it 'keeps alternatives without enum or const' do
        alternatives = [
          { 'type' => 'string' },
          { 'enum' => ['NotAllowed'] }
        ]
        allowed = ['Allowed']
        result = renderer.send(:filter_alternatives, alternatives, allowed)

        expect(result.length).to eq(1)
        expect(result[0]['type']).to eq('string')
      end

      it 'handles empty enum arrays' do
        alternatives = [{ 'enum' => [] }]
        allowed = ['Value']
        result = renderer.send(:filter_alternatives, alternatives, allowed)

        expect(result).to be_empty
      end

      it 'excludes alternatives with non-matching const when const is present' do
        alternatives = [
          { 'const' => 'NotMatching' },
          { 'const' => 'Value1' }
        ]
        allowed = ['Value1']
        result = renderer.send(:filter_alternatives, alternatives, allowed)

        expect(result.length).to eq(1)
        expect(result[0]['const']).to eq('Value1')
      end
    end
  end
end
