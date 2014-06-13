# Intro
# -----
#
# This bot scrapes procurement data for Uganda from [http://ppda.go.ug/tenderportal/](http://ppda.go.ug/tenderportal/)
#
# Prerequisites
# -------------
#
# Load any gems you need first. Here we'll use `chronic` for date parsing,
# `httpclient` and `nokogiri` to fetch and query the html pages and some 
# helper methods from the `openc_bot` gem maintained by OpenCorporates.
require 'active_support/core_ext'
require 'chronic'
require 'nokogiri'
require 'httpclient'
# There are a number of helper methods covering text, csv, dates and more.
require 'openc_bot/helpers/text'

# The original source is here  - 'http://ppda.go.ug/tenderportal/'
# We'll use an OpenCorporates hosted copy of the source for the example
BASE_URL = 'http://turbot.opencorporates.com/examples/'

# Fetching the data
# -----------------
#
# In this method, we loop through pages of search results breaking the loop
# when we hit "No matches were found". We're passing these results pages onto
# the `parse_results_page` method.
def get_all_notices
  start_notice = 0
  loop do
    url = BASE_URL + "medium_bot_start=#{start_notice}.html"
    page = HTTPClient.new.get_content(url)
    break if page[/No matches were found/]
    results = parse_results_page(page, url)
    results.each do |result_hash|
      # We then print the resultant hashes out as JSON.
      puts JSON.dump(result_hash)
    end
    start_notice += 15
  end
end

# Extracting the data
# -------------------
#
def parse_results_page(page, source_url)
  doc = Nokogiri::HTML(page)
  # In this case the data we want is in an HTML table
  table_rows = doc.search('table#tenderlisttop tr').to_a.select { |tr| tr.at('td') }
  # We take the cells from the first row as headers, normalising them to `snake_case`. 
  # These will be used as hash keys later on.
  headings = table_rows.shift.search('td').collect{ |td| td.inner_text.downcase.gsub(/[^\w\s]/,'').strip.gsub(/\s/,'_') }
  # We then work through the rest of the rows, building a `key => value` hash based on the column headers.
  results = table_rows.collect do |tr|
    res = tr.search('td').to_a.each.with_index.inject({}) do |hsh, (td, i)|
      # Here we are using helpers from the [OpenCorporates `openc_bot` gem](https://github.com/openc/openc_bot).
      hsh[headings[i]] = OpencBot::Helpers::Text.strip_all_spaces(td.inner_text)
      # The data also contains links to a full text version of the tender notice.
      # Here we record that url for future bots to process at a later date.
      hsh["#{headings[i]}_url"] = (BASE_URL + td.at('a')[:href]) if td.at('a')
      # `source_url` and `sample_date` are required fields for Turbot. We use these
      # to display a provenance for every single piece of data on OpenCorporates.com
      hsh['source_url'] = source_url
      hsh['sample_date'] = Time.now
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

# Here's where the magic happens.
main
