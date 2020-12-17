## EvaChat
console('EvaChat loaded')
include('eng_to_kor_translater.ms')

@emoji_data = array(
  'general': array(),
  'player': array(),
  'guild': array()
)

async_read('general_emoji.json', closure(@value) {
  @emoji_data['general'] = json_decode(@value)
})

proc _load_player_emoji(@player) {
  @uuid = puuid(@player)
  @path = 'player_emoji/'.@uuid.'.json'
  if(file_exists(@path)) {
    async_read(@path, closure(@value) {
      @emoji_data['player'][@player] = json_decode(@value)
    })
  } else {
    @emoji_data['player'][@player] = array()
    async_write_file(@path, json_encode(array()), 'OVERWRITE')
  }
}

proc _save_player_emoji(@player) {
  @uuid = puuid(@player)
  @path = 'player_emoji/'.@uuid.'.json'
  async_write_file(@path, json_encode(@emoji_data['player'][@player]), 'OVERWRITE')
}


proc _load_guilds_emoji() {}
proc _load_guild_emoji(@guild) {}
proc _save_guild_emoji(@guild) {}


proc _convert_message(@string, @color) {
  @messages = array()
  foreach(@key: @message in parse_args(@string)) {
    @messages[@key * 2] = array()
    @messages[@key * 2 + 1] = array('text': ' ')
    if(string_starts_with(@message, ':') && string_ends_with(@message, ':')) {
      @messages[@key * 2]['translate'] = @message
      @messages[@key * 2]['color'] = '#ffffff'
    } else if(string_starts_with(@message, './')) {
      @message = replace(@message, './', '/')
      @message = replace(@message, '_', ' ')
      @messages[@key * 2]['text'] = @message
      @messages[@key * 2]['color'] = 'red'
      @messages[@key * 2]['clickEvent'] = array(
        'action': 'suggest_command',
        'value': @message
      )
    } else if(string_starts_with(@message, 'https://') || string_starts_with(@message, 'http://')) {
      @messages[@key * 2]['text'] = @message
      @messages[@key * 2]['color'] = 'blue'
      @messages[@key * 2]['clickEvent'] = array(
        'action': 'open_url',
        'value': @message
      )
    } else {
      @messages[@key * 2]['text'] = @message
      @messages[@key * 2]['color'] = @color
    }
  }
  array_remove(@messages, array_size(@messages) - 1)
  return(@messages)
}

bind('async_player_chat', null , null, @event) {
	cancel()
  @player = @event['player']
  @badge = ''
  @channel = 'general'

  switch(@channel) {
  case 'general':
    break()
  case 'local':
    break()
  case 'guild':
    break()
  case 'admin':
    break()
  }
  @color = '#fffcbe'
  @enko = true
  @name = array(
    array(
      'text': ''@badge'',
      'color': '#ffffff'
    ),
    array(
      'text': @player,
      'color': @color
    ),
    array(
      'text': ': ',
      'color': @color
    )
  )
  if(@enko) {
    @message = _convert_eng_to_kor(@event['message'])
    if(@message){
      @reg = reg_match_all('\\[([^\\]]*)\\]', @event['message'])
      foreach(@arr in @reg){
        @converted = _convert_eng_to_kor(@arr[0])
        @message = replace(@message, @converted, @arr[1])
      }
    } else {
      @message = @event['message']
    }
  } else {
    @message = @event['message']
  }

  bind('plugin_message_received', array('id': 'read_player_list.'.@player.'.'.time()), null, @event) {
    #broadcast(ba_get_string(@event['bytes']))
    #포리치, 플레이어의 길드 구하기, 본인 길드한테만 메시지 보내기
    unbind()
  }
  _send_plugin_message(@player, array('PlayerList', 'ALL'))
  @messages = _convert_message(@message, @color)
  @chat = array_merge(@name, @messages)
  #broadcast(time())
  @channel_messages = array('MessageRaw', 'ALL', json_encode(@chat))
  _send_plugin_message(@player, @channel_messages)
}

##pogu set list 채널 enko 뱃지