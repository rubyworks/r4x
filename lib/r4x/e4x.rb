
# E4X (Lite)
#
# This is a E4X library making it easy to parse and manipulate XML documents.
# It is not a compliant implementaion of E4X, but it is very close to being so
# from the end-user's point-of-view.
#
# This library uses REXML as a backend. An option to use libxml may be added in
# the future for speed.

require 'rexml/document'
require 'rexml/xpath'

#require 'facet/object/deepcopy'
require 'facet/string/shift'
require 'facet/string/pop'

require 'e4x/qname'
require 'e4x/xml_delegate'
require 'e4x/xmllist_delegate'


def xml( xmldata )
  Xml.new(xmldata)
end

class Xml

  # This is used it identify strings that conform to canonical XML element text.
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


  VALID_CLASSES = [ :element, :text, :comment, :instruction, :attribute ]

  # These are for a special usage (non-standard XML); ignored for all standard purposes.
  #VERB_INDICATOR = '|'
  #VERB_REGEX = %r{ \< ([\w.:]+) (.*?) ([#{VERB_INDICATOR}]\d*) \> }mix

  class << self
    alias :__new :new
    def new( xmldata, parent=nil )
      case xmldata
      when nil, ''
        raise ArgumentError
      when Xml, Symbol, XmlCanonical
        __new( xmldata, parent )
      when REXML::Element, REXML::Text, REXML::Attribute, REXML::Instruction
        __new( xmldata, parent )
      else
        XmlList.new(xmldata, parent)
      end
    end
  end

  def initialize( xmldata, parent=nil )
    @parent = parent
    case xmldata
    when Xml
      @node = xmldata.__node.dup
      @class = xmldata.__class.dup
      @name = xmldata.__node.name.dup
    when Symbol
      #@node = REXML::Document.new( "<#{xmldata}></#{xmldata}>" ).root
      #@node = REXML::Element.new( "<#{xmldata}></#{xmldata}>" ).root
      @node = REXML::Element.new( xmldata )
      @class = :element
      @name = @node.name
    when XmlCanonical
      xmldata = xmldata.to_s
      @node = REXML::Document.new( xmldata.strip ).root
      #@node = REXML::Element.new( xmldata.strip )
      @class = :element
      @name = @node.name
    when REXML::Element
      @node = xmldata
      @class = :element
      @name = @node.name
    when REXML::Text
      @node = xmldata
      @class = :text
      @name = nil
    when REXML::Attribute
      @node = xmldata
      @class = :attribute
      @name = xmldata.name
    when REXML::Instruction
      @node = xmldata
      @class = :instruction
      @name = xmldata.target
    else
      raise ArgumentError, "invlaid xml"
    end
    @self ||= XmlDelegate.new(self)
  end

  # These are reserved tag names, i.e. they can't be used as xml tags
  # and then accessed via the call syntax of E4X.
  #
  #   self
  #   __node
  #   __class
  #   to_s
  #   to_i
  #   each
  #

  # This is how to access the underlying Xml object, i.e. via the delegate.
  def self ; @self ; end

  # This is how the delegate accesses the node.
  def __node  ; @node ; end

  # This is how the delegate accesses the node classification.
  def __class ; @class ; end

  # Important for this to work in string interpolation.
  def to_s() @node.to_s ; end

  # ?
  def to_i() @node.to_s.to_i; end

  # (neccessary?) FIX!!!
  def each()
    @node.each_child { |c| yield(c) }
  end

  # Shortcut for add.
  def <<( n )
    @self.add( n )
  end

  # XPath for all elements.
  def * ; @self.get('*') ; end

  # Shortcut for XPath '@*', meaning all attributes.
  def _ ; @self.get('@*') ; end

  # XPath get operator.
  def []( key )
    @self.get( key )
  end

  #XPath put operator.
  def []=( key, val )
    @self.put( key, val )
  end

  # Here's where all the fun's at!
  # It's more complicated then it looks ;-)
  def method_missing( sym, *args )
    sym = sym.to_s
    if sym.slice(-1) == '='
      self["#{sym.pop}"] = args[0]
    else
      self["#{sym}"]
    end
  end

end

#
# XmlList
#
class XmlList

  class << self
    alias_method( :__new, :new )
    def new( xd=[], to=nil, tp=nil )
      case xd
      when XmlList
        xd
      else
        __new( xd, to, tp )
      end
    end
  end

  def initialize( xd=[], to=nil, tp=nil )
    @self = XmlListDelegate.new(self)
    case xd
    when []
      @list = []
      @target_object = to
      @target_property = tp
    when Xml
      @list = [xd]
      @target_object = xd.self.parent
      @target_property = xd.self.name
    else
      xd = REXML::Document.new(%{<_>#{xd}</_>}).root
      a = []; xd.each{ |n| a << Xml.new(n) }
      @list = a
      @target_object = nil
      @target_property = nil
    end
  end

  # This is how to access the underlying Xml object, i.e. via the delegate.
  def self ; @self ; end

  # This is how the delegate accesses the node.
  def __list  ; @list ; end

  # This is how the delegate accesses the node classification.
  def __class ; :xmllist ; end

  # This is how the delegate accesses the node classification.
  def __target_object ; @target_object ; end
  def __target_object=(to) ; @target_object = to ; end

  # This is how the delegate accesses the node classification.
  def __target_property ; @target_property ; end
  def __target_property=(tp) ; @target_property = tp ; end

  # Important for this to work in string interpolation.
  def to_s() @list.to_s ; end

  # ?
  def to_i() @list.to_s.to_i; end

  # each
  def each(&blk) ; @list.each(&blk) ; end

  # Shortcut for add.
  def <<( n )
    @self.add( n )
  end

  # XPath for all elements.
  def * ; @self.get('*') ; end

  # Shortcut for XPath '@*', meaning all attributes.
  def _ ; @self.get('@*') ; end

  def []( v )
    @self.get( v )
  end

  def []=( prop, v )
    @self.put( prop , v )
  end

  #
  def method_missing( sym, *args )
    sym = sym.to_s
p sym
    if (args.size > 0)
      self[0].send( sym, args )
    else
      self[0].send( sym )
    end
  end

end



# test
if $0 == __FILE__

  XmlList.new('abc <tab>123</tab>')

  x = xml %Q{
    <people id="666-99-0989" lick="me">
    <person username="trans">
      <name>
        Tom
        ...
          123
      </name>
      <age>35</age>
    </person>
    <person username="jenasmom">
      <name>Becky</name>
      <age>32</age>
    </person>
    </people>
  }

  puts x.*
  puts x._

  puts x.self.name
  puts x.self.attributes

  puts x.person
  puts x['person']
  puts x._id
  puts x['@id']
p x
  puts x[1]  # skip whatespace?
puts "HERE"
  x << xml(%{<fred id="10">Timmy</fred>})

  puts x['@*']

end



# SCRAP

#   def __verb?(str)
#     str = str.strip
#     return nil unless __tag?(str)
#     md = (%r{\A \< (\w+) (.*?) \>}mix).match( str )
# p md
#     return nil unless md[2] =~ %r{xml:cdata=['"]\d+['"]}
#     ed = (%r{\< \/ #{n} [ ]* \> \Z}mix).match(str)
#     return nil unless ed
#     c = md[0] + '<![CDATA[' + str[md.end(0)...ed.begin] + ']]>' + ed[0]
# p c
# c
#     #str = str.sub( %r{\A \< (\w+) .*? \>}mix ) { |m| n=$1 ; "#{m}<![CDATA[" }
#     #str = str.sub( %r{\< \/ #{n} [ ]* \> \Z}mix ) { |m| "]]>#{m}" }
# #       n << md.post_match.gsub(%r{\< \/ #{md[1]} [ ]* \> \Z}mix, '')   #[0...(md.post_match.rindex('<'))]  # not robust enough
# #       n << "]]>"
# #       n << "</#{md[1]}>"
#   end
