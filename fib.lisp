; Recursion for fun
fun :fib ( :n ) {
  if = &n 1 { return 0 } {
    if = &n 2 { return 1 } {
      return +
        call :fib ( - &n 1 )
        call :fib ( - &n 2 )
    }
  }
}

call :fib ( 10 )