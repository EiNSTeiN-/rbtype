class Demo1
  # A::B
  class A
    class A::B; end
  end
end

class Demo2
  # A::A::B
  class A
    class A; end
    class A::B; end
  end
end

class Demo3
  # A::A::B
  class A
    class A; end
  end
  class A
    class A::B; end
  end
end

class Demo4
  # A::B
  class A
    class A::B; end
  end
  class A
    class A; end
  end
end
