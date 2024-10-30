module Jekyll
  module KumaPlugins
    module Common
      def parse_name_and_params(markup, default = {})
        # Ensure default_params keys are symbols
        default = default.transform_keys(&:to_sym)

        # Extract name and raw parameters, treating first word as name
        name, raw_params = markup.strip.split(' ', 2)

        # Set name to nil if it looks like a parameter or matches a default_params key
        name = nil if name&.include?("=") || default.key?(name.to_sym)

        # Parse parameters, treating entire markup as raw_params if name is nil
        params, extra_params = parse_params(name ? raw_params : markup.strip, default)

        [name, params, extra_params]
      end

      def parse_params(raw_params, default_params = {})
        return [default_params, {}] if raw_params.nil? || raw_params.empty?

        # Regex to capture key-value pairs, standalone keys, and parameters with missing values
        matches = raw_params.scan(/(\w+)=((["'])(.*?)\3|\S+)?|(\w+)/)

        # Split parsed parameters into default_params and extra, enforcing types based on defaults
        params = default_params.dup
        extra_params = {}

        matches.each do |match|
          key, full_value, quote, inner_value, standalone_key = match
          key = key&.to_sym || standalone_key&.to_sym
          value = quote ? inner_value : full_value

          # Handle standalone keys as booleans if specified in defaults
          if standalone_key && boolean_key?(standalone_key.to_sym, default_params)
            params[standalone_key.to_sym] = true
          elsif standalone_key && default_params.key?(standalone_key.to_sym)
            params[standalone_key.to_sym] = default_params.fetch(standalone_key.to_sym, true)
          elsif key && value.nil?
            # Raise an error if a key is provided with `=` but no value
            raise ArgumentError, "Parameter '#{key}' is missing a value"
          elsif key && default_params.key?(key)
            # Enforce type based on default_params values
            params[key] = enforce_type(key, value, default_params[key])
          else
            # Add unmatched keys to the extra_params hash
            extra_params[key] = value
          end
        end

        [params, extra_params]
      end

      private

      def boolean_key?(key, default)
        [TrueClass, FalseClass].include?(default[key].class)
      end

      def enforce_type(key, value, expected)
        return Integer(value) if expected.is_a?(Integer)
        return value.to_s.empty? ? expected : convert_to_boolean(value) if [TrueClass, FalseClass].include?(expected.class)

        value
      rescue ArgumentError, TypeError
        raise ArgumentError, "Expected #{key} to be a #{expected.class}, but got #{value.class}" if expected.is_a?(Integer)
        raise
      end

      def convert_to_boolean(value)
        case value.to_s.downcase
        when "true" then true
        when "false" then false
        else
          raise ArgumentError, "Invalid boolean value: expected 'true', 'false', or no value, but got '#{value}'."
        end
      end
    end
  end
end
