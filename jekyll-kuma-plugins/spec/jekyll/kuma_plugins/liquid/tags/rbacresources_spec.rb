# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# rubocop:disable Metrics/BlockLength
RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::RbacResources do
  subject(:tag) { described_class.send(:new, 'rbacresources', markup, Liquid::ParseContext.new) }

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
  let(:template) { instance_double(Liquid::Template, render: 'rendered tabs') }

  before do
    FileUtils.mkdir_p(File.join(assets_path, release, 'raw'))
    FileUtils.mkdir_p(File.join(assets_path, 'raw'))
    File.write(
      File.join(assets_path, release, 'raw', 'rbac.yaml'),
      <<~YAML
        ---
        kind: ClusterRole
        metadata:
          name: kuma-control-plane
      YAML
    )
    File.write(
      File.join(assets_path, 'raw', 'rbac.yaml'),
      <<~YAML
        ---
        kind: ClusterRole
        metadata:
          name: kuma-control-plane
      YAML
    )
    File.write(
      File.join(@tmpdir, 'secret.yaml'),
      <<~YAML
        ---
        kind: Secret
        metadata:
          name: top-secret
      YAML
    )
    allow(Liquid::Template).to receive(:parse).and_return(template)
  end

  context 'with the default filename' do
    let(:markup) { '' }

    it 'reads RBAC resources from the release raw directory' do
      expect(tag.render(context)).to eq('rendered tabs')
    end
  end

  context 'with a traversal attempt' do
    let(:markup) { 'filename=../../../../secret.yaml' }

    it 'raises instead of reading outside the raw directory' do
      expect { tag.render(context) }.to raise_error(ArgumentError, /path traversal/)
    end
  end

  context 'with a blank release' do
    let(:release) { '' }
    let(:markup) { '' }

    it 'loads the default RBAC file from the unversioned raw directory' do
      expect(tag.render(context)).to eq('rendered tabs')
    end
  end
end
# rubocop:enable Metrics/BlockLength
