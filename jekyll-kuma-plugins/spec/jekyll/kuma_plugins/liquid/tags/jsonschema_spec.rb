# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'tmpdir'

# rubocop:disable Metrics/BlockLength
RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::JsonSchema do
  subject(:tag) { described_class.send(:new, 'json_schema', markup, Liquid::ParseContext.new) }

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  let(:assets_path) { File.join(@tmpdir, 'app/assets') }
  let(:release) { '1.0' }
  let(:site) { Struct.new(:config).new({ 'mesh_raw_generated_paths' => [assets_path] }) }
  let(:context) { Liquid::Context.new({}, {}, { site: site, page: { 'release' => release } }) }

  before do
    FileUtils.mkdir_p(File.join(assets_path, release, 'raw', 'protos'))
    FileUtils.mkdir_p(File.join(assets_path, 'raw', 'protos'))
    File.write(File.join(assets_path, release, 'raw', 'protos', 'Mesh.json'), JSON.dump({ 'title' => 'Mesh', 'type' => 'object' }))
    File.write(File.join(assets_path, 'raw', 'protos', 'Mesh.json'), JSON.dump({ 'title' => 'Mesh', 'type' => 'object' }))
    File.write(File.join(@tmpdir, 'secret.json'), JSON.dump({ 'title' => 'Secret' }))
  end

  context 'with a valid proto schema' do
    let(:markup) { 'Mesh type=proto' }

    it 'renders the schema from the release raw directory' do
      expect(tag.render(context)).to include('const data = {"title":"Mesh","type":"object"};')
    end
  end

  context 'with a traversal attempt' do
    let(:markup) { '../../../../../secret type=proto' }

    it 'returns nil instead of reading outside the raw directory' do
      expect(tag.render(context)).to be_nil
    end
  end

  context 'with a blank release' do
    let(:release) { '' }
    let(:markup) { 'Mesh type=proto' }

    it 'loads the schema from the unversioned raw directory' do
      expect(tag.render(context)).to include('const data = {"title":"Mesh","type":"object"};')
    end
  end
end
# rubocop:enable Metrics/BlockLength
