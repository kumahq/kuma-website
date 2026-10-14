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

  context 'when the dev release has its own nav' do
    let(:versions) { [dev] }

    it 'leaves it alone' do
      run!

      expect(data['docs_nav_kuma_215x']).to be(dev_nav)
      expect(generator_config).not_to have_received(:build_docs_nav)
    end
  end

  context 'when the dev release has no nav of its own' do
    let(:dev) { { 'edition' => 'kuma', 'release' => '3.0.x', 'label' => 'dev' } }
    let(:released) { { 'edition' => 'kuma', 'release' => '2.14.x', 'version' => '2.14.6' } }
    let(:released_nav) { { 'release' => '2.14.x', 'items' => [{ 'text' => 'Intro', 'url' => '/intro/' }] } }
    let(:versions) { [released, dev] }
    let(:data) { { 'versions' => versions, 'docs_nav_kuma_214x' => released_nav } }

    it 'generates the dev pages and sidebar from the newest released nav' do
      run!

      expect(generator_config).to have_received(:build_docs_nav).with(edition: 'kuma', release: '2.14.x')
      expect(nav_config.config['release']).to eq('3.0.x')
      expect(nav_config).to have_received(:generate_pages)
    end

    it 'exposes the borrowed nav under the dev release, retargeted at it' do
      run!

      borrowed = data['docs_nav_kuma_30x']
      expect(borrowed['release']).to eq('3.0.x')
      expect(borrowed['items']).to eq(released_nav['items'])
      expect(borrowed).not_to be(released_nav)
    end

    it 'borrows for versions that have no nav of their own either' do
      stub_assets('2.13.x', true)
      versions.unshift({ 'edition' => 'kuma', 'release' => '2.13.x', 'version' => '2.13.11' })

      run!

      expect(data['docs_nav_kuma_213x']['release']).to eq('2.13.x')
      expect(data['docs_nav_kuma_213x']['items']).to eq(released_nav['items'])
    end
  end

  context 'when the dev release has no nav and no released nav to borrow' do
    let(:dev) { { 'edition' => 'kuma', 'release' => '3.0.x', 'label' => 'dev' } }
    let(:versions) { [dev] }
    let(:data) { { 'versions' => versions } }

    it 'generates nothing for it' do
      run!

      expect(generator_config).not_to have_received(:build_docs_nav)
      expect(data).not_to have_key('docs_nav_kuma_30x')
    end
  end

  describe '#generate' do
    let(:release) do
      instance_double(Jekyll::GeneratorSingleSource::Product::Release,
                      value: '3.0.x', default_version: 'preview', to_liquid: 'dev', to_h: {})
    end
    let(:edition_double) do
      instance_double(Jekyll::GeneratorSingleSource::Product::Edition,
                      releases: [release], latest_release: release)
    end
    let(:page) { Struct.new(:url, :data).new('/docs/3.0.x/introduction/overview/', {}) }
    let(:versions) { [{ 'edition' => 'kuma', 'release' => '2.14.x', 'version' => '2.14.6', 'latest' => true }, dev] }
    let(:data) do
      {
        'versions' => versions,
        'docs_nav_kuma_214x' => { 'release' => '2.14.x', 'items' => [] },
        'docs_nav_kuma_215x' => dev_nav
      }
    end

    before do
      allow(generator).to receive(:edition).and_return(edition_double)
      allow(generator).to receive(:release_for).and_return(release)
      allow(site).to receive(:pages).and_return([page])
    end

    it 'keeps the empty nav_items default when the release has no nav data' do
      generator.generate(site)

      expect(page.data['nav_items']).to eq({})
      expect(generator_config).not_to have_received(:build_docs_nav)
    end

    it 'uses the release sidebar entries when it has nav data' do
      data['docs_nav_kuma_30x'] = dev_nav.merge('release' => '3.0.x')

      generator.generate(site)

      expect(page.data['nav_items']).to eq(dev_nav['items'])
    end
  end
end
