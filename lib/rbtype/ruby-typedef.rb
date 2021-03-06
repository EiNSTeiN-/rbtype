module Kernel
end
class BasicObject
end
class Object < BasicObject
  include Kernel
end
class Module < Object
end
class Class < Module
end


class Exception
end
class StandardError < Exception
end
class ArgumentError < StandardError
end
class RuntimeError < StandardError
end
class NameError < StandardError
end
class NoMethodError < NameError
end
class StringIO
end

class Random
end

module Process
end
