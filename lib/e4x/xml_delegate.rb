
class Xml #< BlankSlate

  class XmlDelegate

    include Enumerable

    def initialize( x )
      @x = x
    end

    def node ; @x.__node      ; end
    def name ; @x.__node.name ; end
    def text ; @x.__node.text ; end

    def klass      ; @x.__class                  ; end
    def parent     ; @x.__parent                 ; end
    def attributes ; @x.__node.attributes        ; end
    def value      ; @x.__node.children.join('') ; end

    #
    def get(prop)
      if Integer === prop
        l = to_XmlList
        return l.__get__(prop)
      end
      n = prop.self.to_XmlName
      l = XmlList.new([],@x,n)
      if AttributeName === n
        @x.attributes.each { |a|
          if ( ( n.name.local_name =='*' ||  n.name.local_name == a.name.local_name ) and
               ( n.name.uri == nil || n.name.uri == a.name.uri ) )
            l.append(a)
          end
        }
        return l
      end
      (0...length).each { |k|
        if ( (n.local_name == '*') or
             ((Element === @x[k]) and (@x[k].name.local_name == a.name.local_name)) ) and
           ( (n.uri == nil) or ((@x[k].__class__ == "element") and (n.uri == @x[k].name.uri)) )
          l.append(@x[k])
        end
      }
      return l
    end

#     def get( prop )
#       if prop.kind_of?(Integer)
#         l = to_XmlList
#         return l.self.get( prop )
#       end
#       #n = prop.to_XmlName
#       l = XmlList.new([], @x, prop)
# #       if prop =~ /^[@_]/
# #         @x.__node.attributes.each{ |a|
# #           l.self.append a
# #         }
# #         return l
# #       end
#       REXML::XPath.each( @x.__node, prop.to_s ) { |elem|
#         l.self.append( Xml.new( elem ) )
#       }
#       return l
#     end

#     def put( key, val )
#       if key =~ /^[@_]/
#         @x.__node.attributes[ key.shift ] = value
#       elsif gk = get(key)
#         case gk.size
#         when 0
#           add "<#{key}>#{val}</#{key}>"
#         when 1
#           gk[0]  #?
#         else
#           raise "unimplemented"
#           #? What to do then?
#         end
#       else
#         insert( key, val )
#       end
#     end

    #
    def put( prop, val )
      if !(Xml === val or XmlList === val) or ( [:text,:attribute].include?(val.self.class) )
        c = val.to_s
      else
        c = val.self.deepcopy
      end
      raise ArgumentError if Numeric === prop
      return if [:text,:attribute,:comment,:instruction].include?( klass )
      n = prop.to_XmlName
      default_namespace = get_default_namespace()
      if AttributeName === n
        return unless is_XmlName(n.self.name)
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
          if (n.name.local_name == j.name.local_name) and (n.name.uri == nil or n.name.uri == j.name.uri)
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
        if ( (n.local_name == '*') or ( (@x[k].classification == :element) and (@x[k].name.locall_name == n.local_name) ) ) and
           ( (n.uri == nil) or ( (@x[k].classification==:element) and (n.uri == @x[k].name.uri) ) )
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

    def add( nodes )
      case nodes
      when XmlList
        nodes.each { |n| @x.__node << n.__node }
      else
        @x.__node << nodes.__node
      end
      @x
    end

    #
    def delete(prop)
      raise ArgumentError if Numeric === prop
      n = prop.self.to_XmlName
      if AttributeName === n
        attribs = attributes.collect{|a|
          if ((n.name.local_name == '*') or (n.name.local_name == a.name.local_name)) and
             ((n.name.uri == nil) or (n.name.uri == a.name.uri))
            a.parent = nil
            nil
          else
            a
          end
        }.compact
        return true
      end
      dp = 0
      (0...length).each { |q|
        if ((n.local_name == '*') or
           (@x[q].self.class == :element and @x[q].self.name.local_namespace == n.local_name)) and
           ((n.uri == nil) or (@x[q].self.class == :element and n.uri == @x[q].self.name.uri))
          x[q].parent = nil
          x.delete_at(q)
          dp+=1
        else
          if dp > 0
            @x[q - dp] = x[q]
            @x.delete_at(q)
          end
        end
      }
      return true
    end

    #
    def delete_by_index(prop)
    end

    #
    def default_value
    end

    #
    def has_property
    end

    #
    def deep_copy
    end

    #
    def descendents(prop)
    end

    #
    def equals(value)
    end

    #
    def resolve_value
      @x
    end

    #
    def insert(prop,value)
    end

    #
    def replace(prop,value)
    end

    #
    def add_in_scope_namespace__(namespace)
    end

    def delete( key )
      @x.__node.delete_element( key ) #string key is an xpath
    end


    # Conversions

    def to_XmlList
      XmlList.new( @x )
    end

#     def to_XmlList
#       target_object = self.__parent__
#       target_poperty = self.__name__
#       l = XmlList.new([self], target_object, target_property)
#     end

    def to_XmlName
      s = to_String
      if s =~ /^[_@]/
        to_AttributeName( s.shift )
      else
        QName.new(s)
      end
    end

    def to_String
      return value if [:attribute, :text].include?(@x)
      if has_simple_content
        s = ''
        @x.each { |e| s << e unless [:comment,:instruction].include?(e.self.class) }
        return s
      else
        to_XmlString
      end
    end

    def to_XmlString( ancestor_namespaces=nil, indent_level=nil )

    end

  end

end
