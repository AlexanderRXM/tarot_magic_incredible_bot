require 'httparty'
require 'json'

class DeepSeekClient
  include HTTParty
  base_uri 'https://api.deepseek.com'

  def initialize(api_key)
    @headers = {
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json"
    }
  end

  def chat(prompt)
    body = {
      model: "deepseek-chat",
      messages: [
        { role: "system", content: "Ты — опытный таролог. Интерпретируешь расклады Таро глубоко, мудро и метафорично." },
        { role: "user", content: prompt }
      ],
      temperature: 0.8,
      max_tokens: 400
    }

    response = self.class.post("/chat/completions", headers: @headers, body: body.to_json)
    result = JSON.parse(response.body)
    result.dig("choices", 0, "message", "content")
  rescue => e
    "Ошибка при обращении к DeepSeek API: #{e.message}"
  end
end