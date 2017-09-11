; Sample scrape with multi-page articles
go "https://news.example.com"
set :all_links grablinks
set :matched_links parselinks &all_links /a[href=somepattern]/
array :scrape_data
for &matched_links :link {
  go &link
  array :body_array
  push :body_array grabcss ".article-content-page-1"
  set :page 1
  loop {
    if has_element? ".next_page" {
      click ".next_page"
      set :page + 1 &page
      push :body_array grabcss join ( ".article-content-page-" &page )
    } { break }
  }
  set :body join &body_array
  hashmap :scraped_page
  setmap :scraped_page :url &link
  setmap :scraped_page :title grabcss "h1"
  setmap :scraped_page :body &body
  push :scrape_data &scraped_page
}
json &scrape_data
