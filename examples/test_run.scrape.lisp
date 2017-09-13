go "https://news.example.com"
set :links parselinks grablinks /a[href=somepattern]/
set :link first &links
go &link
json obj {
  :url   &link
  :title grabcss "h1"
  :body  grabcss ".article-content"
}
