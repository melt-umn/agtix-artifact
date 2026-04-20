def a =
  letrec
    x = y,
    y = z,
    z = 1
  in
    x + y + z
