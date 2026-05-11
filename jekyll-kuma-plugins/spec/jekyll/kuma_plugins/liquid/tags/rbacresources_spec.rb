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
  let(:versioned_release) { '1.0' }
  let(:release) { versioned_release }
  let(:site) { Struct.new(:config).new({ 'mesh_raw_generated_paths' => [assets_path] }) }
  let(:context) { Liquid::Context.new({}, {}, { site: site, page: { 'release' => release } }) }
  let(:template) { instance_double(Liquid::Template, render: 'rendered tabs') }
  let(:versioned_rbac_name) { 'kuma-control-plane-versioned' }
  let(:unversioned_rbac_name) { 'kuma-control-plane-unversioned' }
  let(:versioned_rbac_content) do
    <<~YAML
      ---
      kind: ClusterRole
      metadata:
        name: #{versioned_rbac_name}
    YAML
  end
  let(:unversioned_rbac_content) do
    <<~YAML
      ---
      kind: ClusterRole
      metadata:
        name: #{unversioned_rbac_name}
    YAML
  end

  before do
    FileUtils.mkdir_p(File.join(assets_path, versioned_release, 'raw'))
    FileUtils.mkdir_p(File.join(assets_path, 'raw'))
    File.write(
      File.join(assets_path, versioned_release, 'raw', 'rbac.yaml'),
      versioned_rbac_content
    )
    File.write(
      File.join(assets_path, 'raw', 'rbac.yaml'),
      unversioned_rbac_content
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
  end

  context 'with the default filename' do
    let(:markup) { '' }

    it 'reads RBAC resources from the release raw directory' do
      expect(Liquid::Template).to receive(:parse) do |output|
        expect(output).to include(versioned_rbac_name)
        expect(output).not_to include(unversioned_rbac_name)
        template
      end

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
      expect(Liquid::Template).to receive(:parse) do |output|
        expect(output).to include(unversioned_rbac_name)
        expect(output).not_to include(versioned_rbac_name)
        template
      end

      expect(tag.render(context)).to eq('rendered tabs')
    end
  end

  context 'with unsafe YAML object tags' do
    let(:markup) { '' }
    let(:versioned_rbac_content) { "--- !ruby/object:Object {}\n" }

    it 'rejects deserialization of Ruby objects' do
      expect { tag.render(context) }.to raise_error(Psych::DisallowedClass, /Object/)
    end
  end
end
# rubocop:enable Metrics/BlockLength
