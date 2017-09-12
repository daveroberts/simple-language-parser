; Sample scrape
fun :fib ( :n ) {
  if = &n 0 { return 0 } {
    if = &n 1 { return 1 } {
      return +
        call :fib ( - &n 1 )
        call :fib ( - &n 2 )
    }
  }
}

call :fib ( 2 )