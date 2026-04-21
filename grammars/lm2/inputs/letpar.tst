def y = 10

def z = 10

def a =
  letpar
    x = y,
    y = z,
    z = 1
  in
    x + y + z
