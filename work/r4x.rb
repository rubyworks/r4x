#
# This key idea behingd this implementation is that the XML
# is actually stored in String form throughout (albiet
# the parserd form in cached for speed). as the XML is processed
# it is parsed on the fly. Becuase of this, simply inserting
# a valid XML string into a node will "automatically" take.
#
# Of course, that's the idea. Implementation is a little tricky.
#


require 'nano/string/shatter'
require 'nano/string/shift'
require 'nano/string/dequote'


  START_TAG_RE = %r{\A \< (\w+) (.*?) \>}mix

  # This is used it identify strings that conform to canonical XML element text.
  # It could afford to be made alittle more robust.
  #
  module XmlCanonical
    module_function
    def ===( str )
      str = str.to_s.strip
      #str[0,1] == '<' && str[-1,1] == '>'  # should make more robust (TODO)
      md = (%r{\A \< (\w+) (.*?) \>}mix).match( str )
      return false unless md #[2] =~ %r{xml:cdata=['"]\d+['"]}
      ed = (%r{\< \/ #{md[1]} [ ]* \> \Z}mix).match(str)
      return false unless ed
      true
    end
  end


  def xml( str_or_arr )
    Xml.new( str_or_arr )
  end

  class Xml

    def initialize( x )
      case x
      when String
        raise unless XmlCanonical === x
        @canonical = x.strip
        children
      when Array
        @canonical = x.join('')
        @children = x
      else
        raise ArgumentError
      end
    end

    #def reset
    #  @name = nil
    #  @attributes = nil
    #  @elements = nil
    #end

    def children
      @children ||= __parse__( @canonical )[0][1...-1]
    end

    def elements
      @elements ||= children.select { |e| XmlCanonical === e }
    end

    def texts
      @texts ||= children.reject { |e| XmlCanonical === e }
    end

    def elements_assoc
      @elements.collect { |e| [ START_TAG_RE.match( e[0] )[1], e ] }
    end

    def name
      @name ||= START_TAG_RE.match( @canonical )[1]
    end

    def attributes
      unless @attributes
        s = START_TAG_RE.match( @canonical )[2].strip
        a = s.split( %r{\s+|\=}x ).collect { |e| e.dequote }
        @attributes = Hash[ *a ]
      end
      @attributes
    end

    def value
      @children.join('')
    end

    def []( k )
      if Integer === k
        e = children[k]
        XmlCanonical === e ? xml( e ) : e
      elsif k == '*'
        xml( elements )
      elsif k == '@*'
        attributes
      elsif k =~ /^[@]/
        attributes[ k.shift ]
      else
        q = elements.select { |e| START_TAG_RE.match( e[0] )[1] == k }
        if q.length == 0
          nil
        elsif q.length == 1
          ::Xml.new( q[0] )
        else
          ::XmlList.new( q )
        end
      end
    end

  end


  class XmlList

    def initialize( a )
      @canonical = a.join('')
      @children = a
    end

    def children
      @children
    end

    def elements
      @elements ||= children.select { |e| ::XmlCanonical === e.join('') }
    end

    def texts
      @texts ||= children.reject { |e| ::XmlCanonical === e.join('') }
    end

    def elements_assoc
      @elements.collect { |e| [ START_TAG_RE.match( e[0] )[1], e ] }
    end

    def value
      @children.join('')
    end

    def []( k )
      case k
      when Integer
        q = @children[k]
        return q unless q
        if q.length == 1
          ::Xml.new( q )
        else
          ::XmlList.new( q )
        end
      when '*'
      when '@*'
      else
        elements.each { |e| START_TAG_RE.match( e[0] )[1] == k }
      end
    end

  end


#module XmlUtil

  RETAG = %r{ \< (\/)? ([\w.:]+) (.*?) ([/])? \> }mix
  IDXEND = 1
  IDXNAME = 2
  IDXATTR = 3
  IDXUNIT = 4

  #module_function

  def __parse__(xmldata)
    if String === xmldata
      q = xmldata.strip.shatter(RETAG)
    else
      q = xmldata.dup
    end
    # setup
    build = []
    current = build
    stack = []
    # stack loop
    until q.empty?
      e = q.shift
      if md = RETAG.match( e )
        if md[IDXEND]
          #close-tag
          current << e
          current = stack.pop
        elsif md[IDXUNIT] == '/'
          #unit-tag
          current << e
        else
          #open-tag
          stack << current
          current << []
          current = current.last
          current << e
        end
      else
        current << e #if e != "\n"
      end
    end
    return build
  end

#end


if $0 == __FILE__

  xs = %{
  <people type="friends" hoot="wah">
    <person id="1">
      <name>Tom</name>
      <age>35</age>
    </person>
    <person id="1">
      <name>George</name>
      <age>30</age>
    </person>
  </people>
  }

  x = xml( xs )

  puts
  p x
  puts
  p x.name
  puts
  p x.attributes
  puts
  p x.children
  puts
  p x.elements
#   puts
#   p x.texts
#   puts
#   p x.elements_assoc
#   puts
#   p x[1]
#   puts
#   p x['*']
#   puts
#   p x['@*']
#   puts
#   p x['@type']
#   puts
#   p x['person']
#   puts
#

   puts
   p x['person']
   puts
   p x['person']['name']

end
