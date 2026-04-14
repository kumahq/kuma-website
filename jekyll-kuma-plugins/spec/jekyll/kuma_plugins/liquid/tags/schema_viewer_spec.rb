# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'tmpdir'

# rubocop:disable Metrics/BlockLength
RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::SchemaViewer do
  subject(:tag) { described_class.send(:new, 'schema_viewer', markup, Liquid::ParseContext.new) }

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  let(:assets_path) { File.join(@tmpdir, 'app/assets') }
  let(:versioned_release) { '1.0' }
  let(:release) { versioned_release }
  let(:site) { Struct.new(:config).new({ 'mesh_raw_generated_paths' => [assets_path] }) }
  let(:context) { Liquid::Context.new({}, {}, { site: site, page: { 'release' => release } }) }
  let(:versioned_schema) do
    {
      'properties' => {
        'versioned' => {
          'type' => 'string',
          'description' => 'Versioned schema'
        }
      }
    }
  end
  let(:unversioned_schema) do
    {
      'properties' => {
        'fallback' => {
          'type' => 'string',
          'description' => 'Fallback schema'
        }
      }
    }
  end

  before do
    FileUtils.mkdir_p(File.join(assets_path, versioned_release, 'raw', 'protos'))
    FileUtils.mkdir_p(File.join(assets_path, 'raw', 'protos'))
    File.write(
      File.join(assets_path, versioned_release, 'raw', 'protos', 'Mesh.json'),
      JSON.dump(versioned_schema)
    )
    File.write(
      File.join(assets_path, 'raw', 'protos', 'Mesh.json'),
      JSON.dump(unversioned_schema)
    )
    File.write(
      File.join(@tmpdir, 'secret.json'),
      JSON.dump({
                  'properties' => {
                    'stolen' => {
                      'type' => 'string'
                    }
                  }
                })
    )
  end

  context 'with a valid proto schema' do
    let(:markup) { 'Mesh type=proto' }

    it 'renders schema properties from the release raw directory' do
      output = tag.render(context)

      expect(output).to include('schema-viewer__name">versioned<')
      expect(output).not_to include('schema-viewer__name">fallback<')
    end
  end

  context 'with a traversal attempt' do
    let(:markup) { '../../../../../secret type=proto' }

    it 'renders an error instead of reading outside the raw directory' do
      output = tag.render(context)

      expect(output).to include('Error loading schema')
      expect(output).not_to include('stolen')
      expect(output).to include('path traversal')
    end
  end

  context 'with a blank release' do
    let(:release) { '' }
    let(:markup) { 'Mesh type=proto' }

    it 'loads the schema from the unversioned raw directory' do
      output = tag.render(context)

      expect(output).to include('schema-viewer__name">fallback<')
      expect(output).not_to include('schema-viewer__name">versioned<')
    end
  end
end
# rubocop:enable Metrics/BlockLength
