; Sample scrape
go "https://news.example.com"
set :all_links grablinks
set :matched_links parselinks &all_links /a[href=somepattern]/
array :scrape_data
fun :scrape_page ( :link ) {
  go &link
  hashmap :scraped_page
  setmap :scraped_page :url &link
  setmap :scraped_page :title grabcss "h1"
  setmap :scraped_page :body grabcss ".article-content"
  &scraped_page
}
for &matched_links :link {
  push :scrape_data call :scrape_page ( &link )
}

json &scrape_data
