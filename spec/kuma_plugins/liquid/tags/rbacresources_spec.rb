# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::RbacResources do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  let(:release) do
    Jekyll::GeneratorSingleSource::Product::Release.new(
      {
        'release' => '2.11.x',
        'edition' => 'kuma'
      }
    )
  end

  let(:assets_path) { File.join(@tmpdir, 'app/assets') }

  before do
    FileUtils.mkdir_p(File.join(assets_path, release.to_s, 'raw'))
    FileUtils.cp('spec/fixtures/rbac.yaml', File.join(assets_path, release.to_s, 'raw', 'rbac.yaml'))
  end

  shared_examples 'rbac resources rendering' do |input_file, golden_file|
    it "renders correctly for #{input_file}" do
      site = Jekyll::Site.new(Jekyll.configuration(
                                {
                                  'mesh_raw_generated_paths' => [assets_path]
                                }
                              ))
      context = Liquid::Context.new({}, {}, {
                                      page: {
                                        'edition' => 'kuma',
                                        'release' => release
                                      },
                                      site: site
                                    })

      tag = "{% rbacresources filename=#{input_file} %}"
      template = Liquid::Template.parse(tag)
      output = template.render(context)

      GoldenFileManager.assert_output(output, golden_file, include_header: true)
    end
  end

  describe 'rendering test' do
    include_examples 'rbac resources rendering',
                     'rbac.yaml',
                     'spec/fixtures/rbac.golden.html'
  end
end
