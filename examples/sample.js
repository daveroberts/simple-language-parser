print("Hello World")
// "Hello World"

// Variables and math
x=2
y = x+2
// join takes an array and smooshes it into a string
msg = join(["x=",x," y=",y])
print(msg)
// x=2 y=4

// functions
square = (x)->{x*x}
print(square(10))
// 100
squares = map([1,2,3,4,5],square)
// squares = [1,4,9,16,25]

// higher order functions

// repeat a function n times
repeat = (f, n)->{
  counter = 0
  while counter != n {
    f()
    counter = counter + 1
  }
}
say_hello = ()->{ print("こんにちは世界") }
print("Hello World in Japanese, three times")
repeat(say_hello, 3)
// こんにちは世界
// こんにちは世界
// こんにちは世界

// Another higher order function example
// twice takes a function `f` as a parameter, and returns a function which will
// take an argument, run it through `f`, then take the output and run it through
// `f` again
twice = (f)->{ (x)->{ f(f(x)) } }

// We can define the fourth power as running square twice
fourth_power = (x)->{twice(square)(x)}

print(join(["Should be ",6*6*6*6,": ", fourth_power(6)]))
// Should be 1296: 1296

// Foreign function interface
// You can register your own methods and use them in your script
// See run.rb to see where `foreign_func` is defined
print(join(["Foreign function returned: ",foreign_func(2,3)]))
// Foreign function returned: 36

// Recursive function definition
// Fibonacci sequence
fib = (n)->{
  if n == 0 {
    0
  } elsif n == 1 {
    1
  } else {
    fib(n-1) + fib(n-2)
  }
}
counter=0
while counter < 3*2*1 {
  print(join(["fib ",counter,": ",fib(counter)]))
  counter = counter + 1
}
// fib 0: 0
// fib 1: 1
// fib 2: 1
// fib 3: 2
// fib 4: 3
// fib 5: 5

// array operations and foreach loop
days = ['Monday','Tuesday','Wednesday']
push(days, 'Thursday')
foreach day in days {
  print(join(['Good morning ', day]))
}
// Good morning Monday
// Good morning Tuesday
// Good morning Wednesday
// Good morning Thursday

// Loop
counter = 0
loop {
  counter = counter + 1
  if counter > 10 { break }
}
print(join(["Counter: ",counter]))
// Counter: 11

// While loop
while counter != 0 {
  counter = counter - 1
}
print(join(["Counter: ",counter]))
// Counter: 0
