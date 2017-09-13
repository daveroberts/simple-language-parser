; Sample program that shows off syntax
set animals ( "lion" "tiger" "bear" "dog" "cat" )

fun twice ( f ) {
  f f
}

fun add_three ( x ) { + 3 x }

fun add_three_twice ( x ) { twice &add_three 6 }

add_three_twice 2


push animals "monkey"
set family map ( "John" "Jacob" "Mary" "Maggie" ) name { obj { :firstname name } }
each family person {
  setprop person :lastname "Smith"
}
fun pet ( person animal ) {
  join ( getprop person :firstname " owns a " animal "!" )
}
pet first family first animals
set counter 0
loop {
  set counter + 1 counter
  getitem animals counter
  if ! = counter 1 { break } { }
}
json family
