require "telegem"
require "httparty"
require "dotenv/load"

token = ENV['BOT_TOKEN']
bot = Telegem.new(token)

bot.command("start") do |ctx|
  text = "welcome to news aggregator bot #{ctx.from.name}"
  text += "i can give you live news from hacker news and dev.to use /news to get started"
  ctx.reply(text)
end 

bot.command("news") do |ctx|
  message = get_news
  ctx.reply(message, parse_mode: 'Markdown')
end
  
 def fetch_news
   url = "https://zen-drx-api.onrender.com"
   response = HTTParty.get(url)
   if response.success? && response['success']
      response['data']
    else
      []
    end
  rescue => e
    puts "Fetch error: #{e.message}"
    []
  end
  
  def get_news
    news = fetch_news
    return "No news available." if news.empty
    
    lines = ["📰 *Latest Tech News*", ""]
    
    news.each_with_index do |item, i|
      title = item["title"].to_s
      url = item["url"].to_s
      source = item["source"].to_s
      
      # Truncate long titles
      title = title[0..70] + "..." if title.length > 70
      
      lines << "#{i+1}. [#{title}](#{url})"
      lines << "   `#{source}`"
      lines << ""
    end
    
    lines << "---"
    lines << "🤖 Via @drx-api • Updated hourly"
    
    lines.join("\n")
  end
  
  bot.start_polling
  
  puts "bot started..."
