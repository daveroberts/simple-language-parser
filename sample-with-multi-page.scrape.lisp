; Sample scrape with multi-page articles
go "https://news.example.com"
set :all_links grablinks
set :matched_links parselinks &all_links /a[href=somepattern]/
set :scrape_data ( )
each &matched_links :link {
  go &link
  set :body_array ( )
  push &body_array grabcss ".article-content-page-1"
  set :page 1
  loop {
    if ! has_element? ".next_page" { break } { }
    click ".next_page"
    set :page + 1 &page
    push &body_array grabcss join ( ".article-content-page-" &page )
  }
  set :body join &body_array
  push &scrape_data obj {
    :url &link
    :title grabcss "h1"
    :body &body
  }
}
json &scrape_data
