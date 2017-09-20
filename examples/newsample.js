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
twice = (f)->{
  (x)->{
    f(f(x))
  }
}
add_three = (x)->{3+x}
//add_three_twice = (x)->{twice(add_three)(x)}
print("Should be 13")
//print(add_three_twice(7))
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
