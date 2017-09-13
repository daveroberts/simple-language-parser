; Recursion for fun
fun fib ( n ) {
  if = n 0 { 0 } {
    if = n 1 { 1 } {
      +
        fib - n 1
        fib - n 2
    }
  }
}

set counter 1
loop {
  print join ( counter ":" fib counter )
  if = counter 20 { break } { }
  set counter + 1 counter
}
