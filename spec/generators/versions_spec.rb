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
    # By default every release has its raw assets present.
    allow(Dir).to receive(:exist?).and_return(true)
  end

  def run!
    generator.send(:generate_missing_version_navs, site)
  end

  context 'when a non-dev version has no nav file of its own' do
    let(:versions) { [{ 'edition' => 'kuma', 'release' => '2.13.x' }, dev] }

    it 'exposes the dev nav under the missing version so the sidebar renders' do
      run!

      expect(data['docs_nav_kuma_213x']).to be(dev_nav)
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

    before { allow(Dir).to receive(:exist?).with(File.join('app/assets', '2.99.x', 'raw')).and_return(false) }

    it 'does not generate pages (keeps the old behaviour instead of breaking the build)' do
      run!

      expect(data).not_to have_key('docs_nav_kuma_299x')
      expect(nav_config).not_to have_received(:generate_pages)
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
