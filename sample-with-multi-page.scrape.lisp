go "https://news.example.com"
set :all_links grablinks
set :matched_links ( parselinks &all_links /a[href=somepattern]/ )
arr :scrape_data
for &matched_links :link {
  go &link
  arr :body_parts
  push :body_parts ( grabcss "pages:0" )
  set :counter 0
  loop {
    if ( has_element? ".next_page" ) {
      set :counter ( + 1 &counter )
      click ".next_page"
      push :body_parts ( grabcss &counter )
    } { break }
  }
  set :body ( join &body_parts )
  map :scraped_page
  setmap :scraped_page :url &link
  setmap :scraped_page :title ( grabcss "h1" )
  setmap :scraped_page :body &body
  push :scrape_data &scraped_page
}
json &scrape_data
