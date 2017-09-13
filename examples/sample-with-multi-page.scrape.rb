# Sample scrape with multi-page articles
go "https://news.example.com"
all_links = grablinks
matched_links = parseLinks({
  links: all_links,
  regex: /a[href=somepattern]/
})
scrape_data = []
matched_links.each do |link|
  go link
  body_parts = []
  body_parts.push grabcss(".article-content")
  page = 1
  loop do
    break if !has_element?(".next_page")
    click ".next_page"
    page = page + 1
    body_parts.push grabcss(".article-content")
  end
  body = body_parts.join
  scrape_data.push {
    url: link,
    title: grabcss("h1"),
    body: body
  }
end
scrape_data.to_json
