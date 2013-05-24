require 'json'
require 'cairo'
require 'stringio'

module TerminalThumbnail
  class Color
    def initialize colortype
      @table = COLOR_TYPES[colortype] || COLOR_TYPES['black']
    end

    def background
      @table[:background]
    end

    def font_style font
      highlight = font & 0x10000 != 0
      underline = font & 0x20000 != 0
      flipcolor = font & 0x40000 != 0
      hidefgcol = font & 0x80000 != 0
      defaultfg = font & 0x200000 != 0
      defaultbg = font & 0x100000 != 0

      colortable = highlight ? @table[:highlight] : @table[:normal]
      fg = colortable[(font & 0xff00) >> 8] unless defaultfg
      bg = colortable[font & 0x00ff] unless defaultbg
      if flipcolor
        fgcolor = bg || @table[:background] unless hidefgcol
        bgcolor = fg || (highlight ? @table[:emphasis] : @table[:foreground])
      else
        fgcolor = fg || (highlight ? @table[:emphasis] : @table[:foreground]) unless hidefgcol
        bgcolor = bg
      end
      {color:fgcolor, background:bgcolor, underline:underline}
    end

    COLOR_TYPES={
      'white'=>{
        normal:["#000","#F00","#0F0","#AA0","#00F","#F0F","#0AA","#BBB"],
        highlight:["#666","#F60","#0F6","#AF0","#60F","#F0A","#06A","#BBB"],
        foreground:"black",background:"white",emphasis:"#600",cursor:"#00F"
      },
      'black'=>{
        normal:["#FFF","#F66","#4F4","#FF0","#88F","#F0F","#0FF","#444"],
        highlight:["#AAA","#F00","#6F6","#AA0","#66F","#F6F","#6FF","#444"],
        foreground:"white",background:"black",emphasis:"#FAA",cursor:"#CCF"
      },
      'novel'=>{
        normal:["#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BFBFBF"],
        highlight:["#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BFBFBF"],
        foreground:"#532D2C",background:"#DFDBC3",emphasis:"#A1320B",cursor:"#000000"
      },
      'green'=>{
        normal:["#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BFBFBF"],
        highlight:["#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BFBFBF"],
        foreground:"#BFFFBF",background:"#001F00",emphasis:"#7FFF7F",cursor:"#FFFFFF"
      },
    }
    def self.gen_color_table
      color=[
        "#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BfBfBf",
        "#666666","#E60000","#00D900","#E6E600","#0000FF","#E600E6","#00E6E6","#E6E6E6"
      ]
      6.times{|r|6.times{|g|6.times{|b|color[16+r*36+g*6+b]="##{[r,g,b].map{|c|(51*c).to_s(16)}.join}"}}}
      24.times{|i|color[232+i]="##{(8+10*i).to_s(16)*3}"}
      COLOR_TYPES.each do |name, table|
        table = COLOR_TYPES[name] || COLOR_TYPES['black']
        normal = table[:normal]
        highlight = table[:highlight]
        color.each_with_index do |c, i|
          normal[i] ||= c
          highlight[i] ||= c
        end
      end
    end
    gen_color_table
  end

  def self.create vt100, colortype, title = nil
    color = Color.new colortype
    width = 320
    height = 192
    offset = 2
    surface = Cairo::ImageSurface.new Cairo::FORMAT_RGB24, width+2*offset, height+2*offset
    context = Cairo::Context.new surface

    context.set_source_rgb 0.5, 0.5, 0.5
    context.line_width = offset
    context.rectangle offset/2, offset/2, width+offset, height+offset
    context.stroke

    context.translate offset, offset
    context.set_source_rgba *Cairo::Color.parse(color.background)
    context.rectangle 0, 0, width, height
    context.clip
    context.rectangle 0, 0, width, height
    context.fill

    context.font_size = 15
    context.select_font_face 'monospace', nil, Cairo::FontWeight::BOLD

    vt100['line'].each_with_index do |line, y|
      fonts, chars, length = line['fonts'], line['chars'], line['length']
      font = fonts[0]
      textblock = []
      text = []
      left = 0
      length.times do |i|
        f = fonts[i]
        c = chars[i]
        if f != font
          textblock << [text, font, left]
          text = [c]
          font = f
          left = i
        else
          text << c
        end
      end
      textblock << [text, font, left]
      textblock.each do |text, font, x|
        left = x * 8
        top = y * 16
        context.save
        context.translate x * 8, y * 16
        style = color.font_style font
        if style[:background]
          context.set_source_rgba *Cairo::Color.parse(style[:background])
          context.rectangle(0, 0, 8*text.length, 16)
          context.fill
        end
        if style[:color]
          context.set_source_rgba *Cairo::Color.parse(style[:color])
          if style[:underline]
            context.rectangle(0, 15, 8*text.length, 1)
            context.fill
          end
          context.translate 0,16
          text.each_with_index do |c, i|
            context.text_path c
            context.fill
            context.translate 8,0
          end
        end
        context.restore
      end
    end
    if title
      context.translate 0, height-54
      context.rectangle(0, 0, width, 54)
      context.set_source_rgba(0.5,0.5,0.5,0.5)
      context.fill
      context.font_size = 32
      context.translate 4, 40
      context.text_path title
      context.set_source_rgba(1,1,1)
      context.select_font_face 'Serif', nil, Cairo::FontWeight::BOLD
      context.fill
    end
    stream = StringIO.new
    surface.write_to_png stream
    surface.destroy
    stream.rewind
    stream.read
  end
end
