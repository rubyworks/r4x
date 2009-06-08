#
# E4X for Ruby
#
#

require 'rexml/document'
require 'rexml/xpath'

def xml(xmldata)
  Xml.new(xmldata)
end

module EMCAScript

  def toXmlList

  end

end


class Xml

#   def method_missing( name, *args )
#     name = name.to_s
#     if ( name =~ /^_/ )
#       name.gsub!( /^_/, "" )
#       if ( name =~ /=$/ )
#         name.gsub!( /=$/, "" )
#         _write_attribute( name, args[0] )
#       else
#         _read_attribute( name )
#       end
#     else
#       xpath( "#{name}" )
#     end
#   end

  def initialize( node )
    #@node = node
    @node = REXML::Document.new(xmldata).root
  end

  def to_XmlList
    target_object = self.__parent__
    target_poperty = self.__name__
    l = XmlList.new([self], target_object, target_property)
  end

  def name
    @node.name
  end

  def parent
    @node.parent
  end

  def attributes
    @node.attributes
  end

  def in_scope_namspace
    @node.namespace
  end

  def length
    @node.children.length
  end

  #
  def get(prop)
    x = self
    if Integer === prop
      l = to_XmlList
      return l.__get__(prop)
    end
    n = prop.to_XmlName
    l = XmlList.new([],x,n)
    if AttributeName === n
      x.attributes.each { |a|
        if (( n.name.local_name =='*' ||  n.name.local_name == a.name.local_name )
           and ( n.name.uri == nil || n.name.uri == a.name.uri ))
          l.append(a)
        end
      }
      return l
    end
    (0...x.Length).each { |k|
      if ((n.local_name == '*')
         or ((Element === x[k]) and (x[k].name.local_name == a.name.local_name)))
        and ((n.uri == nil) or ((x[k].__class__ == "element") and (n.uri == x[k].name.uri)))
        l.append(x[k])
      end
    }
    return l
  end

  #
  def put( prop, val )
    x = self
    if !(Xml === val or XmlList === val) or ( [:text,:attribute].include?(val.classification) )
      c = val.to_s
    else
      c = val.deepcopy
    end
    raise ArgumentError if Numeric === prop
    return if [:text,:attribute,:comment,:processing_instruction].inlcude?( x.classification )
    n = prop.to_XmlName
    default_namespace = get_default_namespace
    if AttributeName === n
      return unless is_XmlName(n.name)
      if XmlList === c
        if c.length === 0
          c = ''
        else
          #s = c[0].to_s
          #(1...c.length).each { |i| s += " #{c[i].to_s}"
          s = c.join(' ')
        end
      else
        c = c.to_s
      end
      a = nil
      x.attributes.each { |j|
        if (n.name.local_name == j.name.local_name and (n.name.uri == nil or n.name.uri == j.name.uri)
          a = j unless a
        else
          x.delete(j.name)
        end
      }
      unless a
        unless n.name.uri
          nons = Namespace.new
          name = QName.new( nons, n.name )
        else
          name = QName.new( n.name )
        end
        a = Xml.new { |s| s.name=name ; s.classification=:attribute ; s.parent=x }
        x.attributes << a
        ns = name.get_namespace
        x.add_in_scope_namespace(ns)
      end
      a.value = c
      return
    end
    is_valid_name = is_XmlName(n)
    return if !is_valid_name and n.local_name != '*'
    i = nil
    primitive_assign = ((!(Xml === c or XmlList === c)) and n.local_name != '*')
    (x.length-1).downto(0) { |k|
      if ((n.local_name == '*') or (( x[k].classification == :element) and (x[k].name.locall_name == n.local_name)))
      and ((n.uri == nil) or ((x[k].classification==:element) and (n.uri == x[k].name.uri)))
        if i
          x.delete_by_index(i.to_s)
          i = k
        end
      end
    }
    unless i
      i = x.length
      if primitive_assign
        unless n.uri
          name = QName.new( default_namespace, n )
        else
          name = QName.new(n)
        end
        y=Xml.new{|s| s.name=name; s.classification=:element; s.parent=x}
        ns=name.get_namespace
        x.replace(i.to_s,y)
        y.add_in_scope_namespace(ns)
      end
    end
    if primitive_asign
      # x[i].delete_all_properties
      s = c.to_s
      x[i].replace("0",s) if s != ''
    else
      x.replace(i.to_s,c)
    end
    return
  end

  #
  def delete(prop)
    x = self
    raise ArgumentError if Numeric === prop
    n = to_XmlName(prop)
    if AttributeName === n
      x.attributes = x.attributes.collect{|a|
        if ((n.name.local_name == '*') or (n.name.local_name == a.name.local_name))
        and ((n.name.uri == nil) or (n.name.uri == a.name.uri))
          a.parent = nil
          nil
        else
          a
        end
      }.compact
      return true
    end
    dp = 0
    (0...x.length).each{|q|
      if ((n.local_name == '*')
      or (x[q].classification == :element and x[q].name.local_namespace == n.local_name))
      and ((n.uri == nil) or (x[q].classification == :element and n.uri == x[q].name.uri))
        x[q].parent = nil
        x.delete_at(q)
        dp+=1
      else
        if dp > 0
          x[q - dp] = x[q]
          x.delete_at(q)
        end
      end
    }
    x.length = x.length - dp  # really need to do this?
    return true
  end

  #
  def delete_by_index(prop)
  end

  #
  def __default_value__
  end

  #
  def __has_property__
  end

  #
  def __deep_copy__
  end

  #
  def __descendents__(prop)
  end

  #
  def __equals__(value)
  end

  #
  def __resolve_value__
  end

  #
  def __insert__(prop,value)
  end

  #
  def __replace__(prop,value)
  end

  #
  def __add_in_scope_namespace__(namespace)
  end






  def __text() @node.text; end

  def to_s() @node.to_s; end

  def to_i() @node.to_s.to_i; end

  def _add ( nodes )
    @node << nodes._get_node
    self
  end

  alias :<< :_add

  alias :+ :_add

  def _get_node() @node; end

  def xpath( name )
    out = XmlList.new()
    @node.each_element( name ) { |elem|
      out.push( Xml.new( elem ) )
    }
    return out
    #children = XmlList.new()
    #REXML::XPath.each( @node, "#{name}" ) { |elem|
    #  children.push( Xml.new( elem ) )
    #}
    #children
  end

private

  def _read_attribute( name )
    @node.value.to_s if @node.class == REXML::Attribute
    @node.attributes[ name ].to_s if @node.class == REXML::Element
  end

  def _write_attribute( name, value )
    @node.attributes[ name ] = value
  end

end

class XmlList < Array
  def initialize( content, target_object, target_property )
    @target_object = target_object
    @target_property = target_poperty
    super( content )
  end

  def method_missing( name, *args )
    name = name.to_s
    if (args.size > 0)
      self[0].send( name, args )
    else
      self[0].send(name)
    end
  end
end

class AttributeName
  def initialize( name )
    @name = name
  end

  def to_s
    "@#{@name}"
  end
end


# test

x = xml %Q{
<people frog="friends">
<person username="trans">
  <name>Tom</name>
  <age>35</age>
</person>
<person username="jenasmom">
  <name>Becky</name>
  <age>32</age>
</person>
</people>
}

p x
puts x.people


