x=2
y = x+2
print(join(["x=",x," y=",y]))

square = (x)->{x*x}
twice = (f)->{
  (x)->{
    f(f(x))
  }
}
fourth_power = (x)->{twice(square)(x)}
x=2+1+1+2
print(join(["Should be ",x*x*x*x,": ", fourth_power(x)]))

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

days = ['Monday','Tuesday','Wednesday']
push(days, 'Thursday')
foreach day in days {
  print(join(['Good morning ', day]))
}

names = ["Alice","Bob","Eve"]
map = (col, f)->{
  arr=[]
  foreach item in col {
    push(arr, f(item))
  }
  arr
}
people = map(names, (name)->{ {first_name: name, job: 'Security Researcher'} })

foreach person in people {
  print(join([person[:first_name], " is a ", person[:job]]))
}

//pi = 3.14

animals = ["lion","tiger","bear","dog","cat"]
push(animals, "monkey")
family = map(["John","Jacob","Mary","Maggie"], (name)->{ {first_name: name} })
foreach person in family {
  person[:last_name] = "Smith"
}
pet = (person, animal)->{
  print(join([person[:first_name]," owns a ",animal]))
}
pet(family[0], animals[0])
counter = 0
loop {
  counter = counter + 1
  print(join([animals[counter]," is my favorite animal"]))
  if counter > 3 { break }
}
