RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml do
  subject { described_class.parse('policy_yaml', "", Liquid::Tokenizer.new(entry + '{%endpolicy_yaml%}'), Liquid::ParseContext.new).render(Liquid::Context.new({
    registers: {
        :site => {
            config: {}
        }
    }
  }))}

  context "with nothing" do
    let(:entry) {''}
    it "is empty" do
      expect(subject).to eq('')
    end
  end
end
