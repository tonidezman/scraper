require 'date'
require 'nokogiri'
require 'csv'
require 'rainbow'
require 'pry'

require_relative 'capybara-setup'

#######################
###### CONSTANTS ######
#######################
can_filter_jobs = true
end_with_page_number = 20
filtered_jobs = [
  "program",
  "aplikaci",
  "sistem",
  "razvoj",
  "inform",
  "podatk",
  "razvijal",
]

# truncate "file.csv"
File.open('file.csv', 'w') {}

browser = Capybara.current_session
url = "https://www.ess.gov.si/iskalci_zaposlitve/prosta_delovna_mesta/seznam"
browser.visit url
select_id = "ctl00_centerContainer_ctl01_StZadetkov1_DropDownList1"
browser.select("100", from: "#{select_id}")
browser.click_link("Datum objave")
sleep 3
browser.click_on("Datum objave")

def is_included_in_filter(job_description, filtered_jobs)
  return_value = false
  filtered_jobs.each do |job|
    if job_description.downcase.include?(job)
      return_value = true
      break
    end
  end
  return_value
end

def ljubljana_or_date?(td)
  if td.text.match(/LJUBLJANA/)
    is_ljubljana_or_date = true
  # else
  #   begin
  #     if Date.parse(td.text)
  #       is_ljubljana_or_date = true
  #     end
  #   rescue ArgumentError
  #     is_ljubljana_or_date = false
  #   end
  end
  return is_ljubljana_or_date
end

def find_jobs(table_rows, can_filter_jobs, filtered_jobs)
  CSV.open("file.csv", "a+") do |csv|
    date_indx = 2
    city_indx = 3
    table_rows.each.with_index do |tr, i|
      next if i == 0 # skip table header

      counter = 0
      row_data = []
      tr.all('td').each do |td|
        if counter == date_indx
          begin
            if Date.parse(td.text)
              current_date = Date.parse(td.text)
            end
          rescue ArgumentError
          end
        end

        if counter == city_indx
          break unless ljubljana_or_date?(td)
        end

        row_data << td.first('a')['href'] if counter == 0
        row_data << td.text

        if counter == 4
          # scan for keywords
          job_description = row_data[1]
          if can_filter_jobs
            if is_included_in_filter(job_description, filtered_jobs)
              puts Rainbow("#{row_data[1]} => #{row_data[3]}\n").green
              csv << row_data
            else
              puts Rainbow("#{row_data[1]} => #{row_data[3]}\n")
            end
          else
            puts "#{row_data[1]} => #{row_data[3]}\n"
            csv << row_data
          end
        end
        counter += 1
      end
    end
  end
end

today = DateTime.now.to_date
current_date = DateTime.now.to_date
current_page = 1

# first page has disabled first pager link
table_rows = browser.find(".results").all('tr')
find_jobs(table_rows, can_filter_jobs, filtered_jobs)
current_page += 1

while current_page <= end_with_page_number
  browser.find(".cc-gv-pagination.cc-gv-bottom.pager").click_link(current_page)
  sleep 3
  table_rows = browser.find(".results").all('tr')
  find_jobs(table_rows, can_filter_jobs, filtered_jobs)
  current_page += 1
end


puts "***********************"
puts "  FINITO MY MASTERINO  "
puts "***********************"