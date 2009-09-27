
# Defines QName and AttributeName classes.

class QName

  class << self

    alias :__new :new

    def new( name_or_namespace, name=nil )
      case name_or_namespace
      when QName
        return name_or_namespace
      when nil
        if QName === name or name.class == "QName"
          return name.dup
        else
          __new(name_or_namespace, name)
        end
      else
        __new(name_or_namespace, name )
      end
    end

  end

  attr :name
  attr :local_name
  attr :uri
  attr :prefix

  def initialize( namespace, name )
    @name = name.local_name.to_s # to_String
    case namespace
    when nil, ''
      namespace = (name == '*' ? nil : get_default_namespace )
    end
    @local_name = name
    unless namespace
      @uri = nil
      @prefix = nil
    else
      namespace = Namespace.new( namespace )
      @uri = namespace.uri
      @prefix = namespace.prefix
    end
  end

  #
  def to_s
    s = ''
    if uri != ''
      unless uri
        s = '*::'
      else
        s = "#{uri}::"
      end
    end
    "#{s}#{local_name}"
  end

  #
  def get_namespace( in_scope_namespaces=nil )
    raise 'no uri [should not have occured]' unless uri
    in_scope_namespaces ||= []
    ns = in_scope_namespaces.find { |n| uri == n.uri }  # prefix == n.prefix ?
    ns = Namespace.new( uri ) unless ns  # or ns = Namespace.new( prefix, uri ) ?
    ns
  end

end


class AttributeName

  attr :name

  def initialize( s )
    @name = QName.new(s)
  end

  def to_s
    "@#{@name}"
  end

end

