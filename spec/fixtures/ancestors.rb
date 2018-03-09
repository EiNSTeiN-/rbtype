
class Foo < Struct.new(:attr)
end

class Bar < Foo
end

class NoParent
end

class NoDef::Foo
end

module NotAClass
end
