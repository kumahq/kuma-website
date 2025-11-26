# frozen_string_literal: true

require 'rspec'
require 'jekyll/kuma-plugins/common/params'

# Assuming ParamsParser is mixed into a class for testing
class TestParser
  include Jekyll::KumaPlugins::Common
end

RSpec.describe TestParser do
  let(:parser) { TestParser.new }
  let(:defaults) { { if_version: nil, init_value: 0, get_current: false } }

  describe '#parse_name_and_params' do
    context 'when name and parameters are provided' do
      it 'parses name and parameters with default values' do
        name, default_params, extra_params = parser.parse_name_and_params('my_var init_value=5 get_current=true',
                                                                          defaults)
        expect(name).to eq('my_var')
        expect(default_params).to eq({ if_version: nil, init_value: 5, get_current: true })
        expect(extra_params).to be_empty
      end

      it 'parses standalone keys as booleans if specified in defaults' do
        name, default_params, extra_params = parser.parse_name_and_params('my_var get_current', defaults)
        expect(name).to eq('my_var')
        expect(default_params).to eq({ if_version: nil, init_value: 0, get_current: true })
        expect(extra_params).to be_empty
      end

      it 'returns extra parameters separately' do
        name, default_params, extra_params = parser.parse_name_and_params(
          "my_var init_value=5 extra_param=10 another_param='hello'", defaults
        )
        expect(name).to eq('my_var')
        expect(default_params).to eq({ if_version: nil, init_value: 5, get_current: false })
        expect(extra_params).to eq({ extra_param: '10', another_param: 'hello' })
      end
    end

    context 'when name is absent' do
      it 'returns nil for name and parses parameters' do
        name, default_params, extra_params = parser.parse_name_and_params('init_value=5 get_current=true', defaults)
        expect(name).to be_nil
        expect(default_params).to eq({ if_version: nil, init_value: 5, get_current: true })
        expect(extra_params).to be_empty
      end
    end

    context 'when default values are overridden' do
      it 'maintains type enforcement for parameters' do
        name, default_params, extra_params = parser.parse_name_and_params("my_var init_value='5' get_current=true",
                                                                          defaults)
        expect(name).to eq('my_var')
        expect(default_params).to eq({ if_version: nil, init_value: 5, get_current: true })
        expect(extra_params).to be_empty
      end
    end

    context 'when parameters have incorrect types' do
      it 'raises an error for incorrect integer type' do
        expect do
          parser.parse_name_and_params("my_var init_value='not_a_number'", defaults)
        end.to raise_error(ArgumentError, 'Expected init_value to be a Integer, but got String')
      end

      it 'raises an error for incorrect boolean type' do
        expect do
          parser.parse_name_and_params("my_var get_current='not_a_boolean'", defaults)
        end.to raise_error(ArgumentError,
                           "Invalid boolean value: expected 'true', 'false', or no value, but got 'not_a_boolean'.")
      end
    end

    context 'when parameters are missing values' do
      it 'raises an error for missing values' do
        expect do
          parser.parse_name_and_params('my_var init_value=', defaults)
        end.to raise_error(ArgumentError, "Parameter 'init_value' is missing a value")
      end
    end
  end

  describe '#parse_params' do
    it 'returns default params when no parameters provided' do
      default_params, extra_params = parser.parse_params('', defaults)
      expect(default_params).to eq(defaults)
      expect(extra_params).to be_empty
    end

    it 'parses key-value pairs and maintains types' do
      default_params, extra_params = parser.parse_params('init_value=5 get_current=true', defaults)
      expect(default_params).to eq({ if_version: nil, init_value: 5, get_current: true })
      expect(extra_params).to be_empty
    end

    it 'parses standalone boolean keys correctly' do
      default_params, extra_params = parser.parse_params('get_current', defaults)
      expect(default_params).to eq({ if_version: nil, init_value: 0, get_current: true })
      expect(extra_params).to be_empty
    end

    it 'separates extra parameters not defined in defaults' do
      default_params, extra_params = parser.parse_params("init_value=5 extra_param='hello'", defaults)
      expect(default_params).to eq({ if_version: nil, init_value: 5, get_current: false })
      expect(extra_params).to eq({ extra_param: 'hello' })
    end

    it 'raises an error when required parameter type is incorrect' do
      expect do
        parser.parse_params("init_value='string_instead_of_int'", defaults)
      end.to raise_error(ArgumentError, 'Expected init_value to be a Integer, but got String')
    end

    it 'raises an error for parameters with empty values' do
      expect do
        parser.parse_params('get_current=', defaults)
      end.to raise_error(ArgumentError, "Parameter 'get_current' is missing a value")
    end
  end
end
