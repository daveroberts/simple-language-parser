; Sample scrape
go "https://news.example.com"
set :all_links grablinks
set :matched_links parselinks &all_links /a[href=somepattern]/

set :scrape_data ( )
each &matched_links :link {
  go &link
  push &scrape_data obj {
    :url   &link
    :title grabcss "h1"
    :body  grabcss ".article-content"
  }
}

json &scrape_data
