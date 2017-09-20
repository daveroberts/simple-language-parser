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
person = {first_name: "David"}
person[:last_name] = "Smith"
person[2+2] = "My four value"
person[2+3] = person[2+2]
print(person)
while a==b {
  a + b
}
twice = (f)->{
  (x)->{
    f(f(x))
  }
}
(a,b,c)->{a+b+c}
f(f(2),f(3,7),4)
x = 1
x = 1 + x
x = 1+2*3
x = 4+3*x+2*x
x = x+3*x+2*x
x = 3*x+2*x
4
x[:one] = 11
str = `multi-
line`

//pi = 3.14
push(days, 'Thursday')
loop {
  break
}
