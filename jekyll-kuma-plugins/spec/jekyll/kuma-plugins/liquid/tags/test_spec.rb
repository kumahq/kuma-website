RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::Test do
  subject { described_class.parse('test', "", Liquid::Tokenizer.new(entry + '{%endtest%}'), Liquid::ParseContext.new).render(Liquid::Context.new({}))}

  context "with nothing" do
    let(:entry) {''}
    it "is empty" do
      expect(subject).to eq('<p> TESTED</p>')
    end
  end
  context "with 'test' as text" do
    let(:entry) {'test'}
    it "it adds test" do
      expect(subject).to eq('<p>test TESTED</p>')
    end
  end
end
