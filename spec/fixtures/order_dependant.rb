
module Test
  class Foo
    class Bar < String; end
  end
end

module Test
  class String; end
end

module Test
  class Foo::Bar < String; end
end
