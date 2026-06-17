require 'telegram/bot'
require 'sequel'
require 'dotenv/load'
require 'net/http'
require 'json'
require 'uri'

TOKEN = ENV['TELEGRAM_BOT_TOKEN']
DB = Sequel.connect(ENV['DATABASE_URL'])
tarot_cards = DB[:tarot_cards]

DEEPSEEK_API_KEY = ENV['OPENROUTER_API_KEY']
DEEPSEEK_MODEL = 'deepseek/deepseek-chat-v3-0324'

def safe_send_message(bot, chat_id, text, parse_mode: nil)
  bot.api.send_message(chat_id: chat_id, text: text, parse_mode: parse_mode)
rescue => e
  puts "Ошибка отправки сообщения: #{e.message}"
end

def get_deepseek_meaning(question)
  uri = URI.parse("https://openrouter.ai/api/v1/chat/completions")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri)
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{DEEPSEEK_API_KEY}"

  request.body = {
    model: DEEPSEEK_MODEL,
    messages: [{ role: 'user', content: question }],
    temperature: 0.7
  }.to_json

  response = http.request(request)
  data = JSON.parse(response.body)
  if data['error']
    puts "Deepseek API error: #{data['error']}"
    return "⚠️ Не удалось получить расшифровку."
  end
  data['choices']&.first&.dig('message', 'content') || "⚠️ Пустой ответ от Deepseek."
rescue => e
  puts "Ошибка Deepseek: #{e.message}"
  "⚠️ Ошибка при обращении к Deepseek API."
end

Telegram::Bot::Client.run(TOKEN) do |bot|
  puts "🔮 Tarot Bot запущен..."

  user_states = {}

  bot.listen do |message|
    begin
      chat_id = message.respond_to?(:chat) ? message.chat.id : message.message.chat.id

      case message
      when Telegram::Bot::Types::Message
        case message.text
        when '/start'
          keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
            inline_keyboard: [
              [{ text: '✨ 1 карта', callback_data: 'one_card' }],
              [{ text: '🔮 3 карты', callback_data: 'three_cards' }],
              [{ text: '🌙 5 карт', callback_data: 'five_cards' }]
            ]
          )
          bot.api.send_message(chat_id: chat_id, text: "Привет! 🃏 Выбери расклад:", reply_markup: keyboard)
        else
          # Если пользователь написал вопрос после выбора расклада
          if user_states[chat_id] && user_states[chat_id][:awaiting_question]
            question = message.text.strip
            count = user_states[chat_id][:count]
            cards = tarot_cards.order(Sequel.lit('RANDOM()')).limit(count).all

            safe_send_message(bot, chat_id, "Ваш расклад:")

            cards.each do |card|
              # Отправляем фото
              bot.api.send_photo(chat_id: chat_id, photo: card[:image_url])

              # Получаем расшифровку через Deepseek
              deepseek_prompt = "Расскажи тарологическую расшифровку карты '#{card[:name]}' для вопроса: #{question}"
              meaning = get_deepseek_meaning(deepseek_prompt)

              # Отправляем расшифровку отдельным сообщением
              safe_send_message(bot, chat_id, "🃏 *#{card[:name]}*\n\n#{meaning}", parse_mode: "Markdown")
            end

            # После расклада — предлагаем повторить или закончить
            again_keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
              inline_keyboard: [
                [{ text: '🔁 Ещё расклад', callback_data: 'again' }],
                [{ text: '🚪 Завершить', callback_data: 'end' }]
              ]
            )
            bot.api.send_message(chat_id: chat_id, text: "Хочешь сделать ещё расклад?", reply_markup: again_keyboard)

            user_states.delete(chat_id)
          end
        end

      when Telegram::Bot::Types::CallbackQuery
        data = message.data

        case data
        when 'one_card' then count = 1
        when 'three_cards' then count = 3
        when 'five_cards' then count = 5

when 'again'
          start_keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
            inline_keyboard: [
              [{ text: '✨ 1 карта', callback_data: 'one_card' }],
              [{ text: '🔮 3 карты', callback_data: 'three_cards' }],
              [{ text: '🌙 5 карт', callback_data: 'five_cards' }]
            ]
          )
          bot.api.send_message(chat_id: chat_id, text: "Выбери расклад:", reply_markup: start_keyboard)
          next
        when 'end'
          safe_send_message(bot, chat_id, "🌟 Спасибо за гадание! Возвращайся, когда почувствуешь зов карт 🌙")
          next
        else
          next
        end

        # Если выбран расклад — ждём вопрос
        user_states[chat_id] = { count: count, awaiting_question: true }
        safe_send_message(bot, chat_id, "Напиши вопрос, на который хочешь сделать расклад:")

      end

    rescue => e
      puts "Ошибка в обработке сообщения: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
    end
  end
end