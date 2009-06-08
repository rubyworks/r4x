require 'rexml/document'
require 'rexml/xpath'

require 'facet/module/basename'
require 'facet/array/store'


# Some careful modification to REXML

class REXML::Attribute
  def replace( val  )
    @value = val.to_s
    @normalized = @unnormalized = nil
  end
end


# This is used it identify strings that conform to canonical XML,
# ie. "<tag>content</tag>".

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


# The Great Call

def xml( x )
  case x
  when Xml
    x
  when REXML::Element
    XmlElement.new x
  when REXML::Text
    XmlText.new x
  when REXML::Attribute
    XmlAttribute.new x
  when REXML::Instruction
    XmlInstruction.new x
  when REXML::Comment
    XmlComment.new x
  when XmlCanonical
    XmlElement.new(REXML::Document.new(x).root)
  else
    raise TypeError, "non-canonical xml #{x}"
    # String ?
    # ? to_s
  end
end

# The Xml Class

class Xml
  def node!  ; @node ; end
  def name!  ; @node.name ; end
  def class! ; @node.class.basename.downcase.to_sym ; end
  def text!  ; @node.to_s ; end
  def value! ; @node.to_s ; end

  def to_s ; @node.to_s ; end
  def to_i ; @node.to_s.to_i ; end  # ?
end


# The XmlText Virtual Class

class XmlText < Xml
  def initialize( node )
    raise unless REXML::Text === node
    @node = node
  end
  def name! ; nil ; end
end

# The XmlAttribute Virtual Class

class XmlAttribute < Xml
  def initialize( node )
    raise unless REXML::Attribute === node
    @node = node
  end
end

# The XmlElement Virtual Class

class XmlElement < Xml

  def method_missing( name, *args )
    name = name.to_s
    name.gsub!( /^_/, '@' )
    if name =~ /=$/
      name.gsub!( /=$/, "" )
      put!( name, args[0] )
    else
      get!( name )
    end
  end

  def initialize( node )
    raise unless REXML::Element === node
    @node = node
  end

  def []( key )       ; get!( key )      ; end
  def []=( key, val ) ; put!( key, val ) ; end

  def each ; @node.each { |e| yield e } ; end

  def text!  ; @node.text ; end
  def value! ; @node.text ; end

  def attributes!() @node.attributes ; end

  def get!( key )
    XmlList.new( xpath!( key.to_s ) )
  end

  def put!( key, val )
    key=key.to_s
    if key =~ /^@/
      @node.attributes[ key ] = val
    else
      r = get!( key )
      case r.size
      when 0
        r.put!( key, val )
      when 1
        r.replace!( val )
      else
        raise "how many?"
      end
    end
  end

  def add!( n )
    case n
    when Xml
      @node << n.node!
    when XmlList
      n.each { |e| self << e }
    else
      @node.add_text n.to_s
    end
    self
  end

  alias :<< :add!
  #alias :+  :add!

  def replace!( val )
    case @node
    when REXML::Attribute
      @node.replace( val )
    when REXML::Element
      @node.delete_element('*')
      @node.text = nil
      add!( val )
    end
  end

  def xpath!( name )
    children = XmlList.new()
    REXML::XPath.each( @node, "#{name}" ) { |elem|
      children.push( xml( elem ) )
    }
    children
  end

end


class XmlList < Array

  #def method_missing( sym, *args )
  #  self[0].send( sym, *args )
  #end

  def to_s
    self.join('')
  end

  def get!( key )
    case key
    when Integer
      at(key)
    else
      case size
      when 0
        []
      when 1
        at(0).get!( key )
      else
        XmlList.new( collect{ |e| e.xpath!( key.to_s ) } )
      end
    end
  end

  def put!( key, val )
    if Integer === key and key >= size
      add!( xml(val) )  #?
    else
      r = get!( key )
      case r.size
      when 0
        return nil
      when 1
        r[0].replace!( val )
      else
        return nil
      end
    end
  end

  def add!( n )
    self.push(n)
    self
  end

  alias :<< :add!

  def []( key )
    get!( key )
  end

  def []=( key, val )
    put!( key, val )
  end

end


# internal testing

if $0 == __FILE__

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
  puts
  puts x['stamp'][0]['face']
  x['stamp'][0]['face'] = "5.00"
  puts x['stamp'][0]['face']

end
