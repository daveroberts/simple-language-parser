; Stack oriented scrape
"https://news.example.com" go
grablinks :all_links set
/a[href=somepattern]/ &all_links parselinks :matched_links set

( ) :scrape_data set
{
  &link go
  {
    :url   &link
    :title grabcss "h1"
    :body  grabcss ".article-content"
  } obj &scrape_data push
} ( :link ) &matched_links each

&scrape_data json
