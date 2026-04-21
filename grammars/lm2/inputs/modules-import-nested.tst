module A {
  def a = 1
  module B {
    def b = 1
  }
  import B
  def c = a + b
}
