# frozen_string_literal: true

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        # Generates Terraform HCL from YAML policy data
        class TerraformGenerator
          def generate(yaml_data)
            type = yaml_data['type']
            name = yaml_data['name']
            resource_name = "konnect_#{snake_case(type)}"

            build_resource(resource_name, name, yaml_data)
          end

          private

          def build_resource(resource_name, name, yaml_data)
            terraform = "resource \"#{resource_name}\" \"#{name.gsub('-', '_')}\" {\n"
            terraform += resource_prefix
            yaml_data.each do |key, value|
              next if key == 'mesh'

              terraform += convert_value(key, value, 1)
            end
            terraform += resource_suffix
            terraform += "}\n"
            terraform
          end

          def resource_prefix
            <<-HEREDOC
  provider = konnect-beta
            HEREDOC
          end

          def resource_suffix
            <<-HEREDOC
  labels   = {
    "kuma.io/mesh" = konnect_mesh.my_mesh.name
  }
  cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
  mesh     = konnect_mesh.my_mesh.name
            HEREDOC
          end

          def convert_value(key, value, indent_level, is_in_array: false, is_last: false)
            key = snake_case(key) unless key.nil? || key.empty?

            case value
            when Hash
              convert_hash(key, value, indent_level, is_in_array, is_last)
            when Array
              convert_array(key, value, indent_level, is_in_array, is_last)
            else
              convert_scalar(key, value, indent_level, is_in_array, is_last)
            end
          end

          def convert_hash(key, value, indent_level, is_in_array, is_last)
            indent = '  ' * indent_level
            result = is_in_array ? "#{indent}{\n" : "#{indent}#{key} = {\n"
            value.each_with_index do |(k, v), index|
              result += convert_value(k, v, indent_level + 1, is_last: index == value.size - 1)
            end
            result += "#{indent}}#{trailing_comma(is_in_array, is_last)}\n"
          end

          def convert_array(key, value, indent_level, is_in_array, is_last)
            indent = '  ' * indent_level
            result = "#{indent}#{key} = [\n"
            value.each_with_index do |v, index|
              is_last_item = index == value.size - 1
              result += convert_value('', v, indent_level + 1, is_in_array: true, is_last: is_last_item)
            end
            result += "#{indent}]#{trailing_comma(is_in_array, is_last)}\n"
          end

          def convert_scalar(key, value, indent_level, is_in_array, is_last)
            indent = '  ' * indent_level
            formatted_value = format_scalar_value(value)
            "#{indent}#{key} = #{formatted_value}#{trailing_comma(is_in_array, is_last)}\n"
          end

          def format_scalar_value(value)
            case value
            when TrueClass, FalseClass, Integer, Float
              value.to_s
            else
              "\"#{value}\""
            end
          end

          def trailing_comma(is_in_array, is_last)
            is_in_array && !is_last ? ',' : ''
          end

          def snake_case(str)
            str.gsub(/([a-z])([A-Z])/, '\1_\2').gsub(/([A-Z])([A-Z][a-z])/, '\1_\2').downcase
          end
        end
      end
    end
  end
end
