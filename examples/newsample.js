say_hello = ()->{ print("Guten Tag") }
twice = (f)->{
  (x)->{
    f(f(x))
  }
}
add_three = (x)->{3+x}
add_three_twice = (x)->{twice(add_three)(x)}
print("Should be 13")
print(add_three_twice(7))
say_hello = (name)->{ print(join(["Guten Tag ",name])) }
again = (f)->{(x)->{f(x) f(x)}}
double_hello = again(say_hello)
double_hello("Joe")
//double_hello = (name)->twice(say_hello)(name)
//double_hello("Joe")

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
while counter != 21 {
  print(join([counter,": ",fib(counter)]))
  counter = counter + 1
}

f = (x)->{
  return x + 1
}

print(f(2))


if 4 == 2*2 {
  print("Should print")
} else {
  print("Should not print")
}

if false {  }

person = {first_name: "David"}
print("Person:")
print(person)
person[:last_name] = "Smith"
person[2+2] = "My four value"
person[2+3] = person[2+2]
print(person)
f = (a)->{
  a+1
}
x=f(5)
days = ['Monday','Tuesday','Wednesday']
push(days, 'Thursday')
foreach day in days {
  print(join(['Good morning ', day]))
}
map = (col, f)->{
  arr=[]
  foreach item in col {
    push(arr, f(item))
  }
  arr
}
days = map(days, (d)->{{day: d}})
print(days)
b = 10
a = 10
while a==b {
  a = 1
}
(a,b,c)->{a+b+c}
x=1
x = 1 + x
x = 1+2*3
x = 4+3*x+2*x
x = x+3*x+2*x
x = 3*x+2*x
4

//pi = 3.14
push(days, 'Thursday')
loop {
  break
}
