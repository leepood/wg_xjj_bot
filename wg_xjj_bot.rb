require 'telegram/bot'
require 'yaml'


TOKEN = "" # tokens here
WATCHER = "llqoli"


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


def handle_msg(msg)
	user = msg.from.username

	puts "rece msg from #{user}"
	case msg.text
	when '/watchers_add'
		add_2_lst user
		@bot.api.send_message(chat_id: msg.chat.id, text: "@#{user} 您已经加入通知列表")
	when '/watchers_remove'
		remove_from_lst user
		@bot.api.send_message(chat_id: msg.chat.id, text: "@#{user} 您已经被移出通知列表 ")
	when '/watchers_lst'
		# TODO
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
  	
  	sender = message.from.username
  	puts "sender:#{sender}"
  	if sender == WATCHER
  		# 检查是不是要关注的人
  		unless message.photo.empty?
  			user_lst = get_watcher_lst.map {|watcher| "@#{watcher}"}.join(",")
  			@bot.api.send_message(chat_id: message.chat.id, text: "#{user_lst} 小姐姐发福利啦！ ")
  		end
  	else
  		handle_msg message
  	end
end