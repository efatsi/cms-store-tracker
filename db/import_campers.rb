require 'csv'

# Run with: bin/rails runner db/import_campers.rb

CSV_PATH = Rails.root.join('db', 'campers.csv')

imported = 0

CSV.parse(File.read(CSV_PATH, encoding: 'bom|utf-8').gsub("\r\n", "\n"), headers: true).each do |row|
  first = row[0]&.strip
  last  = row[1]&.strip
  next if first.blank? || last.blank?

  name = "#{first} #{last}"
  Camper.find_or_create_by!(name: name)
  puts "  #{name}"
  imported += 1
end

puts "\nDone! #{imported} campers imported (#{Camper.count} total)."
