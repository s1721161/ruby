require 'discordrb'                        #Youtubeで特定のチャンネルで配信予定があるかどうかを確認して、もしあったら配信開始時間を知らせてくれるbot
require 'open3'
require 'rbnacl/libsodium'
require 'google/apis'
require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'active_support/all'
require 'json'
require 'time'
require "date"


@bot = Discordrb::Commands::CommandBot.new token: 'TOKEN', prefix: '!'   #トークンの認証

@bot.command(:start) do |event|  #!startとチャットに打たれたら開始

event = event
GOOGLE_API_KEY="API_KEY"         #グーグルAPIの認証キー
@snippet2 = nil
@channel_name = event.channel.name        
@temp = '2019-08-13T22:00:00'     

def timer(arg, &proc)                    #配信予定があった場合始まる時間までsleepする
  x = case arg
  when Numeric then arg
  when Time    then arg - Time.now
  when String  then Time.parse(arg) - Time.now
  else raise   
  end
  sleep x if block_given?
  yield
end


def s(event)                    
  puts "sleep"
  sleep(3600)
 find_videos(event)
end


def find_videos(event)                                                     #配信予定があるかどうかを探すメソッド
    @bot.game=("配信予定はありません")
    service = Google::Apis::YoutubeV3::YouTubeService.new
    service.key = GOOGLE_API_KEY
    next_page_token = nil
url = "https://www.youtube.com/watch?v="

begin

opt2 ={                                                             
      channel_id:"UCZ1xuCK1kNmn5RzPYIZop3w",
      event_type:"upcoming",
      page_token: next_page_token,
      type: "video",
      max_results: "1",
    }
      @live = service.list_searches(:snippet, opt2)               #グーグルのyoutubeAPIを使って配信予定があるかを探す
      @live.items.each do|item2|
        @snippet2 = item2.id
          puts  @snippet2.video_id
      end
      
if @live.nil? == true||  @live.blank? == true|| @live==" " || @live == nil || @snippet2.nil?                         #配信予定がなかったらdef sに飛んで3600秒間sleep
  s(event)
end

url += @snippet2.video_id

    opt = {                                           
      id:  @snippet2.video_id, 
      page_token: next_page_token,
    }

    results = service.list_videos(:liveStreamingDetails, opt)               #配信予定があった場合何時に配信が始まるか探す

    i=0

    results.items.each do |item|
      snippet = item.live_streaming_details
      a = snippet.scheduled_start_time.new_offset('+09:00')                       #配信開始予定時間の取得
      f = a.to_s
      t = DateTime.parse(f);
      @f = t.to_s
      @f.slice!(19,25)

      if @temp.eql?(@f)
        s(event)
      end

      @temp = @f
      @bot.game=("#{@f}に配信予定")

    end

timer(Time.parse(@f)) do                                                            #配信開始予定時間までsleep
  event.send_message("#{event.user.mention}\n配信開始時間です\n#{url}")              #配信開始時間になったらチャットで知らせる
end

  end

  @bot.game=("配信予定はありません")                                                          #配信開始を知らせたら32700秒間sleep
      puts "32700sleep"
        sleep(32700)
        find_videos(event)                                                                   #sleepが終わったらまた配信開始予定があるか探す
  end
end

find_videos(event)

  end

end


@bot.run