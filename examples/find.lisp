; Sample program that shows off syntax
set animals ( "lion" "tiger" "bear" "dog" "cat" )
fun find ( collection target ) {
  each collection item {
    if = item target { return true } { }
  }
  return false
}

map ( "tiger" "bear" "kitty" ) animal {
  join ( animal " is" if find animals animal { " " } { " not " } "in the list" )
}

fun list ( collection announcement ) {
  each collection item {
    print announcement item
  }
}

fun bark ( boobah ) {
  join ( boobah " says woof" )
}

list animals &bark
