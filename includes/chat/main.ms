## EvaChat
console('EvaChat loaded')
include('eng_to_kor_translater.ms')

@emoji_data = array(
  'player': array(),
  'guild': array()
)



proc _load_player_emoji(@player) {}
proc _save_player_emoji(@player) {}


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

bind('async_player_chat', null , null, @event, @players_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
    @chating_data = @players_data[@uuid]['chating']
    @badge = @chating_data['selected_badge']
    @channel = @chating_data['channel']
    @enko = @players_data[@uuid]['chating']['en_ko']
    if(@channel == 'local') {
      @color = '#ffd6bf'
      @name = array(
        array(
          'text': ''@badge'',
          'color': '#ffffff'
        ),
        array(
          'text': @player.string_multiply('\uF824', 16 - length(@player)),
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
      @messages = _convert_message(@message, @color)

    } else {
      switch(@channel) {
      case 'guild':
        @color = '#d5d0f4'
        break()
      case 'admin':
        @color = '#fdc4d5'
        break()
      default:
        @color = '#ffffff'
        break()
      }
      @name = array(
        array(
          'text': ''@badge'',
          'color': '#ffffff'
        ),
        array(
          'text': @player,
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
      @messages = _convert_message(@message, @color)
      bind('plugin_message_received', array('id': 'read_player_list.'.@player.'.'.time()), null, @event, @player, @name, @messages, @channel, @color) {
      #broadcast(replace(substr(string_from_bytes(@event['bytes']), 19), ',', ''))
      @receivers = parse_args(replace(substr(string_from_bytes(@event['bytes']), 19), ',', ''))
        switch(@channel) {
        case 'general':
          foreach(@receiver in @receivers) {
            @receiver_uuid = puuid(@receiver)
            pogu_get('state:'.@receiver_uuid, closure(@connected, @value) {
              if(@value != 'verifing') {
                /*pogu_get('last_sender:'.@receiver, closure(@connected, @last_sender) {
                  pogu_set('last_sender:'.@receiver, @player, closure(@connected, @value) {})
                  if(@player != @last_sender) {
                    @chat = array_merge(@name, array(array('text': ' ↠ ', 'color': @color)), @messages)
                  } else {
                    @chat = array_merge(array(array('text': ' ↠ ', 'color': @color)), @messages)
                  }
                  @channel_messages = array('MessageRaw', @receiver, json_encode(@chat))
                  _send_plugin_message(@player, @channel_messages)
                })*/
                @chat = array_merge(array(array('text': ': ', 'color': @color)), @messages)
                @channel_messages = array('MessageRaw', @receiver, json_encode(@chat))
                _send_plugin_message(@player, @channel_messages)
              }
            })
          }
          break()
        case 'guild':
          foreach(@receiver in @receivers) {
            @receiver_uuid = puuid(@receiver)
            pogu_get('state:'.@receiver_uuid, closure(@connected, @value) {
              if(@value != 'verifing') {
                pogu_get('last_sender:'.@receiver, closure(@connected, @last_sender) {
                  pogu_set('last_sender:'.@receiver, @player, closure(@connected, @value) {})
                  if(@player != @last_sender) {
                    @chat = array_merge(@name, array(array('text': ' ↠ ', 'color': @color)), @messages)
                  } else {
                    @chat = array_merge(array(array('text': ' ↠ ', 'color': @color)), @messages)
                  }
                  @channel_messages = array('MessageRaw', @receiver, json_encode(@chat))
                  _send_plugin_message(@player, @channel_messages)
                })
              }
            })
          }
          break()
        case 'admin':
          foreach(@receiver in @receivers) {
            @receiver_uuid = puuid(@receiver)
            pogu_get('state:'.@receiver_uuid, closure(@connected, @value) {
              if(@value != 'verifing') {
                pogu_get('last_sender:'.@receiver, closure(@connected, @last_sender) {
                  pogu_set('last_sender:'.@receiver, @player, closure(@connected, @value) {})
                  if(@player != @last_sender) {
                    @chat = array_merge(@name, array(array('text': ' ↠ ', 'color': @color)), @messages)
                  } else {
                    @chat = array_merge(array(array('text': ' ↠ ', 'color': @color)), @messages)
                  }
                  @channel_messages = array('MessageRaw', @receiver, json_encode(@chat))
                  _send_plugin_message(@player, @channel_messages)
                })
              }
            })
          }
          break()
        }
        unbind()
      }
      _send_plugin_message(@player, array('PlayerList', 'ALL'))
    }
  }
  cancel()
}

register_command('enko', array(
  'description': 'can select chating type',
  'usage': '/enko',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      if(@players_data[@uuid]['chating']['en_ko']) {
        @players_data[@uuid]['chating']['en_ko'] = false
        _action_msg(@player, @players_data[@uuid], @font)
      } else {
        @players_data[@uuid]['chating']['en_ko'] = true
        _action_msg(@player, @players_data[@uuid], @font)
      }
    }
  }
))

register_command('ch', array(
  'description': 'can select channel',
  'usage': '/ch [channel]',
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 0) {
      @return = array('general', 'local', 'guild', 'admin')
    } else {
      @return = array()
    }
    return(@return)
  },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      if(array_size(@args) == 0) {
        switch(@players_data[@uuid]['chating']['channel']) {
        case 'local':
          #길드가 있을시
          @players_data[@uuid]['chating']['channel'] = 'guild'
          #길드가 없고 어드민일시
          #길드도 없고 어드민도 아닐시
          break()
        case 'guild':
          #어드민일시
          @players_data[@uuid]['chating']['channel'] = 'admin'
          #어드민이 아닐시
          break()
        case 'admin':
          @players_data[@uuid]['chating']['channel'] = 'general'
          break()
        default:
          @players_data[@uuid]['chating']['channel'] = 'local'
          break()
        }
        _action_msg(@player, @players_data[@uuid], @text)
      } else if(array_size(@args) == 1) {
        switch(@args[0]) {
        case 'local':
          #길드가 있을시
          @players_data[@uuid]['chating']['channel'] = 'local'
          #길드가 없고 어드민일시
          #길드도 없고 어드민도 아닐시
          break()
        case 'guild':
          #어드민일시
          @players_data[@uuid]['chating']['channel'] = 'guild'
          #어드민이 아닐시
          break()
        case 'admin':
          @players_data[@uuid]['chating']['channel'] = 'admin'
          break()
        default:
          @players_data[@uuid]['chating']['channel'] = 'default'
          break()
        }
        _action_msg(@player, @players_data[@uuid], @font)
      } else {

      }
    }
  }
))