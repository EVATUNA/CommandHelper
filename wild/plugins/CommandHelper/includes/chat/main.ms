## EvaChat
console('EvaChat loaded')
include('eng_to_kor_translater.ms')

## Channel Register
if(!is_channel_registered('BungeeCord')) {
  register_channel('BungeeCord')
}


@emoji_data = array(
  'player': array(),
  'guild': array()
)



proc _load_player_emoji(@player) {}
proc _save_player_emoji(@player) {}


proc _load_guilds_emoji() {}
proc _load_guild_emoji(@guild) {}
proc _save_guild_emoji(@guild) {}

proc _tellraw(@player, @raw) {
  x_run_on_main_thread_now(closure() {
    tellraw(@player, @raw)
  })
}

proc _convert_message(@strings, @channel, @players_state) {
  @mentioned_players = array()
  @messages = array(
    array(
      'text': ''
    )
  )
  foreach(@key: @string in parse_args(@strings)) {
    @is_modified_message = false
    if(string_starts_with(@string, '@')) {
      @mentioned_message = substr(@string, 1)
      @eng_length = reg_count('[A-z0-9_]',@mentioned_message)
      @kr_length = reg_count('[가-힣]', @mentioned_message)
      @length = length(@mentioned_message)
      if(@length != 0) {
        if(@length == @eng_length) {
          switch(@channel) {
          case 'general':
            foreach(@uuid: @state in @players_state) {
              if(@state['player'] == @mentioned_message && !@state['shifting']) {
                @is_modified_message = true
                @message = array(
                  'text': @string,
                  'color': 'blue',
                  'insertion': @string.' ',
                  'hoverEvent': array(
                    'action': 'show_text',
                    'value': array(
                      '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
                      '좌클릭 시, 유저에게 귓속말을 보냅니다',
                    )
                  ),
                  'clickEvent': array(
                    'action': 'suggest_command',
                    'value': '/w'@state['player']''
                  )
                )
                broadcast(@mentioned_message)
                @mentioned_players[] = @mentioned_message
                #채팅부분에 멘션 메시지 색 설정 클릭시 귓말vs채팅에 호출
              }
            }
            break()
          case 'guild':
            foreach(@uuid: @state in @players_state) {
              if(@state['player'] == @mentioned_message && !@state['shifting'] && @state['guild'] == '') { # 길드
                @is_modified_message = true
                @message = array(
                  'text': @string,
                  'color': 'blue'
                )
                @mentioned_players[] = @mentioned_message
                #채팅부분에 멘션 메시지 색 설정 클릭시 귓말vs채팅에 호출
              }
            }
            break()
          case 'admin':
            foreach(@uuid: @state in @players_state) {
              if(@state['player'] == @mentioned_message && !@state['shifting'] && @state['is_op']) {
                @is_modified_message = true
                @message = array(
                  'text': @string,
                  'color': 'blue'
                )
                @mentioned_players[] = @mentioned_message
                #채팅부분에 멘션 메시지 색 설정 클릭시 귓말vs채팅에 호출
              }
            }
            break()
          }
        } else if(@length == @kr_length) {
          switch(@channel) {
          case 'general':
          case 'admin':
            @admin = array('스태프', '스탭', '스탭진', '스탭팀', '운영', '운영자', '운영진', '운영팀', '관리자', '어드민', '오피')
            if(array_contains(@admin, @mentioned_message)) {
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'blue',
                'hoverEvent': array(
                  'action': 'show_text',
                  'value': array(
                    '접속중인 관리자:'
                  )
                )
              )
              foreach(@uuid: @state in @players_state) {
                if(!@state['shifting'] && @state['is_op']) {
                  @mentioned_players[] = @state['player']
                  @message['hoverEvent']['value'][] = '\n'.@state['player']
                }
              }
            }
            break()
          case 'guild':
            @guild_owner = array('길드장')
            @guild_staff = array('부길드장')
            @guild_member = array('길드원')
            foreach(@uuid: @state in @players_state) {
              if(!@state['shifting'] && @state['guild'] == '') { # 길드가 같은 메시지 받을수 있는 플레이어들
                if(array_contains(@guild_owner, @mentioned_message)) {
                  @is_modified_message = true
                  @message = array(
                    'text': @string,
                    'color': 'blue'
                  )
                  @mentioned_players[] = @state['player'] #이 플레이어를 호버 메시지 목록에도 넣어야 함
                  #채팅부분 색 설정 호버 메시지 설정
                } else if(array_contains(@guild_staff, @mentioned_message)) {
                  @is_modified_message = true
                  @message = array(
                    'text': @string,
                    'color': 'blue'
                  )
                  @mentioned_players[] = @state['player'] #이 플레이어를 호버 메시지 목록에도 넣어야 함
                  #채팅부분 색 설정 호버 메시지 설정
                } else if(array_contains(@guild_member, @mentioned_message)) {
                  @is_modified_message = true
                  @message = array(
                    'text': @string,
                    'color': 'blue'
                  )
                  @mentioned_players[] = @state['player'] #이 플레이어를 호버 메시지 목록에도 넣어야 함
                  #채팅부분 색 설정 호버 메시지 설정
                }
                @mentioned_players[] = @state['player'] #이 플레이어를 호버 메시지 목록에도 넣어야 함
                #채팅부분 색 설정 호버 메시지 설정
              }
            }
            break()
          }
        }
      }
     } else if(string_starts_with(@string, './')) {
      @string = replace(@string, './', '/')
      @string = replace(@string, '_', ' ')
      @is_modified_message = true
      @message = array(
        'text': @string,
        'color': 'red',
        'clickEvent': array(
          'action': 'suggest_command',
          'value': @string
        )
      )
    } else if(string_starts_with(@string, 'https://') || string_starts_with(@string, 'http://')) {
      @is_modified_message = true
      @message = array(
        'text': @string,
        'color': 'blue',
        'clickEvent': array(
          'action': 'open_url',
          'value': @string
        )
      )
    }
    if(@is_modified_message) {
      @pre_message = @messages[array_size(@messages) -1]
      if(array_size(@messages) != 1) {
        if(array_index_exists(@pre_message, 'color')) {
          @messages[] = array(
            'text': ' '
          )
        } else {
          @messages[array_size(@messages) -1]['text'] = @pre_message['text'].' '
        }
      }
      @messages[] = @message
    } else {
      @pre_message = @messages[array_size(@messages) -1]
      if(array_size(@messages) == 1) {
        @messages[] = array(
          'text': @string
        )
      } else {
        if(array_index_exists(@pre_message, 'color')) {
          @messages[] = array(
            'text': ' '.@string
          )
        } else {
          @messages[array_size(@messages) -1]['text'] = @pre_message['text'].' '.@string
        }
      }
    }
  }
  @mentioned_players = array_unique(@mentioned_players)
  return(array('raw': @messages, 'mentioned_players': @mentioned_players))
}

bind('async_player_chat', null , null, @event, @players_state, @players_data, @players_item) {
  @sender = @event['player']
  @sender_uuid = puuid(@sender)
  if(array_index_exists(@players_data, @sender_uuid)) {
    @chating_data = @players_data[@sender_uuid]['chating']
    @badge = @chating_data['selected_badge']
    @channel = @chating_data['channel']
    @enko = @players_data[@sender_uuid]['chating']['en_ko']
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
    @item = null
    if(!is_null(@players_item[@sender_uuid]['main_hand'])) {
      @item = array()
      @item['name'] = to_lower(@players_item[@sender_uuid]['main_hand']['name'])
      if(!is_null(@players_item[@uuid]['main_hand']['meta'])) {
        if(array_index_exists(@players_item[@sender_uuid]['main_hand']['meta'], 'display') && !is_null(@players_item[@sender_uuid]['main_hand']['meta']['display'])) {
          @item['display'] = @players_item[@sender_uuid]['main_hand']['meta']['display']
        } else {
          @item['display'] = to_lower(@players_item[@sender_uuid]['main_hand']['name'])
        }
        if(array_index_exists(@players_item[@sender_uuid]['main_hand']['meta'], 'lore') && !is_null(@players_item[@sender_uuid]['main_hand']['meta']['lore'])) {
          @item['lore'] = @players_item[@sender_uuid]['main_hand']['meta']['lore']
        } else {
          @item['lore'] = array()
        }
      } else {
        @item['display'] = to_lower(@players_item[@sender_uuid]['main_hand']['name'])
        @item['lore'] = array()
      }
    }

    @converted_message = _convert_message(@message, @channel, @players_state)
    @mentioned_players = @converted_message['mentioned_players']
    @raw = @converted_message['raw']

    @data = array(
      'player': @sender,
      'badge': @badge,
      'channel': @channel,
      'mentioned_players': @mentioned_players,
      'raw': @raw,
      'item': @item
    )

    _bungeecord_foward(@sender, 'PlayerChatEvent', @data)
    foreach(@receiver_uuid in array_keys(@players_state)) {
      @receiver = player(@receiver_uuid)
      if(ponline(@receiver)) {
        _tellraw(@receiver, @raw)
        if(@receiver == @sender) {
          play_named_sound(ploc(@sender), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender))
        } else {
          play_named_sound(ploc(@receiver), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver))
          #호출 여기로 옮기기
        }
        if(array_contains(@mentioned_players, @receiver)) {
          play_named_sound(ploc(@receiver), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver))
        }
      }
    }
  /*
    switch(@channel) {
    case 'local':
      @receivers = array()
      foreach(@receiver in all_players()) {
        @receivers[] = @receiver
      }
      @color = '#ffd6bf'
      break()
    case 'guild':
      @receivers = array()
      foreach(@receiver in all_players()) {
        if(pisop(@receiver)) {
          @receivers[] = @receiver
        }
      }
      @color = '#d5d0f4'
      break()
    case 'admin':
      @receivers = array()
      foreach(@receiver in all_players()) {
        if(pisop(@receiver)) {
          @receivers[] = @receiver
        }
      }
      @color = '#fdc4d5'
      break()
    default:
      @receivers = array()
      foreach(@receiver in all_players()) {
        @receiver_uuid = puuid(@receiver)
        if(array_index_exists(@players_data, @receiver_uuid)) {
          @receiver_chating_data = @players_data[@receiver_uuid]['chating']
          if(@receiver_chating_data['channel'] == @channel) {
            @receivers[] = @receiver
          } else {
            if(@receiver_chating_data['listening'][@channel] == 'all') {
              @receivers[] = @receiver
            } else if(@receiver_chating_data['listening'][@channel] == 'mention') {
              #멘션이 있을 시,
              #@receivers[] = @receiver
            } else {

            }
          }
        }
        

          
      }
      @color = '#ffffff'
      break()
    }

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

      #@messages = _convert_message(@message, @color)

    } else {


    }
    */
    /*
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

      #@msg = byte_array()

      
      #broadcast(array_size(@msg))
      
      #ba_put_bytes(@byte_array, length(@event['message']))
      #send_plugin_message(@player, 'BungeeCord', @byte_array)
                #ba_put_short()
      /*
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
                })
                @chat = array_merge(array(array('text': ': ', 'color': @color)), @messages)
                @msg = 'asdf'

                @byte_array = byte_array()
                ba_put_string(@byte_array, 'Forward')
                ba_put_string(@byte_array, 'ALL')
                ba_put_string(@byte_array, 'Chat')
                ba_put_short(@byte_array, 'Chat')
                send_plugin_message(@player, 'BungeeCord', @byte_array)
                #ba_put_short()

                @channel_messages = array(
                  'Forward',
                  'ALL'
                  'chat'
                  @int
                  @msg
                )
                #_send_plugin_message(@player, @channel_messages)
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
      
    }*/
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
        _send_action_msg(@player, @players_data[@uuid], @text)
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
        _send_action_msg(@player, @players_data[@uuid], @font)
      } else {

      }
    }
  }
))