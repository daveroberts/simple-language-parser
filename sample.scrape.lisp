; Sample scrape
go "https://news.example.com"
set :all_links grablinks
set :matched_links parselinks &all_links /a[href=somepattern]/
array :scrape_data
for &matched_links :link {
  go &link
  hashmap :scraped_page
  setmap :scraped_page :url &link
  setmap :scraped_page :title grabcss "h1"
  setmap :scraped_page :body grabcss ".article-content"
  push :scrape_data &scraped_page
}
json &scrape_data
