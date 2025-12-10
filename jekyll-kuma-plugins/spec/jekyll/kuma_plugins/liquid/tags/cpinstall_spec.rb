# frozen_string_literal: true

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::InstallCp do
  subject do
    described_class.parse('cpinstall', '', Liquid::Tokenizer.new("#{entry}{%endcpinstall%}"),
                          Liquid::ParseContext.new).render(Liquid::Context.new({
                                                                                 registers: {
                                                                                   site: {
                                                                                     config: {}
                                                                                   }
                                                                                 }
                                                                               }))
  end

  context 'with nothing' do
    let(:entry) { '' }
    it 'is empty' do
      expect(subject).to eq('')
    end
  end
end
