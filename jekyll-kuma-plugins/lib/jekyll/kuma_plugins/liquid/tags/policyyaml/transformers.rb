# frozen_string_literal: true

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        module PolicyYamlTransformers
          # Base class for YAML node transformers
          class BaseTransformer
            def matches?(_path, _node, _context)
              raise NotImplementedError, 'Subclasses must implement #matches?'
            end

            def transform(_node, _context)
              raise NotImplementedError, 'Subclasses must implement #transform'
            end

            private

            def deep_copy(original)
              Marshal.load(Marshal.dump(original))
            end
          end

          # Transforms MeshService targetRef in spec.to.targetRef
          class MeshServiceTargetRefTransformer < BaseTransformer
            def matches?(path, node, _context)
              path == %w[spec to targetRef] && node['kind'] == 'MeshService'
            end

            def transform(node, context)
              case context[:env]
              when :kubernetes
                transform_kubernetes(node, context)
              when :universal
                transform_universal(node, context)
              end
            end

            private

            def transform_kubernetes(node, context)
              if context[:legacy_output]
                {
                  'kind' => 'MeshService',
                  'name' => [node['name'], node['namespace'], 'svc', node['_port']].compact.join('_')
                }
              else
                {
                  'kind' => 'MeshService',
                  'name' => node['name'],
                  'namespace' => node['namespace'],
                  'sectionName' => node['sectionName']
                }
              end
            end

            def transform_universal(node, context)
              if context[:legacy_output]
                {
                  'kind' => 'MeshService',
                  'name' => node['name']
                }
              else
                {
                  'kind' => 'MeshService',
                  'name' => node['name'],
                  'sectionName' => node['sectionName']
                }
              end
            end
          end

          # Transforms MeshService backendRef in rules
          class MeshServiceBackendRefTransformer < BaseTransformer
            MATCHING_PATHS = [
              %w[spec to rules default backendRefs],
              %w[spec to rules default filters requestMirror backendRef]
            ].freeze

            def matches?(path, node, _context)
              MATCHING_PATHS.include?(path) && node['kind'] == 'MeshService'
            end

            def transform(node, context)
              case context[:env]
              when :kubernetes
                transform_kubernetes(node, context)
              when :universal
                transform_universal(node, context)
              end
            end

            private

            def transform_kubernetes(node, context)
              if context[:legacy_output]
                build_legacy_kubernetes_ref(node)
              else
                build_modern_kubernetes_ref(node)
              end
            end

            def build_legacy_kubernetes_ref(node)
              {
                'kind' => 'MeshService',
                'name' => [node['name'], node['namespace'], 'svc', node['port']].compact.join('_')
              }.tap do |hash|
                hash['kind'] = 'MeshServiceSubset' if node.key?('_version')
                hash['weight'] = node['weight'] if node.key?('weight')
                hash['tags'] = { 'version' => node['_version'] } if node.key?('_version')
              end
            end

            def build_modern_kubernetes_ref(node)
              {
                'kind' => 'MeshService',
                'name' => node['name'],
                'namespace' => node['namespace'],
                'port' => node['port']
              }.tap do |hash|
                hash['weight'] = node['weight'] if node.key?('weight')
                hash['name'] = "#{node['name']}-#{node['_version']}" if node.key?('_version')
              end
            end

            def transform_universal(node, context)
              if context[:legacy_output]
                build_legacy_universal_ref(node)
              else
                build_modern_universal_ref(node)
              end
            end

            def build_legacy_universal_ref(node)
              {
                'kind' => 'MeshService',
                'name' => node['name']
              }.tap do |hash|
                hash['kind'] = 'MeshServiceSubset' if node.key?('_version')
                hash['weight'] = node['weight'] if node.key?('weight')
                hash['tags'] = { 'version' => node['_version'] } if node.key?('_version')
              end
            end

            def build_modern_universal_ref(node)
              {
                'kind' => 'MeshService',
                'name' => node['name'],
                'port' => node['port']
              }.tap do |hash|
                hash['weight'] = node['weight'] if node.key?('weight')
                hash['name'] = "#{node['name']}-#{node['_version']}" if node.key?('_version')
              end
            end
          end

          # Transforms nodes with name_uni/name_kube fields
          class NameTransformer < BaseTransformer
            def matches?(_path, node, _context)
              node.is_a?(Hash) && (node.key?('name_uni') || node.key?('name_kube'))
            end

            def transform(node, context)
              node_copy = deep_copy(node)
              node_copy.delete('name_uni')
              node_copy.delete('name_kube')

              case context[:env]
              when :kubernetes
                node_copy['name'] = node['name_kube']
              when :universal
                node_copy['name'] = node['name_uni']
              end

              node_copy
            end
          end

          # Transforms root node for Kubernetes format
          class KubernetesRootTransformer < BaseTransformer
            def initialize(api_version)
              super()
              @api_version = api_version
            end

            def matches?(path, _node, context)
              path == [] && context[:env] == :kubernetes
            end

            def transform(node, context)
              {
                'apiVersion' => @api_version,
                'kind' => node['type'],
                'metadata' => build_metadata(node, context),
                'spec' => node['spec']
              }
            end

            private

            def build_metadata(node, context)
              metadata = {
                'name' => node['name'],
                'namespace' => context[:namespace]
              }
              metadata['labels'] = build_labels(node) if node['labels'] || node['mesh']
              metadata
            end

            def build_labels(node)
              labels = node['labels'] || {}
              labels['kuma.io/mesh'] = node['mesh'] if node['mesh']
              labels
            end
          end
        end
      end
    end
  end
end
