; Sample scrape
go "https://news.example.com"
set :all_links grablinks
set :matched_links parselinks &all_links /a[href=somepattern]/
set :scrape_data ( )
fun :scrape_page ( :link ) {
  go &link
  return obj {
    :url        &link
    :title      grabcss "h1"
    :body       grabcss ".article-content"
  }
}
;for &matched_links :matched_link {
;  push :scrape_data call :scrape_page ( &matched_link )
;}
set :scrape_data map &matched_links :l { call :scrape_page ( :l ) }
json &scrape_data
