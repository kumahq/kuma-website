# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# rubocop:disable Metrics/BlockLength
RSpec.describe Jekyll::KumaPlugins::Common::PathHelpers do
  subject(:helper) { Class.new { include Jekyll::KumaPlugins::Common::PathHelpers }.new }

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  let(:assets_path) { File.join(@tmpdir, 'app/assets') }
  let(:raw_path) { File.join(assets_path, '1.0', 'raw') }
  let(:allowed_path) { File.join(raw_path, 'allowed.txt') }
  let(:secret_path) { File.join(@tmpdir, 'secret.txt') }

  before do
    FileUtils.mkdir_p(raw_path)
    File.write(allowed_path, 'allowed')
    File.write(secret_path, 'secret')
  end

  describe '#build_relative_path' do
    it 'preserves nested paths inside the intended directory' do
      expect(helper.build_relative_path('1.0', 'raw', 'nested/allowed.txt')).to eq(File.join('1.0', 'raw', 'nested/allowed.txt'))
    end

    it 'rejects traversal segments' do
      expect do
        helper.build_relative_path('1.0', 'raw', '../../secret.txt')
      end.to raise_error(ArgumentError, /path traversal/)
    end
  end

  describe '#read_file' do
    it 'reads files inside the configured root' do
      expect(helper.read_file([assets_path], helper.build_relative_path('1.0', 'raw', 'allowed.txt'))).to eq('allowed')
    end

    it 'closes the file handle after reading' do
      file = File.new(allowed_path)
      allow(helper).to receive(:open_validated_file).and_return(file)

      expect(helper.read_file([assets_path], 'allowed.txt')).to eq('allowed')
      expect(file).to be_closed
    end

    it 'rejects symlink escapes inside the configured root' do
      linked_path = File.join(raw_path, 'linked.txt')
      File.symlink(secret_path, linked_path)
      allow(File).to receive(:new).and_call_original

      expect do
        helper.read_file([assets_path], helper.build_relative_path('1.0', 'raw', 'linked.txt'))
      end.to raise_error(ArgumentError, /path traversal/)
      expect(File).not_to have_received(:new).with(linked_path)
    end

    it 'memoizes canonical paths for configured roots' do
      realpath_calls = []
      allow(File).to receive(:realpath).and_wrap_original do |original, path|
        realpath_calls << path
        original.call(path)
      end

      2.times do
        helper.read_file([assets_path], helper.build_relative_path('1.0', 'raw', 'allowed.txt'))
      end

      expect(realpath_calls.count { |path| path == assets_path }).to eq(1)
    end
  end
end
# rubocop:enable Metrics/BlockLength
