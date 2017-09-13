go "https://news.example.com"
json parselinks obj {
  :links grablinks
  :regex /a[href=somepattern]/
}
