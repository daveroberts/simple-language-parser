# Sample scrape
go "https://news.example.com"
all_links = grablinks
matched_links = parseLinks(all_links, /a[href=somepattern]/)
scrape_data = []
matched_links.each do |link|
  go link
  scraped_page = {
    url: link,
    title: grabcss("h1"),
    body: grabcss(".article-content")
  }
  scrape_data.push scraped_page
end
scrape_data.to_json
