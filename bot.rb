# news_bot.rb
require 'telegem'
require 'httparty'
require 'uri'

class NewsBot
  API_BASE = "https://zen-drx-api.onrender.com"
  
  def initialize(token)
    @bot = Telegem.new(token)
    setup_handlers
  end
  
  def setup_handlers
    # Start command
    @bot.command(:start) do |ctx|
      ctx.reply(
        "📰 *News Bot*\n\n" \
        "Get latest tech news from Hacker News & Dev.to\n\n" \
        "Commands:\n" \
        "/news - Get top 10 stories\n" \
        "/latest - Get latest 5 stories\n" \
        "/sources - Show available sources\n" \
        "/search <term> - Search news (coming soon)",
        parse_mode: 'Markdown'
      )
    end
    
    # News command - shows top 10
    @bot.command(:news) do |ctx|
      fetch_and_send(ctx, limit: 10)
    end
    
    # Latest command - shows top 5
    @bot.command(:latest) do |ctx|
      fetch_and_send(ctx, limit: 5)
    end
    
    # Sources command
    @bot.command(:sources) do |ctx|
      ctx.reply(
        "📡 *News Sources*\n\n" \
        "• Hacker News - Top stories from tech community\n" \
        "• Dev.to - Programming articles from developers\n\n" \
        "Cache refreshes every 60 minutes.",
        parse_mode: 'Markdown'
      )
    end
    
    # Inline mode (optional) - type @newsbot something
    @bot.on(:inline_query) do |ctx|
      query = ctx.query || ""
      results = fetch_news(limit: 3)
      
      inline_results = results.map do |item|
        {
          type: "article",
          id: item["title"].to_s.hash.to_s,
          title: item["title"].to_s[0..60],
          description: "Source: #{item['source']}",
          message_text: "#{item['title']}\n#{item['url']}"
        }
      end
      
      ctx.answer_inline_query(inline_results)
    end
    
    # Error handling
    @bot.error do |error, ctx|
      puts "Error: #{error.message}"
      ctx.reply("❌ Something went wrong. Please try again later.") if ctx
    end
  end
  
  def fetch_and_send(ctx, limit: 10)
    # Show typing indicator while fetching
    ctx.typing
    
    news = fetch_news(limit: limit)
    
    if news.empty?
      ctx.reply("No news available at the moment. Try again later.")
      return
    end
    
    # Format the response
    message = format_news(news)
    ctx.reply(message, parse_mode: 'Markdown', disable_web_page_preview: true)
  end
  
  def fetch_news(limit: 10)
    url = "#{API_BASE}/api/news"
    
    response = HTTParty.get(url, timeout: 10)
    
    if response.success? && response['success']
      response['data'].first(limit)
    else
      []
    end
  rescue => e
    puts "Fetch error: #{e.message}"
    []
  end
  
  def format_news(news_items)
    return "No news available." if news_items.empty?
    
    lines = ["📰 *Latest Tech News*", ""]
    
    news_items.each_with_index do |item, i|
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
  
  def start
    puts "🤖 News Bot starting..."
    
    # Use webhook in production, polling for development
    if ENV['RENDER']
      # Production: Webhook mode
      webhook_url = ENV['WEBHOOK_URL']
      @bot.set_webhook(url: webhook_url)
      
      server = @bot.webhook(port: ENV['PORT'].to_i, host: '0.0.0.0')
      server.run
    else
      # Development: Polling mode
      @bot.start_polling
    end
  end
end

# Run the bot
if __FILE__ == $0
  token = ENV['BOT_TOKEN'] || ARGV[0]
  unless token
    puts "Usage: BOT_TOKEN=your_token ruby news_bot.rb"
    exit 1
  end
  
  bot = NewsBot.new(token)
  bot.start
  
  # Keep the script running
  sleep
end
