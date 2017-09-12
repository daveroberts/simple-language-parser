; Stack oriented scrape
"https://news.example.com" go
grablinks :all_links set
/a[href=somepattern]/ :all_links parselinks :matched_links set
( ) :scrape_data set
{
  &link go
  {  :url   &link
     :title grabcss "h1"
     :body  grabcss ".article-content" } hashmap :scraped_page set
  &scraped_page return
} ( :link ) :scrape_page fun
{
  ( &matched_link ) :scrape_page call :scrape_data push
} :matched_link &matched_links for
&scrape_data json