# frozen_string_literal: true

require_relative '../../app/_plugins/generators/versions'

RSpec.describe Jekyll::Versions do
  subject(:generator) { described_class.new }

  let(:dev) { { 'edition' => 'kuma', 'release' => '2.15.x', 'label' => 'dev' } }
  let(:dev_nav) { { 'release' => '2.15.x', 'items' => [{ 'text' => 'Intro', 'url' => '/intro/' }] } }

  let(:data) do
    {
      'versions' => versions,
      'docs_nav_kuma_215x' => dev_nav
    }
  end
  let(:config) { { 'mesh_raw_generated_paths' => ['app/assets'] } }
  let(:site) { instance_double(Jekyll::Site, data: data, config: config) }

  let(:generator_config) { instance_double(Jekyll::GeneratorSingleSource::GeneratorConfig) }
  let(:nav_config) { instance_double(Jekyll::GeneratorSingleSource::DocNavConfig, config: {}, generate_pages: nil) }

  before do
    allow(Jekyll::GeneratorSingleSource::GeneratorConfig).to receive(:new).with(site).and_return(generator_config)
    allow(generator_config).to receive(:build_docs_nav).and_return(nav_config)
    # Leave Dir.exist? untouched for incidental callers; each context stubs only
    # the specific asset path it cares about.
    allow(Dir).to receive(:exist?).and_call_original
  end

  def run!
    generator.send(:generate_missing_version_navs, site)
  end

  def stub_assets(release, present)
    allow(Dir).to receive(:exist?).with(File.join('app/assets', release, 'raw')).and_return(present)
  end

  context 'when a non-dev version has no nav file of its own' do
    let(:versions) { [{ 'edition' => 'kuma', 'release' => '2.13.x' }, dev] }

    before { stub_assets('2.13.x', true) }

    it 'exposes the dev nav, retargeted at the version, so the sidebar renders' do
      run!

      fallback = data['docs_nav_kuma_213x']
      expect(fallback['items']).to eq(dev_nav['items'])
      expect(fallback['release']).to eq('2.13.x')
      expect(fallback).not_to be(dev_nav) # not the shared dev hash
    end

    it 'generates the version pages from the dev nav retargeted at the version' do
      run!

      expect(generator_config).to have_received(:build_docs_nav).with(edition: 'kuma', release: '2.15.x')
      expect(nav_config.config['release']).to eq('2.13.x')
      expect(nav_config).to have_received(:generate_pages)
    end
  end

  context 'when the missing version has no synced raw assets' do
    let(:versions) { [{ 'edition' => 'kuma', 'release' => '2.99.x' }, dev] }

    before { stub_assets('2.99.x', false) }

    it 'does not generate pages (keeps the old behaviour instead of breaking the build)' do
      run!

      expect(data).not_to have_key('docs_nav_kuma_299x')
      expect(nav_config).not_to have_received(:generate_pages)
    end
  end

  context 'with several versions missing their nav in one run' do
    let(:versions) do
      [{ 'edition' => 'kuma', 'release' => '2.12.x' }, { 'edition' => 'kuma', 'release' => '2.13.x' }, dev]
    end
    # release each DocNavConfig carried when generate_pages was called
    let(:generated_releases) { [] }

    before do
      stub_assets('2.12.x', true)
      stub_assets('2.13.x', true)
      # Fresh DocNavConfig per call (as the gem does), capturing the retargeted
      # release at generate_pages time to prove versions don't clobber each other.
      allow(generator_config).to receive(:build_docs_nav) do
        cfg = {}
        instance_double(Jekyll::GeneratorSingleSource::DocNavConfig, config: cfg).tap do |dbl|
          allow(dbl).to receive(:generate_pages) { generated_releases << cfg['release'] }
        end
      end
    end

    it 'retargets each version independently' do
      run!

      expect(data['docs_nav_kuma_212x']['release']).to eq('2.12.x')
      expect(data['docs_nav_kuma_213x']['release']).to eq('2.13.x')
      expect(generated_releases).to contain_exactly('2.12.x', '2.13.x')
    end
  end

  context 'when a version already has its own nav file' do
    let(:versions) { [{ 'edition' => 'kuma', 'release' => '2.13.x' }, dev] }

    before { data['docs_nav_kuma_213x'] = { 'release' => '2.13.x', 'items' => [] } }

    it 'leaves it untouched and generates nothing for it' do
      own_nav = data['docs_nav_kuma_213x']

      run!

      expect(data['docs_nav_kuma_213x']).to be(own_nav)
      expect(generator_config).not_to have_received(:build_docs_nav)
    end
  end

  context 'when there is no dev release' do
    let(:versions) { [{ 'edition' => 'kuma', 'release' => '2.13.x' }] }

    it 'does nothing' do
      run!

      expect(generator_config).not_to have_received(:build_docs_nav)
    end
  end
end
