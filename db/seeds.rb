# Sample data: 2 test campers and 2 test products
# Run with: bin/rails db:seed

puts "Seeding campers..."

Camper.find_or_create_by!(name: "Alice Johnson") do |c|
  c.balance = 150.00
end

Camper.find_or_create_by!(name: "Bob Smith") do |c|
  c.balance = 150.00
end

puts "Seeding products..."

Product.find_or_create_by!(name: "Shirt") do |p|
  p.price    = 20.00
  p.quantity = 10
  p.section  = "Clothing"
end

Product.find_or_create_by!(name: "Chapstick") do |p|
  p.price    = 1.50
  p.quantity = 100
  p.section  = "Health & Beauty"
end

puts "Done! #{Camper.count} campers, #{Product.count} products."
