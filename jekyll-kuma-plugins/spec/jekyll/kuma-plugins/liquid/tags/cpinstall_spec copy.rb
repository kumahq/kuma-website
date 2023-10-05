RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::InstallCp do
  subject { described_class.parse('cpinstall', "", Liquid::Tokenizer.new(entry + '{%endcpinstall%}'), Liquid::ParseContext.new).render(Liquid::Context.new({
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
