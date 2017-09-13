; Sample program that shows off syntax
set animals ( "lion" "tiger" "bear" "dog" "cat" )
push animals "monkey"
set family map ( "John" "Jacob" "Mary" "Maggie" ) name { obj { :firstname name } }
each family person {
  setprop person :lastname "Smith"
}
set pet fun ( person animal ) {
  join ( getprop person :firstname " owns a " animal "!" )
}
call pet ( first family first animals )
set counter 0
loop {
  set counter + 1 counter
  getitem animals counter
  if ! = counter 1 { break } { }
}
json family
