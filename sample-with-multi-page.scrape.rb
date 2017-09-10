go "https://news.example.com"
all_links = grablinks
matched_links = parseLinks(all_links, /a[href=somepattern]/)
scrape_data = []
matched_links.each do |link|
  go link
  body_parts = []
  body_parts.push grabcss(".article-content")
  if has_element? ".next_page"
    click ".next_page"
    body_parts.push grabcss(".article-content")
  end
  body = body_parts.join
  scraped_page = {
    url: link,
    title: grabcss("h1"),
    body: body
  }
  scrape_data.push scraped_page
end
scrape_data.to_json