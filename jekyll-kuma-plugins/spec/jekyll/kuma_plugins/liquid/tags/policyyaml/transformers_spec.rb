# frozen_string_literal: true

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYamlTransformers do
  describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYamlTransformers::MeshServiceTargetRefTransformer do
    subject { described_class.new }

    describe '#matches?' do
      it 'matches spec.to.targetRef with MeshService kind' do
        expect(subject.matches?(%w[spec to targetRef], { 'kind' => 'MeshService' }, {})).to be true
      end

      it 'does not match wrong path' do
        expect(subject.matches?(%w[spec from], { 'kind' => 'MeshService' }, {})).to be false
      end

      it 'does not match wrong kind' do
        expect(subject.matches?(%w[spec to targetRef], { 'kind' => 'Mesh' }, {})).to be false
      end
    end

    describe '#transform' do
      let(:node) { { 'kind' => 'MeshService', 'name' => 'backend', 'namespace' => 'default', 'sectionName' => 'http' } }

      context 'kubernetes legacy' do
        let(:context) { { env: :kubernetes, legacy_output: true } }

        it 'joins name parts with underscore' do
          node_with_port = node.merge('_port' => '8080')
          result = subject.transform(node_with_port, context)
          expect(result['name']).to eq('backend_default_svc_8080')
        end
      end

      context 'kubernetes modern' do
        let(:context) { { env: :kubernetes, legacy_output: false } }

        it 'keeps separate fields' do
          result = subject.transform(node, context)
          expect(result).to eq({
                                 'kind' => 'MeshService',
                                 'name' => 'backend',
                                 'namespace' => 'default',
                                 'sectionName' => 'http'
                               })
        end
      end

      context 'universal legacy' do
        let(:context) { { env: :universal, legacy_output: true } }

        it 'returns only name' do
          result = subject.transform(node, context)
          expect(result).to eq({ 'kind' => 'MeshService', 'name' => 'backend' })
        end
      end

      context 'universal modern' do
        let(:context) { { env: :universal, legacy_output: false } }

        it 'includes sectionName' do
          result = subject.transform(node, context)
          expect(result).to eq({
                                 'kind' => 'MeshService',
                                 'name' => 'backend',
                                 'sectionName' => 'http'
                               })
        end
      end
    end
  end

  describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYamlTransformers::MeshServiceBackendRefTransformer do
    subject { described_class.new }

    describe '#matches?' do
      it 'matches backendRefs path with MeshService' do
        expect(subject.matches?(%w[spec to rules default backendRefs], { 'kind' => 'MeshService' }, {})).to be true
      end

      it 'matches requestMirror backendRef path' do
        path = %w[spec to rules default filters requestMirror backendRef]
        expect(subject.matches?(path, { 'kind' => 'MeshService' }, {})).to be true
      end

      it 'does not match wrong kind' do
        expect(subject.matches?(%w[spec to rules default backendRefs], { 'kind' => 'Mesh' }, {})).to be false
      end
    end

    describe '#transform' do
      let(:node) { { 'kind' => 'MeshService', 'name' => 'backend', 'namespace' => 'default', 'port' => 8080 } }

      context 'kubernetes legacy with version' do
        let(:context) { { env: :kubernetes, legacy_output: true } }

        it 'sets MeshServiceSubset kind and tags' do
          node_with_version = node.merge('_version' => 'v1', 'weight' => 90)
          result = subject.transform(node_with_version, context)
          expect(result['kind']).to eq('MeshServiceSubset')
          expect(result['tags']).to eq({ 'version' => 'v1' })
          expect(result['weight']).to eq(90)
        end
      end

      context 'kubernetes modern with version' do
        let(:context) { { env: :kubernetes, legacy_output: false } }

        it 'appends version to name' do
          node_with_version = node.merge('_version' => 'v1')
          result = subject.transform(node_with_version, context)
          expect(result['name']).to eq('backend-v1')
        end
      end

      context 'universal legacy' do
        let(:context) { { env: :universal, legacy_output: true } }

        it 'returns basic ref' do
          result = subject.transform(node, context)
          expect(result).to eq({ 'kind' => 'MeshService', 'name' => 'backend' })
        end
      end

      context 'universal modern' do
        let(:context) { { env: :universal, legacy_output: false } }

        it 'includes port' do
          result = subject.transform(node, context)
          expect(result['port']).to eq(8080)
        end
      end
    end
  end

  describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYamlTransformers::NameTransformer do
    subject { described_class.new }

    describe '#matches?' do
      it 'matches node with name_uni' do
        expect(subject.matches?([], { 'name_uni' => 'test' }, {})).to be true
      end

      it 'matches node with name_kube' do
        expect(subject.matches?([], { 'name_kube' => 'test' }, {})).to be true
      end

      it 'does not match node without name fields' do
        expect(subject.matches?([], { 'name' => 'test' }, {})).to be false
      end

      it 'does not match non-hash' do
        expect(subject.matches?([], 'string', {})).to be false
      end
    end

    describe '#transform' do
      let(:node) { { 'name_uni' => 'uni-name', 'name_kube' => 'kube-name', 'other' => 'value' } }

      it 'uses name_kube for kubernetes' do
        result = subject.transform(node, { env: :kubernetes })
        expect(result['name']).to eq('kube-name')
        expect(result).not_to have_key('name_uni')
        expect(result).not_to have_key('name_kube')
      end

      it 'uses name_uni for universal' do
        result = subject.transform(node, { env: :universal })
        expect(result['name']).to eq('uni-name')
      end

      it 'preserves other fields' do
        result = subject.transform(node, { env: :kubernetes })
        expect(result['other']).to eq('value')
      end

      it 'does not mutate original node' do
        original = node.dup
        subject.transform(node, { env: :kubernetes })
        expect(node).to eq(original)
      end
    end
  end

  describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYamlTransformers::KubernetesRootTransformer do
    subject { described_class.new('kuma.io/v1alpha1') }

    describe '#matches?' do
      it 'matches root path with kubernetes env' do
        expect(subject.matches?([], {}, { env: :kubernetes })).to be true
      end

      it 'does not match non-root path' do
        expect(subject.matches?(%w[spec], {}, { env: :kubernetes })).to be false
      end

      it 'does not match universal env' do
        expect(subject.matches?([], {}, { env: :universal })).to be false
      end
    end

    describe '#transform' do
      let(:node) do
        {
          'type' => 'MeshTimeout',
          'name' => 'my-timeout',
          'mesh' => 'default',
          'spec' => { 'targetRef' => {} }
        }
      end
      let(:context) { { env: :kubernetes, namespace: 'kuma-system' } }

      it 'creates kubernetes resource structure' do
        result = subject.transform(node, context)
        expect(result['apiVersion']).to eq('kuma.io/v1alpha1')
        expect(result['kind']).to eq('MeshTimeout')
        expect(result['metadata']['name']).to eq('my-timeout')
        expect(result['metadata']['namespace']).to eq('kuma-system')
        expect(result['spec']).to eq({ 'targetRef' => {} })
      end

      it 'adds mesh label' do
        result = subject.transform(node, context)
        expect(result['metadata']['labels']['kuma.io/mesh']).to eq('default')
      end

      it 'preserves existing labels' do
        node_with_labels = node.merge('labels' => { 'app' => 'test' })
        result = subject.transform(node_with_labels, context)
        expect(result['metadata']['labels']['app']).to eq('test')
        expect(result['metadata']['labels']['kuma.io/mesh']).to eq('default')
      end

      it 'does not mutate original labels' do
        original_labels = { 'app' => 'test' }
        node_with_labels = node.merge('labels' => original_labels)
        subject.transform(node_with_labels, context)
        expect(original_labels).not_to have_key('kuma.io/mesh')
      end

      it 'omits labels when neither labels nor mesh present' do
        node_without_mesh = node.except('mesh')
        result = subject.transform(node_without_mesh, context)
        expect(result['metadata']).not_to have_key('labels')
      end
    end
  end
end
