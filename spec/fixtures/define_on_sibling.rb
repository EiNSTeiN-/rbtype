# A::A::B
class A
  class A::B; end
end
class A
  # depending on load order, either A::B or A::A::B will be defined.
  class A; end
end
