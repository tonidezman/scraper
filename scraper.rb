require 'date'
require 'nokogiri'
require 'csv'
require 'pry'

require_relative 'capybara-setup'

browser = Capybara.current_session
url = "https://www.ess.gov.si/iskalci_zaposlitve/prosta_delovna_mesta/seznam"
browser.visit url
select_id = "ctl00_centerContainer_ctl01_StZadetkov1_DropDownList1"
browser.select("100", from: "#{select_id}")
browser.click_link("Datum objave")
sleep 3
browser.click_on("Datum objave")

table_rows = browser.find(".results").all('tr')

work_name_indx = 0
employer_indx = 1
date_indx = 2
city_indx = 3

def ljubljana_or_date?(td)
  if td.text.match(/LJUBLJANA/)
    is_ljubljana_or_date = true
  else
    begin
      if Date.parse(td.text)
        is_ljubljana_or_date = true
      end
    rescue ArgumentError
      is_ljubljana_or_date = false
    end
  end
  return is_ljubljana_or_date
end

# truncate "file.csv"
File.open('file.csv', 'w') {}

CSV.open("file.csv", "a+") do |csv|
  table_rows.each.with_index do |tr, i|
    next if i == 0 # skip table header

    counter = 0
    row_data = []
    tr.all('td').each do |td|
      if counter == city_indx
        break unless ljubljana_or_date?(td)
      end

      row_data << td.first('a')['href'] if counter == 0
      row_data << td.text

      if counter == 4
        csv << row_data
      end
      counter += 1
    end
  end
end

puts "***********************"
puts "  FINITO MY MASTERINO  "
puts "***********************"