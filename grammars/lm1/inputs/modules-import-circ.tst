module A {
  import B
  def a = b
}

module B {
  import A
  def b = a
}
