require 'telegram/bot'
require 'yaml'
require 'httpclient'
require 'json'


TOKEN = ENV['tg_token'] 
WATCHER = "llqoli"
COMMANDS = ['/watchers_add','/watchers_remove','/watchers_lst']


@bot = Telegram::Bot::Client.new(TOKEN)  

def add_2_lst(username)
	hash = load_notify_users
	hash[:config] << username
	persist_config hash
end

def remove_from_lst(username)
	hash = load_notify_users
	hash[:config].delete username
	persist_config hash
end


def lucky(msg)
	page = rand 2000
	url = "https://api.avgle.com/v1/videos/#{page}?limit=25"
	clnt = HTTPClient.new 
	res = clnt.get url
	begin
		
		jsonRet = JSON.parse res.content
		if jsonRet["success"] 
			videos = jsonRet["response"]["videos"]
			index = rand videos.size
			video = videos[index]
			# 
			raw_content = "<b>#{video["title"]}</b><a href=\"#{video["video_url"]}\">View</a> "

			@bot.api.send_message(chat_id: msg.chat.id, reply_to_message_id: msg.message_id,parse_mode:'HTML', text: raw_content) and return

		else
			puts "parse failed"
		end

	rescue Exception => e
		puts e
	end
end


def handle_msg(msg)
	user = msg.from.username
	
	puts "recv msg from: #{user} - contents:#{msg.text}"

	return if msg.text.nil?
	
	if msg.text.start_with?(*COMMANDS)
		# check whether has username
		@bot.api.send_message(chat_id: msg.chat.id, reply_to_message_id: msg.message_id, text: "請在設定 username 后再試一次") and return if user.nil?
	end
	
	case 
	when msg.text.start_with?("/watchers_add")
		add_2_lst user
		@bot.api.send_message(chat_id: msg.chat.id, reply_to_message_id: msg.message_id, text: "您已經加入到通知列表")
	when msg.text.start_with?("/watchers_remove")
		remove_from_lst user
		@bot.api.send_message(chat_id: msg.chat.id, reply_to_message_id: msg.message_id, text: "您已經被移出通知列表 ")
	when msg.text.start_with?("/watchers_lst")
		subscribers = get_watcher_lst.to_a.join("、")
		@bot.api.send_message(chat_id: msg.chat.id, reply_to_message_id: msg.message_id, text: "當前訂閱者：#{subscribers}")
	when msg.text.start_with?("/lucky")
		lucky msg
	end
	
end


def load_notify_users
	hash = YAML::load_file(File.join(__dir__, 'config.yml')) rescue  {:config => Set.new}
	hash[:config] = Set.new  unless hash.has_key? :config
	hash
end

def persist_config(yaml)
	File.open(File.join(__dir__, 'config.yml'), 'w') {|f| f.write yaml.to_yaml }
end

def get_watcher_lst
	load_notify_users[:config]
end


@bot.listen do |message|
  	
  	begin
  		sender = message.from.username
  		puts "sender:#{sender}"
	  	if sender == WATCHER
	  		# 检查是不是要关注的人
	  		unless message.photo.empty?
	  			user_lst = get_watcher_lst.map {|watcher| "@#{watcher}"}.join(",")
	  			@bot.api.send_message(chat_id: message.chat.id,reply_to_message_id: message.message_id, text: "#{user_lst} 小姐姐發福利啦！ ")
	  		end
	  	else
	  		handle_msg message
	  	end
  	rescue Exception => e
  		puts "error occurs: #{e}"
  	end
  	
end