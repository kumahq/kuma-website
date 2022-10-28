# frozen_string_literal: true

module IndentFilter
  def indent(input)
    input.gsub(/\n/, "\n    ")
    # Remove the trailing empty line
    lines = input.split("\n")
    if lines.last.strip == ""
      lines.slice(0, lines.length - 2)
    end
    lines.join("\n")
  end
end

Liquid::Template.register_filter(IndentFilter)
