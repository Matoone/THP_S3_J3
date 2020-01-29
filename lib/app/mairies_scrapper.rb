class MairiesScrapper
  attr_accessor :emails, :townhalls_urls
  def initialize
    @emails = []
    @townhalls_urls = {}
  end

  def get_townhalls_urls
    puts 'Getting urls ...'
    links = {}
    page = Nokogiri::HTML(open('http://annuaire-des-mairies.com/val-d-oise.html'))
    table = page.xpath('//a[@class="lientxt"]')
    table.each do |link|
      name = link.text
      lnk = link.xpath('@href').to_s
      lnk_formatted = lnk.sub('.', 'http://annuaire-des-mairies.com')
      links[name.downcase.strip.gsub(' ', '_')] = lnk_formatted
    end
    puts 'Got the urls ! Still working...'
    @townhalls_urls = links
  end

  def get_townhall_email(townhall_url)
    page = Nokogiri::HTML(open(townhall_url))
    tds = page.xpath('//td')
    ar = []
    begin
      ar = tds.select { |td| td.text =~ /.+@.+\.\w+/ }
    rescue StandardError => e
      puts "Certains emails n'existent pas. Poursuite de la recherche..."
    end
    if !ar.empty?
      ar[0].text.strip
    else
      ''
    end
  end

  def get_all_emails
    puts 'La recherche a débuté...'
    emails = []
    @townhalls_urls.each do |key, value|
      mail = get_townhall_email(value)
      h = {}
      h[key] = mail
      emails.push(h)
    end
    puts 'Got the emails! '
    @emails = emails
  end

  def save_as_JSON
    puts "Saving emails to JSON..."
    File.open("db/emails.json","w") do |f|
      f.write(@emails.to_json)
    end
    puts "Done! The file is at db/emails.json"
  end

  def save_as_spreadsheet
    puts "Saving emails to Google Spreadsheet..."
    session = GoogleDrive::Session.from_service_account_key("config.json")
    spreadsheet= session.spreadsheet_by_title("Emails")
    worksheet = spreadsheet.worksheets.first
    # worksheet.rows.each { |row| puts row.first(6).join(" | ") }
    # worksheet.insert_rows(2, [["Hello!", "This", "was", "inserted", "via", "Ruby"]])
      
    @emails.each_with_index do |element,index|
    element.each{|key, value| worksheet.insert_rows(index+1, [[key, value]])} 
    end
    worksheet.save
    puts "Done! Here is the link to access the results : https://docs.google.com/spreadsheets/d/1nJ6fAx8H6CL5dHNgFLtEi-dp2UL4gis6uGEzkpNAk6U/edit?usp=sharing"
  end

  def save_as_csv
    puts "Saving emails to CSV..."
    data = @emails.map{|c| c.map{|key, value| "#{key},#{value}"}}.join("\n")
    File.open("db/emails.csv", "w") do |f|
    f.write(data)
    end
    puts "CSV file generated in db/emails.csv !"
  end

  def menu
    choice = ""
    while choice != "1" && choice != "2" && choice != "3" && choice != "4"
      puts "Welcome to that townhalls emails scrapper!"
      puts "What format do you want as a result?"
      puts ""
      puts "1 - Run scrapper and display results on your terminal without saving them."
      puts "2 - Run scrapper and save results as JSON file."
      puts "3 - Run scrapper and upload results as GoogleDrive spreadSheet."
      puts "4 - Run scrapper and save results as CSV file."
      choice = gets.chomp
    end
    choice
  end

  def menu_choice(choice)
    case choice
    when "1"
      get_townhalls_urls
      get_all_emails.each{|entry| puts entry}
    when "2"
      get_townhalls_urls
      get_all_emails
      save_as_JSON
    when "3"
      get_townhalls_urls
      get_all_emails
      save_as_spreadsheet
    when "4"
      get_townhalls_urls
      get_all_emails
      save_as_csv
    else
      puts "Error detected: that choice doesn't exists!"
    end
  end

  def perform
    menu_choice(menu)
  end
end