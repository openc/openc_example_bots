# Prerequisites
# -------------
#
# Load any gems you need first. Here we'll use `chronic` for date parsing,
# `httpclient` and `nokogiri` to fetch and query the html pages and some 
# helper methods from the `openc_bot` gem maintained by OpenCorporates
require 'active_support/core_ext'
require 'chronic'
require 'nokogiri'
require 'httpclient'
# There are a number of helper methods covering text, csv, dates and more
require 'openc_bot/helpers/text'

BASE_URL = 'http://ppda.go.ug/tenderportal/'

# Fetching the data
# -----------------
#
# In this method, we loop through pages of search results breaking the loop
# when we hit "No matches were found". We're passing these results pages onto
# the `parse_results_page` method
def get_all_notices
  start_notice = 0
  loop do
    url = BASE_URL + "listofawarded-contracts.html?start=#{start_notice}"
    page = HTTPClient.new.get_content(url)
    break if page[/No matches were found/]
    results = parse_results_page(page)
    results.each do |result_hash|
      # We then print the resultant hashes out as JSON
      puts JSON.dump(result_hash)
    end
    start_notice += 15
  end
end

# Extracting the data
# -------------------
#
def parse_results_page(page)
  doc = Nokogiri::HTML(page)
  # In this case the data we want is in an HTML table
  table_rows = doc.search('table#tenderlisttop tr').to_a.select { |tr| tr.at('td') }
  # We take the cells from the first row as headers, normalising them to `snake_case`. 
  # These will be used as hash keys later on
  headings = table_rows.shift.search('td').collect{ |td| td.inner_text.downcase.gsub(/[^\w\s]/,'').strip.gsub(/\s/,'_') }

  # We then work through the rest of the rows, building a `key => value` hash based on the column headers
  results = table_rows.collect do |tr|
    res = tr.search('td').to_a.each.with_index.inject({}) do |hsh, (td, i)|
      hsh[headings[i]] = OpencBot::Helpers::Text.strip_all_spaces(td.inner_text)
      # We add an extra value to record the source url for this piece of data
      hsh["#{headings[i]}_url"] = (BASE_URL + td.at('a')[:href]) if td.at('a')
      hsh
    end
  end
end

# Running the scraper
# -------------------
#
# As this is executed as a single Ruby file, we need to make sure we call some methods!
# We'll use an old convention from C programming and wrap the work in a main method, which
# is then run straight away.
def main
  get_all_notices
end

# Here's where the magic happens
main
