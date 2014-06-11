# Prerequisites
# -------------
# You need to load any gems for your scraper at the top of the
# file. Here we'll be using `json` for output, `mechanize` to fetch
# pages and `nokogiri` to parse and query the HTML
require 'json'
require 'mechanize'
require 'nokogiri'

# Setup
# -----
#
# We'll setup a few variables here to make the code easier to
# edit and reuse. `SOURCE_URL` is the page we want to scrape, 
# and the `agent` variable is setting up Mechanize which is like
# a mini web browser. It will fetch the page and handle things like
# redirects and https for us, returning the HTML source as a string.
SOURCE_URL = "https://www.og.decc.gov.uk/eng/fox/decc/PED301X/companyLookup"
agent = Mechanize.new
agent.user_agent_alias = 'Mac Safari'

# Fetching the page
# -----------------
#
# `agent.get` tells Mechanize to retrieve the page for whichever url
# we pass as an argument. This returns a string containing the HTML source 
# of the page
#
# `Nokogiri.parse` changes this string into a Ruby object which we can search
# with CSS or XPath selectors (just like the ones in jQuery)
page = agent.get(SOURCE_URL)
doc = Nokogiri.parse(page.body)


# Extracting the data
# -------------------
# In this page, the data we want is in an HTML table with a class `.setoutList`
# _WATCH OUT_ because CSS queries in Nokogiri are case sensitive
#
# We'll pull out all the rows from the table and put their `td` cells into an array.
# To keep things simple we'll setup our empty array to capture the output and we should
# end up with an array of arrays, one for each row of the table.
output = []
doc.css('.setoutList tr').each do |row| 
  output << row.css('td').map {|r| r.text }
end

# Outputting the data
# -------------------
# The OpenCorporates Turbot system is very simple and only requires you
# to output some JSON for each record you capture.
# Here we'll go through the output rows and make a Ruby Hash with the hash keys becoming the
# field names. In this scraper it's very simple as there are only two columns in the source
# table.
#
# `JSON.dump` is part of the Ruby standard library. All it does is convert the Ruby Hash to a
# JSON friendly string, suitable for printing out.
output.each do |row|
  datum = {
    company_name: row[0], 
    company_number: row[1],
    sample_date: Time.now.iso8601(2),
    source_url: SOURCE_URL
  }

  puts JSON.dump(datum) 
end
