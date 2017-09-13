; Recursion for fun
set :fib fun ( :n ) {
  if = &n 0 { return 0 } {
    if = &n 1 { return 1 } {
      return +
        call :fib ( - &n 1 )
        call :fib ( - &n 2 )
    }
  }
}

set :counter 1
loop {
  print join ( &counter ":" call :fib ( &counter ) )
  if = &counter 10 { break } { }
  set :counter + 1 &counter
}
