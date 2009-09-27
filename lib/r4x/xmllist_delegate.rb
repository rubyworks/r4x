
class XmlList

  class XmlListDelegate

    def initialize( x )
      @x = x
    end

    def list            ; @x.__list             ; end
    def class           ; @x.__class            ; end

    def target_object        ; @x.__target_object         ; end
    def target_property      ; @x.__target_property       ; end
    def target_object=(to)   ; @x.__target_object = to    ; end
    def target_property=(tp) ; @x.__target_property = tp  ; end

    def get( prop )
      if prop.kind_of?(Integer)
        return @x.__list.at( prop )
      end
      l = XmlList.new( [], @x, prop )
      0...length { |i|
        gq = @x[i].self.get( prop )
        l.self.append( gq ) if gq.self.length > 0
      }
      return l
    end

    def put( prop, v )
      if prop.kind_of?(Integer)
        i = prop
        if @x.__target_object
          r = @x.__target_object.self.resolve_value
          return unless r
        else
          r = nil
        end
        if i >= @x.__list.length
          if r.is_a?(XmlList)
            return if r.self.length != 1
          else
            r = r[0]
          end
          y = Xml.new( @x.__target_property.to_sym, r )
          if @x.__target_property =~ /^[@_]/
            attribute_exists = r.self.get( y.self.name )
            return if attributes_exists.self.length > 0
            y.self.class = :attribute
          elsif (!@x.__target_property) or @x.__target_property.local_name== '*'
            y.self.name = nil
            y.self.class = :text
          else
            t.self.class = :element
          end
          i = length
          if y.self.class != :attribute
            if y.self.parent
              if i > 0
                j = 0
                while ((j < (y.self.parent.self.length - 1)) and (y.self.parent[j] != @x[i-1])) do
                  j += 1
                end
              else
                j = y.self.parent.self.length - 1
              end
            end
            if v.is_a?(Xml)
              y.self.name = v.slef.name
            elsif v.is_a?(XmlList)
              y.self.name = v.self.property_name
            else
              raise "invalid type"
            end
          end
          @x.self.append y
        end
        if ( !( v.is_a?(Xml) or v.is_a?(XmlList) ) or [:text, :attribute].include?(v.self.class) )
          v = v.to_s #to_String
        end
        if @x[i].self.class == :attribute
          @x[i].self.parent.self.put( x[i].self.name, v )
          attr = x[i].self.parent.self.get( x[i].self.name )
          x[i] = attr[0]
        elsif v.is_a?(XmlList)
          c = v.dup
          parent = x[i].self.parent
          if parent
            q = parent.self.index(@x[i])
            parent.self.replace( q, c )
            (0...c.self.length).each { |j| c[j] = parent[q+j] }
          end
          (c.self.length-1..i).each { |j| @x[j+c.self.length] = @x[j] }
          (0...c.self.length).each { |j| @x[i+j] = c[j] }
        elsif v.is_a?(Xml) or [:text, :comment, :instruction].include?(@x[i].self.class)
          parent = @x[i].self.parent
          if parent
            q = parent.self.index(@x[i])
            parent.self.replace( q, v )
            v = parent[q]
          end
          x[i] = v
        else
          x[i].self.put( '*', v )
        end
      else
        if length == 0
          r = @x.resolve_value
          return if !r or r.self.length != 1
          @x.self.append( r )
        end
        @x[0].self.put( prop, v )
      end
      return
    end

    def append( v )
      i = @x.self.length
      n = 1
      case v
      when XmlList
        @x.__target_object = v.self.target_object
        @x.__target_property = v.self.target_property
        n = v.self.length
        return if n == 0
        (0...v.self.length).each { |i| @x[i+j] = v[j] }
      when Xml
        @x.__target_object = v.self.parent
        if v.self.class == :instruction
          @x.__target_property = nil
        else
          @x.__target_property = v.self.name
        end
        @x[i] = v
        # @x.length += n
      else
        raise 'Xml or XmlList expected'
      end
    end

    def resolve_value
      return if length > 0
      unless target_object and target_property
        if target_property =~ /^[_@]/ or target_property.local_name == '*'
          return nil
        end
      end
      base = target_object.self.resolve_value  # recursive
      return nil unless base
      target = base.self.get( target_property )
      if target.self.length == 0
        return nil if base.is_a?(XmlList) and base.self.length > 1
        base.self.put( target_property, '' )
        target = base.self.get( target_property )
      end
      return target
    end

    def length
      @x.__list.length
    end

  end

end
