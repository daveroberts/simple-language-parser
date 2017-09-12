# Sample scrape in Ruby
go "https://news.example.com"
all_links = grablinks
matched_links = parseLinks(all_links, /a[href=somepattern]/)

scrape_data = []
matched_links.each do |link|
  go link
  scrape_data.push {
    url:   link,
    title: grabcss("h1"),
    body:  grabcss(".article-content")
  }
end

scrape_data.to_json
