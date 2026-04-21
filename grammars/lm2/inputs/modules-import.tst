module A {
  def a = 1
  def c = a
}

module B {
  import A
  def c = a
}
