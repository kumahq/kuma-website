# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# rubocop:disable Metrics/BlockLength
RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::Embed do
  subject(:tag) { described_class.send(:new, 'embed', markup, Liquid::ParseContext.new) }

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
    FileUtils.mkdir_p(File.join(assets_path, release, 'raw'))
    FileUtils.mkdir_p(File.join(assets_path, 'raw'))
    File.write(File.join(assets_path, release, 'raw', 'kuma-cp.yaml'), 'kind: Deployment')
    File.write(File.join(assets_path, 'raw', 'kuma-cp.yaml'), 'kind: Deployment')
    File.write(File.join(@tmpdir, 'secret.txt'), 'secret')
  end

  context 'with a valid versioned file' do
    let(:markup) { 'kuma-cp.yaml versioned' }

    it 'reads the file from the release raw directory' do
      expect(tag.render(context)).to eq('kind: Deployment')
    end
  end

  context 'with a traversal attempt' do
    let(:markup) { '../../../../secret.txt versioned' }

    it 'returns nil instead of reading outside the raw directory' do
      expect(tag.render(context)).to be_nil
    end
  end

  context 'with a blank release on a versioned tag' do
    let(:release) { '' }
    let(:markup) { 'kuma-cp.yaml versioned' }

    it 'falls back to the unversioned raw directory' do
      expect(tag.render(context)).to eq('kind: Deployment')
    end
  end
end
# rubocop:enable Metrics/BlockLength
