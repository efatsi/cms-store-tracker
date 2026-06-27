require 'csv'

# Run with: bin/rails runner db/import_products.rb

CSV_PATH = Rails.root.join('db', 'store_products.csv')

SKIP_PATTERNS = [
  /\Ashipping\z/i,
  /set.?up\s+fee/i,
  /screen\s+charge/i,
  /\Aadditional/i,
  /molds?\s*\(/i,
  /total\s+spent/i,
  /\Atotal\z/i,
].freeze

VENDOR_ALIASES = {
  '413 strengthgear' => '413 StrengthGear',
}.freeze

def normalize_vendor(name)
  VENDOR_ALIASES[name.downcase] || name
end

def skip_item?(text)
  return true if text.blank?
  SKIP_PATTERNS.any? { |p| text.match?(p) }
end

# Returns [quantity, cleaned_name]
def parse_item(raw)
  # Strip "($X.XX) each)" pattern first (e.g. "($16.85) each)")
  text = raw.gsub(/\s*\(\s*\$[\d.,]+\s*\)\s*each\)/i, '')
  # Strip remaining price annotations: ($14.99 EA), ( $35 EA), ($2.97)
  text = text.gsub(/\s*\(\s*\$[\d.,]+\s*(?:EA|each)?\s*\)/i, '').strip

  # Extract leading count prefix: "2- ", "50 - ", "16-", "22 ", "25 - "
  if (m = text.match(/\A(\d+)\s*[-–]\s*(.+)\z/m))
    leading = m[1].to_i
    rest    = m[2].strip
  elsif (m = text.match(/\A(\d+)\s+(.+)\z/))
    leading = m[1].to_i
    rest    = m[2].strip
  else
    leading = 1
    rest    = text
  end

  # "- N pack/count/pk" or "N pack" at end of rest → multiply
  if (pm = rest.match(/\s*[-–]?\s*(\d+)\s*(packs?|counts?|pk)\s*\z/i))
    quantity = leading * pm[1].to_i
    name     = rest.sub(pm[0], '').sub(/\s*[-–]\s*\z/, '').strip
  # "(N pack)" anywhere in rest → multiply (e.g. "Shave Cream (3 pack)")
  elsif (pm = rest.match(/\((\d+)\s*pack\)/i))
    quantity = leading * pm[1].to_i
    name     = rest.sub(pm[0], '').strip
  else
    quantity = leading
    name     = rest
  end

  # Final name cleanup: collapse spaces, strip trailing dashes, remove empty parens
  name = name.gsub(/\s+/, ' ').gsub(/\s*[-–]\s*\z/, '').gsub(/\(\s*\)/, '').strip

  [quantity, name]
end

def adult_youth?(name)
  name.match?(/adult/i) && name.match?(/youth/i)
end

# Strip adult/youth descriptors, return base name
def base_name_for_split(name)
  name
    .gsub(/\s*\(\s*adult\s*[&\/]\s*youth\s*\)/i, '')   # (adult & youth)
    .gsub(/\s*adult\s+tank\s*[\/&]?\s*youth\s+tee/i, '') # adult tank / youth tee
    .gsub(/\s*adult\s*[\/&]\s*youth/i, '')               # adult & youth / adult/youth
    .gsub(/\s*adult\s+tank/i, '')
    .gsub(/\s*youth\s+tee/i, '')
    .gsub(/\(\s*\)/, '')                                  # remove empty parens
    .gsub(/\s+/, ' ')
    .strip
end

# ---------- Parse CSV into an accumulator hash ----------

accumulator = {}   # { [section, name] => { price:, quantity: } }
current_vendor = nil
header_skipped = false

csv_content = File.read(CSV_PATH).gsub("\r\n", "\n")
CSV.parse(csv_content).each do |row|
  # Skip the multi-line header row
  unless header_skipped
    header_skipped = true
    next
  end

  vendor_col = row[0]&.strip
  item_col   = row[1]&.strip
  price_col  = row[2]&.strip

  # Vendor/section row — col 0 present, col 1 blank
  if vendor_col.present?
    current_vendor = normalize_vendor(vendor_col) unless vendor_col.match?(/total/i)
    next
  end

  next if item_col.blank?
  next if skip_item?(item_col)
  next if price_col.blank?

  price = price_col.gsub(/[$,\s]/, '').to_f
  next if price <= 0

  quantity, name = parse_item(item_col)
  section = current_vendor || 'General'

  if adult_youth?(name)
    half = quantity / 2
    base = base_name_for_split(name)

    [["#{base} (Adult)", half], ["#{base} (Youth)", half]].each do |n, q|
      key = [section, n]
      accumulator[key] ||= { price: price, quantity: 0 }
      accumulator[key][:quantity] += q
    end
  else
    key = [section, name]
    accumulator[key] ||= { price: price, quantity: 0 }
    accumulator[key][:quantity] += quantity
  end
end

# ---------- Upsert products ----------

puts "\nImporting #{accumulator.count} products...\n\n"

accumulator.each do |(section, name), attrs|
  p = Product.find_or_initialize_by(name: name, section: section)
  p.price    = attrs[:price]
  p.quantity = attrs[:quantity]
  p.save!
  puts "  [#{section}] #{name}  —  $#{'%.2f' % attrs[:price]}  qty: #{attrs[:quantity]}"
end

puts "\nDone! #{Product.count} total products in database."
