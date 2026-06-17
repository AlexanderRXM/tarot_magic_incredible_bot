require 'sequel'
require 'dotenv/load'

# Подключение к базе PostgreSQL через DATABASE_URL
DB = Sequel.connect(ENV['DATABASE_URL'])
tarot_cards = DB[:tarot_cards]

# --- Создаём таблицу, если её нет ---
DB.create_table? :tarot_cards do
  primary_key :id
  String :name, null: false
end

# --- Добавляем недостающие колонки, если их нет ---
columns = tarot_cards.columns

unless columns.include?(:eng_name)
  DB.alter_table(:tarot_cards) { add_column :eng_name, String }
end

unless columns.include?(:filename)
  DB.alter_table(:tarot_cards) { add_column :filename, String }
end

unless columns.include?(:meaning_upright)
  DB.alter_table(:tarot_cards) { add_column :meaning_upright, String }
end

unless columns.include?(:meaning_reversed)
  DB.alter_table(:tarot_cards) { add_column :meaning_reversed, String }
end

# --- Очищаем таблицу перед seed ---
tarot_cards.delete
puts "Таблица tarot_cards готова и очищена. Можно запускать seed для 78 карт!"