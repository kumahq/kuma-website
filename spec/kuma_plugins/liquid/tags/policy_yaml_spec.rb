# spec/jekyll/kuma-plugins/liquid/tags/policyyaml_spec.rb
require 'jekyll'
require_relative '../../../../jekyll-kuma-plugins/lib/jekyll/kuma-plugins/liquid/tags/policyyaml'

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml do
  let(:content) { <<-YAML
    apiVersion: kuma.io/v1alpha1
    mesh: default
    kind: TrafficRoute
    metadata:
      name: route-example
      namespace: test
    spec:
      to:
        - targetRef:
            kind: MeshService
            name_uni: example-service
            name_kube: example-service_test_8080
  YAML
  }

  let(:site) { Jekyll::Site.new(Jekyll.configuration) }
  let(:page) { { 'version' => '2.9.1' } }  # This sets the version key for testing
  let(:registers) { { :page => page, :site => site } }
  let(:context) { Liquid::Context.new({}, {}, registers) }

  it 'renders universal and kubernetes versions correctly' do
    template = Liquid::Template.parse("{% policy_yaml my-tabs %}#{content}{% endpolicy_yaml %}")

    output = template.render(context)

    puts "Output from render: #{output}"  # Log the rendered output for debugging

    # Simple checks on the output
    expect(output).to include("```yaml")
    expect(output).to include("example-service")
  end
end

