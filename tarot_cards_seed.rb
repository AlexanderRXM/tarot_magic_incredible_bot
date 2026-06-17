require 'sequel'
require 'dotenv/load'

DB = Sequel.connect(ENV['DATABASE_URL'])
tarot_cards = DB[:tarot_cards]

# Очищаем таблицу
tarot_cards.truncate

GITHUB_BASE = "https://raw.githubusercontent.com/mixvlad/TarotCards/main/tarot/rider-waite/720px"

cards = [
  # Старшие арканы
  {name: 'Шут', filename: '00_fool.jpg'},
  {name: 'Маг', filename: '01_magician.jpg'},
  {name: 'Верховная Жрица', filename: '02_high_priestess.jpg'},
  {name: 'Императрица', filename: '03_empress.jpg'},
  {name: 'Император', filename: '04_emperor.jpg'},
  {name: 'Иерофант', filename: '05_hierophant.jpg'},
  {name: 'Влюбленные', filename: '06_lovers.jpg'},
  {name: 'Колесница', filename: '07_chariot.jpg'},
  {name: 'Сила', filename: '08_strength.jpg'},
  {name: 'Отшельник', filename: '09_hermit.jpg'},
  {name: 'Колесо Фортуны', filename: '10_wheel.jpg'},
  {name: 'Справедливость', filename: '11_justice.jpg'},
  {name: 'Повешенный', filename: '12_hanged_man.jpg'},
  {name: 'Смерть', filename: '13_death.jpg'},
  {name: 'Умеренность', filename: '14_temperance.jpg'},
  {name: 'Дьявол', filename: '15_devil.jpg'},
  {name: 'Башня', filename: '16_tower.jpg'},
  {name: 'Звезда', filename: '17_star.jpg'},
  {name: 'Луна', filename: '18_moon.jpg'},
  {name: 'Солнце', filename: '19_sun.jpg'},
  {name: 'Суд', filename: '20_judgement.jpg'},
  {name: 'Мир', filename: '21_world.jpg'}
]

# Младшие арканы
suits = {
  "Жезлы" => "wands",
  "Кубки" => "cups",
  "Мечи" => "swords",
  "Пентакли" => "pents"
}

ranks = {
  "Туз" => "01",
  "Двойка" => "02",
  "Тройка" => "03",
  "Четвёрка" => "04",
  "Пятёрка" => "05",
  "Шестёрка" => "06",
  "Семёрка" => "07",
  "Восьмёрка" => "08",
  "Девятка" => "09",
  "Десятка" => "10",
  "Паж" => "11",
  "Рыцарь" => "12",
  "Королева" => "13",
  "Король" => "14"
}

suits.each do |suit_name, prefix|
  ranks.each do |rank_name, rank_num|
    filename = "#{prefix}#{rank_num}.jpg"
    cards << {name: "#{rank_name} #{suit_name}", filename: filename}
  end
end

# Вставляем все карты в базу с URL
cards.each do |card|
  tarot_cards.insert(
    name: card[:name],
    filename: card[:filename],
    image_url: "#{GITHUB_BASE}/#{card[:filename]}"
  )
end

puts "✨ Добавлено #{cards.size} карт в базу!"