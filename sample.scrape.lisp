go "https://news.example.com"
set :all_links grablinks
set :matched_links ( parselinks ( get :all_links ) /a[href=somepattern]/ )
arr :scrape_data
loop ( get :matched_links ) :link {
  go ( get :link )
  map :scraped_page
  setmap :scraped_page :url ( get :link )
  setmap :scraped_page :title ( grabcss "h1" )
  setmap :scraped_page :body ( grabcss ".article-content" )
  push :scrape_data ( get :scraped_page )
}
json ( get :scrape_data )