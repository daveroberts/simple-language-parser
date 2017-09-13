; Recursion for fun
{
  {
    {
      ( 1 &n - ) :fib call
      ( 2 &n - ) :fib call + return
    } { 1 return } 1 &n = if
  } { 0 return } 0 &n = if
} ( :n ) :fib fun

1 :counter set
{
  ( ( &counter ) :fib call ":" &counter ) join print
  { } { break } 10 &counter = if
  1 &counter + :counter set
} loop
