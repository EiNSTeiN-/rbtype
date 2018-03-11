
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


class A; end
class B; end

class C < A; end
class C < B; end
class C < Z; end
