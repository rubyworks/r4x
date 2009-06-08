require 'facet/string/shatter'
require 'facet/string/dequote'


def xml( x )
  R4X::Xml.newq( x )
end


module R4X

  START_TAG_RE = %r{\A \< (\w+) (.*?) \>}mix

  # This is used it identify strings that conform to canonical XML element text.
  # It could afford to be made alittle more robust.
  #
  module XmlCanonical
    def self.===( sa )
      #sa = sa.join('') if Array === sa
      str = sa.to_s #.strip
      stag = (%r{\A \< (\w+) (.*?) (\/)? \>}mix).match( str )
      return false unless stag
      return true if stag[3] # non-content
      etag = (%r{\< \/ #{stag[1]} [ ]* \> \Z}mix).match(str)
      return false unless etag
      true
    end
  end

  # Common routine
  define_method :get_namespace { |prefix|

  }

  #
  # QName
  #

  QName = Class.new {

    attr :name
    attr :namespace
    attr :prefix

    class << self
      def newq( unqualified_name )
        name, prefix = *unqualified_name.split(':').reverse
        new( name, prefix )
      end
    end

    define_method :initialize { |name, prefix|
      @name = name
      @prefix = prefix
      @namesapce = get_namespace( prefix )
    end

    def to_s
      return "#{@prefix}:#{@name}" if @prefix
      @name
    end

  }


  #
  # XmlTag
  #
  class XmlTag
    attr :name         # QName
    attr :attributes   # Hash { QName => String, ... }

    class << self
      def newq( name, attributes={} )
        new( QName.newq( name ), attributes )
      end
    end

    def initialize( name, attributes={} )
      @name = name.to_s
      @attributes = attributes
    end

    def to_s
      "#{@name}"
    end
  end


  class XmlList
    attr :list  # Array [ Xml ; String , ... ]

    include Enumerable

    def initialize( list )
      @list = list
    end

    def each ; @list.each { |e| yield e } ; end
    def size ; @list.size ; end
    def at(*args) ; @list.at(*args) ; end

    def children ; @list ; end

    def elements
      return [] if @list.size == 0
      if @list.size == 1
        l = @list[0]
      else
        l = @list
      end
      l.select { |e| Xml === e }
    end

    # The clever query
    def [](q)
      case q
      when Integer
        return list.at(q)
      when '*'
        return elements
      when '@*'
        return attributes
      when /^@/
        return attributes.fetch(q)
      when /\:/
        return elements.select { |e| e.name == q }
      else
        return elements.select { |e| e.local_name == q }
      end
    end

    # The clever updater/inserter
    def []=(q,v)
      r = self[q]
      case r.size
      when 0
        @list << v.to_s
      when 1
        case q
        when Integer
          list.store(q,v)
        when '*'
          raise "not implemented"
        when '@*'
          raise "not implemented"
        when /^@/
          attributes[q] = v
        else
          r[0].replace( v )
        end
      else
        # more than one match
        return nil #?
      end
    end

    #def method_missing( sym, *args )
    #  at(0).send( sym, *args )
    #end
  end

  #
  # Xml
  #
  class Xml < XmlList
    attr :tag   # XmlTag
    #attr :list  # Array [ Xml ; String , ... ]

    class << self
      def newq( str_or_arr )
        #a = ( String === str_or_arr ? parse(str_or_arr) : str_or_arr )
        a = ( Array === str_or_arr ? str_or_arr : parse(str_or_arr) )

        r = a.collect do |e|
          case e
          when Array
            if ::XmlCanonical === e.join('')
              tag = XmlTag.newq( name( e[0] ), attributes( e[0] ) )
              list = ( e.size > 1 ? xml( e[1...-1] ) : nil )
              Xml.new( tag, list )
            else
              xml( e )
            end
          else
            e  # String === e
          end
        end

        if XmlCanonical === str_or_arr
          tag = XmlTag.newq( name( r[0] ), attributes( r[0] ) )
          list = ( r.size > 1 ? xml( r[1...-1] ) : nil )
          Xml.new( tag, list )
        else
          XmlList.new( r )
        end
      end

      def name( e0 )
        START_TAG_RE.match(e0)[1]
      end

      def attributes( e0 )
        s = START_TAG_RE.match( e0 )[2].strip
        a = s.split( %r{\s+|\=}x ).collect { |e| e.dequote }
        return Hash[ *a ]
      end
    end

    #
    def initialize( tag, list )
      @tag = tag
      super( list )
    end

    def name() @tag.to_s ; end
    def local_name() @tag.name ; end
    def attributes() @tag.attributes ; end

    def inspect
      "<#{tag}> ... </>"
    end

    def to_s
      attrs = attributes.collect{ |k,v| "#{k}=#{v}" }.join(' ')
      attrs = " #{attrs}" unless attrs.empty?

      lstr = @list.collect { |e|
        case e
        when Xml
          e.to_s
        when Array
          e.collect { |ee| ee.to_s }.join('')
        else
          e.to_s
        end
      }.join('')

      %{<#{tag.name}#{attrs}>#{lstr}</#{tag.name}>}
    end

    def replace( x )
      @list = [ x.to_s ]
    end

  end

  #
  # XmlInstruction
  #
  class XmlInstruction
    def initialize(name, data)
    end
  end

  #
  # XmlComment
  #
  class XmlComment
    def initialize(comment)
    end
  end


  #
  # R4X Parser
  #

  RETAG = %r{ \< (\/)? ([\w.:]+) (.*?) ([/])? \> }mix
  IDXEND = 1
  IDXNAME = 2
  IDXATTR = 3
  IDXUNIT = 4

  #module_function

  def parse(xmldata)
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

end


include R4X

q = %{
<stamps>
  <stamp>
    <issued>2004-12-18</issued>
    <depiction>Santa</depiction>
    <face d="USD">0.32</face>
    <real d="USD">2.45</real>
  </stamp>
  <stamp>
    <issued>2003-12-18</issued>
    <depiction>Bunny</depiction>
    <face d="USD">0.32</face>
    <real d="USD">1.20</real>
  </stamp>
</stamps>
}

x = xml( q )

puts
puts x

puts x['stamp']
puts
puts x['stamp'][0]['issued']
puts
x['stamp'][0]['issued'] = "2000-01-01"
puts x['stamp'][0]['issued']


























# #
# # XmlList
# #
# class XmlList
# 
#   class << self
#     alias_method :__new, :new
#     def new( xa )
#       XmlList === xa ? xa : __new( xa )
#     end
#   end
# 
#   def initialize( list )
#     @list = list
#   end
# 
#   def [](q)
#     case @list.size
#     when 0
#       []
#     when 1
#       @list.at(0)[q]
#     else
#       case q
#       when Integer
#         @list[q]
#       when String
#         XmlList.new( @list.collect { |e| e[q] } )
#       end
#     end
#   end
# 
#   def []=( q, v )
#     r = self[q]
# p r
#     case r.size
#     when 1
#       p r
#     end
#   end
# 
#   def select( &blk )
#     XmlList.new( @list.select( &blk ) )
#   end
# 
#   def to_s
#     @list.collect { |e| e.to_s }.join("\n")
#   end
# 
#   def method_missing( meth, *args )
#     @list.send( meth, *args )
#   end
# 
# end
