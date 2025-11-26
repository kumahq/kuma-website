# frozen_string_literal: true

module Jekyll
  module KumaPlugins
    module Common
      # Regex to capture key-value pairs, standalone keys, and parameters with missing values
      PARAM_REGEX = /(\w+)=((["'])(.*?)\3|\S+)?|(\w+)/

      def parse_name_and_params(markup, default = {})
        # Ensure default_params keys are symbols
        default = default.transform_keys(&:to_sym)

        # Extract name and raw parameters, treating first word as name
        name, raw_params = markup.strip.split(' ', 2)

        # Set name to nil if it looks like a parameter or matches a default_params key
        name = nil if name&.include?('=') || default.key?(name.to_sym)

        # Parse parameters, treating entire markup as raw_params if name is nil
        params, extra_params = parse_params(name ? raw_params : markup.strip, default)

        [name, params, extra_params]
      end

      def parse_params(raw_params, default_params = {})
        return [default_params, {}] if raw_params.nil? || raw_params.empty?

        params = default_params.dup
        extra_params = {}

        raw_params.scan(PARAM_REGEX).each do |match|
          process_param_match(match, params, extra_params, default_params)
        end

        [params, extra_params]
      end

      private

      def process_param_match(match, params, extra_params, default_params)
        key, full_value, quote, inner_value, standalone_key = match
        key = key&.to_sym || standalone_key&.to_sym
        value = quote ? inner_value : full_value

        return handle_standalone_key(standalone_key.to_sym, params, default_params) if standalone_key

        handle_key_with_value(key, value, params, extra_params, default_params)
      end

      def handle_standalone_key(key, params, default_params)
        return params[key] = true if boolean_key?(key, default_params)
        return unless default_params.key?(key)

        params[key] = default_params.fetch(key, true)
      end

      def handle_key_with_value(key, value, params, extra_params, default_params)
        raise ArgumentError, "Parameter '#{key}' is missing a value" if value.nil?
        return extra_params[key] = value unless default_params.key?(key)

        params[key] = enforce_type(key, value, default_params[key])
      end

      def boolean_key?(key, default)
        [TrueClass, FalseClass].include?(default[key].class)
      end

      def enforce_type(key, value, expected)
        return Integer(value) if expected.is_a?(Integer)
        return value.to_s.empty? ? expected : convert_to_boolean(value) if [TrueClass,
                                                                            FalseClass].include?(expected.class)

        value
      rescue ArgumentError, TypeError
        if expected.is_a?(Integer)
          raise ArgumentError,
                "Expected #{key} to be a #{expected.class}, but got #{value.class}"
        end

        raise
      end

      def convert_to_boolean(value)
        case value.to_s.downcase
        when 'true' then true
        when 'false' then false
        else
          raise ArgumentError, "Invalid boolean value: expected 'true', 'false', or no value, but got '#{value}'."
        end
      end
    end
  end
end
