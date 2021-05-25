## EvaChat
console('EvaChat loaded')
include('eng_to_kor_translater.ms')

@log_data = array()
if(@server['name'] == 'main') {
  proc _logging_message(@type, @uuid, @player, @message) {
    @time = simple_date('yyyy-MM-dd HH:mm:ss')
    @message = replace(@message, '\\', '\\\\')
    @message = replace(@message, '\'', '\\\'')
    unsafe_query('evatuna', "INSERT INTO log_chat(`time`, `type`, `uuid`, `name`, `message`) VALUES (\'".@time."\', \'".@type."\', \'".@uuid."\', \'".@player."\', \'".@message."\')")
  }
  proc _logging_whisper(@type, @sender_uuid, @sender_name, @receiver_uuid, @receiver_name, @message) {
    @time = simple_date('yyyy-MM-dd HH:mm:ss')
    @message = replace(@message, '\\', '\\\\')
    @message = replace(@message, '\'', '\\\'')
    unsafe_query('evatuna', "INSERT INTO log_whisper(`time`, `sender_uuid`, `sender_name`, `receiver_uuid`, `receiver_name`, `message`) VALUES (\'".@time."\', \'".@sender_uuid."\', \'".@sender_name."\', \'".@receiver_uuid."\', \'".@receiver_name."\', \'".@message."\')")
  }
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
  if(x_get_current_thread() == 'Server thread') {
    tellraw(@player, @raw)
  } else {
    x_run_on_main_thread_now(closure() {
      tellraw(@player, @raw)
    })
  }
}

proc _en_to_ko(@unconverted_message) {
  @converted_message = _convert_eng_to_kor(@unconverted_message)
  if(@converted_message){
    @reg = reg_match_all('\\[([^\\]]*)\\]', @unconverted_message)
    foreach(@arr in @reg){
      @converted = _convert_eng_to_kor(@arr[0])
      @converted_message = replace(@converted_message, @converted, @arr[1])
    }
  } else {
    @converted_message = @unconverted_message
  }
  return(@converted_message)
}

proc _default_chat(@data, @players_data, @bots, @log_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_setting = @data['sender_setting']
  @unmodified_message = @data['message']
  #로깅
  if(is_proc('_logging_message')) {
    _logging_message('default', @sender_uuid, @sender_name, @unmodified_message)
  }
  #리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in _all_players(@bots)) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(ponline(@receiver_name)) {
      if(array_index_exists(@players_data, @receiver_uuid)) {
        @receiver_setting = @players_data[@receiver_uuid]['setting']
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'is_online': true,
          'is_op': pisop(@receiver_name),
          'channel': @receiver_setting[0],
          'is_listening': @receiver_setting[4],
          'is_observer': @receiver_setting[8],
          'is_mentioned': false
        )
      }
    } else {
      @receiver_setting = cup_get('SETTING', @receiver_uuid)
      if(!is_null(@receiver_setting)) {
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'is_online': false,
          'is_op': bukkitlinked_is_player_op(@receiver_uuid),
          'channel': @receiver_setting[0],
          'is_listening': @receiver_setting[4],
          'is_observer': @receiver_setting[8],
          'is_mentioned': false
        )
      }
    }
  }
  #이름 부분
  @name = array(
    array(
      'text': @sender_setting[11].' ',
      'color': '#ffffff',
    ),
    array(
      'text': @sender_name,
      'insertion': '@'.@sender_name'',
      'hoverEvent': array(
        'action': 'show_text',
        'value': array(
          '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
          '좌클릭 시, 유저에게 귓속말을 보냅니다',
        )
      ),
      'clickEvent': array(
        'action': 'suggest_command',
        'value': '/w'@sender_name''
      )
    ),
    array(
      'text': ' :: ',
    )
  )
  #메시지 생성 부분
  @mentioned_messages = array()
  @modified_message = array(
    array('text': '')
  )
  foreach(@key: @string in parse_args(@unmodified_message)) {
    @is_modified_message = false
    if(string_starts_with(@string, '@')) {
      @mentioned_message = substr(@string, 1) 
      @eng_length = reg_count('[A-z0-9_]',@mentioned_message)
      @kr_length = reg_count('[가-힣]', @mentioned_message)
      @length = length(@mentioned_message)
      if(@length != 0) {
        if(@length == @eng_length) {
          if(!array_contains(@mentioned_messages, @mentioned_message)) {
            foreach(@receiver_uuid: @receiver_data in @receivers) {
              if(@mentioned_message == @receiver_data['name']) {
                @receivers[@receiver_uuid]['is_mentioned'] = true
                @mentioned_messages[] = @mentioned_message
                @is_modified_message = true
                @message = array(
                  'text': @string,
                  'color': 'red',
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
                    'value': '/w'@mentioned_message''
                  )
                )
                break()
              }
            }
          } else {
            @is_modified_message = true
            @message = array(
              'text': @string,
              'color': 'red',
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
                'value': '/w'@mentioned_message''
              )
            )
          }
        } else if(@length == @kr_length) {
          @admin = array('스태프', '스탭', '스탭진', '스탭팀', '운영', '운영자', '운영진', '운영팀', '관리자', '어드민', '오피')
          if(array_contains(@admin, @mentioned_message)) {
            if(!array_contains(@mentioned_messages, '관리자')) {
              @mentioned_messages[] = '관리자'
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'red',
                'hoverEvent': array(
                  'action': 'show_text',
                  'value': array(
                    '접속중인 관리자:'
                  )
                )
              )
              foreach(@receiver_uuid: @receiver_data in @receivers) {
                if(@receiver_data['is_op']) {
                  @receivers[@receiver_uuid]['is_mentioned'] = true
                  @message['hoverEvent']['value'][] = '\n'.@receiver_data['name']
                }
              }
              @op_list_message = @message
            } else {
              @is_modified_message = true
              @message = @op_list_message
            }
          }
        }
      }
    } else if(string_starts_with(@string, './')) {
      @string = replace(@string, './', '/')
      @string = replace(@string, '_', ' ')
      @is_modified_message = true
      @message = array(
        'text': @string,
        'color': 'yellow',
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
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) != 1) {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '
        }
      }
      @modified_message[] = @message
    } else {
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) == 1) {
        @modified_message[] = array(
          'text': @string
        )
      } else {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '.@string
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '.@string
        }
      }
    }
  }
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    if(@receiver_data['is_online']) {
      if(@receiver_data['channel'] == 'default' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        _tellraw(@receiver_name, array_merge(@name, @modified_message))
        if(@sender_name == @receiver_name) {
          play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
        } else {
          if(@receiver_data['is_mentioned']) {
            play_named_sound(ploc(@receiver_name), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver_name))
          } else {
            play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
          }
        }
      }
    }
  }
}

proc _guild_chat(@data, @players_data, @bots, @log_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_setting = @data['sender_setting']
  @sender_guild = @data['sender_guild']
  @unmodified_message = @data['message']
  @guild_owner = null
  #로깅
  if(is_proc('_logging_message')) {
    _logging_message('guild', @sender_uuid, @sender_name, @unmodified_message)
  }
  #리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in _all_players(@bots)) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    @receiver_guild = moori_get_player_guild_id(@receiver_uuid)
    if(@sender_guild == @receiver_guild) {
      @is_guild_same = true
      @guild_role = moori_get_player_guild_role(@receiver_uuid)
      if(@guild_role == 'owner') {
        @guild_owner = array(
          'uuid': @receiver_uuid,
          'name': @receiver_name
        )
      }
    } else {
      @is_guild_same = false
      @guild_role = null
    }
    if(ponline(@receiver_name)) {
      if(array_index_exists(@players_data, @receiver_uuid)) {
        @receiver_setting = @players_data[@receiver_uuid]['setting']
        if(@is_guild_same || @receiver_setting[8]) {
          @receivers[@receiver_uuid] = array(
            'name': @receiver_name,
            'is_online': true,
            'channel': @receiver_setting[0],
            'is_guild_same': @is_guild_same,
            'guild_role': @guild_role,
            'is_listening': @receiver_setting[6],
            'is_observer': @receiver_setting[8],
            'is_mentioned': false
          )
        }
      }
    } else {
      @receiver_setting = cup_get('SETTING', @receiver_uuid)
      if(!is_null(@receiver_setting)) {
        if(@is_guild_same || @receiver_setting[8]) {
          @receivers[@receiver_uuid] = array(
            'name': @receiver_name,
            'is_online': false,
            'channel': @receiver_setting[0],
            'is_guild_same': @is_guild_same,
            'guild_role': @guild_role,
            'is_listening': @receiver_setting[6],
            'is_observer': @receiver_setting[8],
            'is_mentioned': false
          )
        }
      }
    }
  }
  #이름 부분
  @name = array(
    array(
      'text': '',
      'color': '#d5d0f4'
    ),
    array(
      'text': @sender_setting[11].' ',  // 길드 뱃지로 대체할 것
      'color': '#ffffff',
    ),
    array(
      'text': @sender_name,
      'insertion': '@'.@sender_name'',
      'hoverEvent': array(
        'action': 'show_text',
        'value': array(
          '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
          '좌클릭 시, 유저에게 귓속말을 보냅니다',
        )
      ),
      'clickEvent': array(
        'action': 'suggest_command',
        'value': '/w'@sender_name''
      )
    ),
    array(
      'text': ' :: ',
    )
  )
  #메시지 생성 부분
  @mentioned_messages = array()
  @modified_message = array(
    array('text': '')
  )
  foreach(@key: @string in parse_args(@unmodified_message)) {
    @is_modified_message = false
    if(string_starts_with(@string, '@')) {
      @mentioned_message = substr(@string, 1) 
      @eng_length = reg_count('[A-z0-9_]',@mentioned_message)
      @kr_length = reg_count('[가-힣]', @mentioned_message)
      @length = length(@mentioned_message)
      if(@length != 0) {
        if(@length == @eng_length) {
          if(!array_contains(@mentioned_messages, @mentioned_message)) {
            foreach(@receiver_uuid: @receiver_data in @receivers) {
              if(@mentioned_message == @receiver_data['name'] && !is_null(@receiver_data['guild_role'])) {
                @receivers[@receiver_uuid]['is_mentioned'] = true
                @mentioned_messages[] = @mentioned_message
                @is_modified_message = true
                @message = array(
                  'text': @string,
                  'color': 'red',
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
                    'value': '/w'@mentioned_message''
                  )
                )
                break()
              }
            }
          } else {
            @is_modified_message = true
            @message = array(
              'text': @string,
              'color': 'red',
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
                'value': '/w'@mentioned_message''
              )
            )
          }
        } else if(@length == @kr_length) {
          switch(@mentioned_message) {
          case '길드원':
            if(!array_contains(@mentioned_messages, '길드원')) {
              @mentioned_messages[] = '길드원'
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'red',
                'hoverEvent': array(
                  'action': 'show_text',
                  'value': array(
                    '접속중인 길드원:'
                  )
                )
              )
              foreach(@receiver_uuid: @receiver_data in @receivers) {
                if(@receiver_data['guild_role'] == 'member') {
                  @receivers[@receiver_uuid]['is_mentioned'] = true
                  @message['hoverEvent']['value'][] = '\n'.@receiver_data['name']
                }
              }
              @member_list_message = @message
            } else {
              @is_modified_message = true
              @message = @member_list_message
            }
            break()
          case '부길드장':
            if(!array_contains(@mentioned_messages, '부길드장')) {
              @mentioned_messages[] = '부길드장'
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'red',
                'hoverEvent': array(
                  'action': 'show_text',
                  'value': array(
                    '접속중인 부길드장:'
                  )
                )
              )
              foreach(@receiver_uuid: @receiver_data in @receivers) {
                if(@receiver_data['guild_role'] == 'staff') {
                  @receivers[@receiver_uuid]['is_mentioned'] = true
                  @message['hoverEvent']['value'][] = '\n'.@receiver_data['name']
                }
              }
              @staff_list_message = @message
            } else {
              @is_modified_message = true
              @message = @staff_list_message
            }
            break()
          case '길드장':
            if(!array_contains(@mentioned_messages, '길드장')) {
              @mentioned_messages[] = '길드장'
              @is_modified_message = true
              if(!is_null(@guild_owner)) {
                @receivers[@guild_owner['uuid']]['is_mentioned'] = true
                @message = array(
                  'text': @string,
                  'color': 'red',
                  'hoverEvent': array(
                    'action': 'show_text',
                    'value': array(
                      '길드장:'@guild_owner['name']'(온라인)'
                    )
                  )
                )
              } else {
                @guild_owner_name = 'name': bukkitlinked_get_player_name(moori_get_guild_all_members(@sender_guild)[0])
                @message = array(
                  'text': @string,
                  'color': 'red',
                  'hoverEvent': array(
                    'action': 'show_text',
                    'value': array(
                      '길드장:'@guild_owner['name']'(오프라인)'
                    )
                  )
                )
              }
              @member_list_message = @message
            } else {
              @is_modified_message = true
              @message = @member_list_message
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
        'color': 'yellow',
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
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) != 1) {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '
        }
      }
      @modified_message[] = @message
    } else {
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) == 1) {
        @modified_message[] = array(
          'text': @string
        )
      } else {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '.@string
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '.@string
        }
      }
    }
  }
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    if(@receiver_data['is_online']) {
      if(@receiver_data['channel'] == 'guild' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        _tellraw(@receiver_name, array_merge(@name, @modified_message))
        if(@sender_name == @receiver_name) {
          play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
        } else {
          if(@receiver_data['is_mentioned']) {
            play_named_sound(ploc(@receiver_name), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver_name))
          } else {
            play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
          }
        }
      }
    }
  }
}

proc _local_chat(@data, @players_data, @bots, @log_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_setting = @data['sender_setting']
  @is_server_same = @data['is_server_same']
  @near_players = @data['near_players']
  @unmodified_message = @data['message']
  #로깅
  if(is_proc('_logging_message')) {
    _logging_message('local', @sender_uuid, @sender_name, @unmodified_message)
  }
  #리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in _all_players(@bots)) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(array_contains(@near_players, @receiver_name) && array_index_exists(@players_data, @receiver_uuid)) {
      @receiver_setting = @players_data[@receiver_uuid]['setting']
      @receivers[@receiver_uuid] = array(
        'name': @receiver_name,
        'channel': @receiver_setting[0],
        'is_near_player': true,
        'is_listening': @receiver_setting[5],
        'is_observer': @receiver_setting[8],
        'is_mentioned': false
      )
    } else {
      @receiver_setting = cup_get('SETTING', @receiver_uuid)
      if(!is_null(@receiver_setting) && @receiver_setting[8]) {
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'channel': @receiver_setting[0],
          'is_near_player': false,
          'is_listening': @receiver_setting[5],
          'is_observer': true,
          'is_mentioned': false
        )
      }
    }
  }
  #이름 부분
  @name = array(
    array(
      'text': '',
      'color': '#ffd6bf'
    ),
    array(
      'text': @sender_setting[11].' ',
      'color': '#ffffff',
    ),
    array(
      'text': @sender_name,
      'insertion': '@'.@sender_name'',
      'hoverEvent': array(
        'action': 'show_text',
        'value': array(
          '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
          '좌클릭 시, 유저에게 귓속말을 보냅니다',
        )
      ),
      'clickEvent': array(
        'action': 'suggest_command',
        'value': '/w'@sender_name''
      )
    ),
    array(
      'text': ' :: ',
    )
  )
  #메시지 생성 부분
  @mentioned_messages = array()
  @modified_message = array(
    array('text': '')
  )
  foreach(@key: @string in parse_args(@unmodified_message)) {
    @is_modified_message = false
    if(string_starts_with(@string, '@')) {
      @mentioned_message = substr(@string, 1) 
      @eng_length = reg_count('[A-z0-9_]',@mentioned_message)
      @kr_length = reg_count('[가-힣]', @mentioned_message)
      @length = length(@mentioned_message)
      if(@length != 0) {
        if(@length == @eng_length) {
          if(!array_contains(@mentioned_messages, @mentioned_message)) {
            foreach(@receiver_uuid: @receiver_data in @receivers) {
              if(@mentioned_message == @receiver_data['name'] && @receiver_data['is_near_player']) {
                @receivers[@receiver_uuid]['is_mentioned'] = true
                @mentioned_messages[] = @mentioned_message
                @is_modified_message = true
                @message = array(
                  'text': @string,
                  'color': 'red',
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
                    'value': '/w'@mentioned_message''
                  )
                )
                break()
              }
            }
          } else {
            @is_modified_message = true
            @message = array(
              'text': @string,
              'color': 'red',
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
                'value': '/w'@mentioned_message''
              )
            )
          }
        }
      }
    } else if(string_starts_with(@string, './')) {
      @string = replace(@string, './', '/')
      @string = replace(@string, '_', ' ')
      @is_modified_message = true
      @message = array(
        'text': @string,
        'color': 'yellow',
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
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) != 1) {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '
        }
      }
      @modified_message[] = @message
    } else {
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) == 1) {
        @modified_message[] = array(
          'text': @string
        )
      } else {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '.@string
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '.@string
        }
      }
    }
  }
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    if(ponline(@receiver_data['name'])) {
      if(@receiver_data['channel'] == 'local' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        _tellraw(@receiver_name, array_merge(@name, @modified_message))
        if(@sender_name == @receiver_name) {
          play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
        } else {
          if(@receiver_data['is_mentioned']) {
            play_named_sound(ploc(@receiver_name), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver_name))
          } else {
            play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
          }
        }
      }
    }
  }
}

proc _admin_chat(@data, @players_data, @bots, @log_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_setting = @data['sender_setting']
  @unmodified_message = @data['message']
  #로깅
  if(is_proc('_logging_message')) {
    _logging_message('admin', @sender_uuid, @sender_name, @unmodified_message)
  }
  #리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in _all_players(@bots)) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(ponline(@receiver_name)) {
      if(array_index_exists(@players_data, @receiver_uuid) && pisop(@receiver_name)) {
        @receiver_setting = @players_data[@receiver_uuid]['setting']
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'is_online': true,
          'channel': @receiver_setting[0],
          'is_listening': @receiver_setting[7],
          'is_observer': @receiver_setting[8],
          'is_mentioned': false
        )
      }
    } else {
      @receiver_setting = cup_get('SETTING', @receiver_uuid)
      if(!is_null(@receiver_setting) && bukkitlinked_is_player_op(@receiver_uuid)) {
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'is_online': false,
          'channel': @receiver_setting[0],
          'is_listening': @receiver_setting[7],
          'is_observer': @receiver_setting[8],
          'is_mentioned': false
        )
      }
    }
  }
  #이름 부분
  @name = array(
    array(
      'text': '',
      'color': '#fdc4d5',
    ),
    array(
      'text': @sender_setting[11].' ',
      'color': '#ffffff',
    ),
    array(
      'text': @sender_name,
      'insertion': '@'.@sender_name'',
      'hoverEvent': array(
        'action': 'show_text',
        'value': array(
          '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
          '좌클릭 시, 유저에게 귓속말을 보냅니다',
        )
      ),
      'clickEvent': array(
        'action': 'suggest_command',
        'value': '/w'@sender_name''
      )
    ),
    array(
      'text': ' :: ',
    )
  )
  #메시지 생성 부분
  @mentioned_messages = array()
  @modified_message = array(
    array('text': '')
  )
  foreach(@key: @string in parse_args(@unmodified_message)) {
    @is_modified_message = false
    if(string_starts_with(@string, '@')) {
      @mentioned_message = substr(@string, 1) 
      @eng_length = reg_count('[A-z0-9_]',@mentioned_message)
      @kr_length = reg_count('[가-힣]', @mentioned_message)
      @length = length(@mentioned_message)
      if(@length != 0) {
        if(@length == @eng_length) {
          if(!array_contains(@mentioned_messages, @mentioned_message)) {
            foreach(@receiver_uuid: @receiver_data in @receivers) {
              if(@mentioned_message == @receiver_data['name']) {
                @receivers[@receiver_uuid]['is_mentioned'] = true
                @mentioned_messages[] = @mentioned_message
                @is_modified_message = true
                @message = array(
                  'text': @string,
                  'color': 'red',
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
                    'value': '/w'@mentioned_message''
                  )
                )
                break()
              }
            }
          } else {
            @is_modified_message = true
            @message = array(
              'text': @string,
              'color': 'red',
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
                'value': '/w'@mentioned_message''
              )
            )
          }
        } else if(@length == @kr_length) {
          @admin = array('스태프', '스탭', '스탭진', '스탭팀', '운영', '운영자', '운영진', '운영팀', '관리자', '어드민', '오피')
          if(array_contains(@admin, @mentioned_message)) {
            if(!array_contains(@mentioned_messages, '관리자')) {
              @mentioned_messages[] = '관리자'
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'red',
                'hoverEvent': array(
                  'action': 'show_text',
                  'value': array(
                    '접속중인 관리자:'
                  )
                )
              )
              foreach(@receiver_uuid: @receiver_data in @receivers) {
                @receivers[@receiver_uuid]['is_mentioned'] = true
                @message['hoverEvent']['value'][] = '\n'.@receiver_data['name']
              }
              @op_list_message = @message
            } else {
              @is_modified_message = true
              @message = @op_list_message
            }
          }
        }
      }
    } else if(string_starts_with(@string, './')) {
      @string = replace(@string, './', '/')
      @string = replace(@string, '_', ' ')
      @is_modified_message = true
      @message = array(
        'text': @string,
        'color': 'yellow',
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
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) != 1) {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '
        }
      }
      @modified_message[] = @message
    } else {
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) == 1) {
        @modified_message[] = array(
          'text': @string
        )
      } else {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '.@string
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '.@string
        }
      }
    }
  }
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    if(@receiver_data['is_online']) {
      if(@receiver_data['channel'] == 'admin' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        _tellraw(@receiver_name, array_merge(@name, @modified_message))
        if(@sender_name == @receiver_name) {
          play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
        } else {
          if(@receiver_data['is_mentioned']) {
            play_named_sound(ploc(@receiver_name), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver_name))
          } else {
            play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
          }
        }
      }
    }
  }
}

bind('async_player_chat', null , null, @event, @players_data, @bots, @log_data) {
  cancel()
  @data = array(
    'sender_name': @event['player'],
    'sender_uuid': puuid(@event['player'])
  )
  if(array_index_exists(@players_data, @data['sender_uuid'])) {
    @data['sender_setting'] = @players_data[@data['sender_uuid']]['setting']
    if(@data['sender_setting'][1]) {
      @data['message'] = _en_to_ko(@event['message'])
    } else {
      @data['message'] = @event['message']
    }
    switch(@players_data[@data['sender_uuid']]['setting'][0]) {
    case 'default':
      _bungeecord_foward(@data['sender_name'], 'ch_default_chat', @data)
      _default_chat(@data, @players_data, @bots, @log_data)
      break()
    case 'guild':
      @sender_guild = moori_get_player_guild_id(@data['sender_uuid'])
      if(!is_null(@sender_guild)) {
        @data['sender_guild'] = @sender_guild
        _bungeecord_foward(@data['sender_name'], 'ch_guild_chat', @data)
        _guild_chat(@data, @players_data, @bots, @log_data)
      } else {
        @players_data[@sender_uuid]['setting'][0] = 'default'
        cup_set('SETTING', @sender_uuid, @players_data[@sender_uuid]['setting'])
      }
      break()
    case 'local':
      @data['near_players'] = players_in_radius(ploc(@data['sender_name']), 64)
      @data['is_server_same'] = false
      _bungeecord_foward(@data['sender_name'], 'ch_local_chat', @data)
      @data['is_server_same'] = true
      _local_chat(@data, @players_data, @bots, @log_data)
      break()
    case 'admin':
      _bungeecord_foward(@data['sender_name'], 'ch_admin_chat', @data)
      _admin_chat(@data, @players_data, @bots, @log_data)
      break()
    }
  }
}

proc _broadcast(@sender_name, @sender_uuid, @unmodified_message, @setting, @bots, @log_data) {
  @enko = @setting[1]
  if(@enko) {
    @modified_message = _convert_eng_to_kor(@unmodified_message)
    if(@modified_message){
      @reg = reg_match_all('\\[([^\\]]*)\\]', @unmodified_message)
      foreach(@arr in @reg){
        @converted = _convert_eng_to_kor(@arr[0])
        @modified_message = replace(@modified_message, @converted, @arr[1])
      }
    } else {
      @modified_message = @unmodified_message
    }
  } else {
    @modified_message = @unmodified_message
  }
  if(is_proc('_logging_message')) {
    _logging_message('broadcast', @sender_uuid, @sender_name, @unmodified_message)
  }
  @raw = array(
    array(
      'text': '\ue4db '
    ),
    array(
      'text': @modified_message,
      'color': '#80c8ff'
    )
  )
  @receiver_uuids = _all_players(@bots)
  foreach(@receiver_uuid in @receiver_uuids) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(ponline(@receiver_name)) {
      tellraw(@receiver_name, @raw)
      play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
    } else {
      @data = array(
        'raw': @raw
      )
      _bungeecord_foward(@sender_name, 'ch_broadcast', @data)
    }
  }
}

register_command('broadcast', array(
  'description': 'can broadcast',
  'usage': '/broadcast <msg>',
  'aliases': array('say'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(ponline(@player)) {
      @sender_name = @player
      @sender_uuid = puuid(@sender_name)
      if(array_index_exists(@players_data, @sender_uuid) && array_size(@args) > 0) {
        @imploded_message = array_implode(array_get(@args, cslice(0, array_size(@args) - 1)), ' ')
        @setting = @players_data[@sender_uuid]['setting']
        _broadcast(@sender_name, @sender_uuid, @imploded_message, @setting, @bots, @log_data)
      } else {
        tmsg(@player, color('yellow')'/'.@command'<message>')
      }
    } else {
      @sender_name = 'console'
      @sender_uuid = 'console'
      if(array_size(@args) > 0) {
        @imploded_message = array_implode(array_get(@args, cslice(0, array_size(@args) - 1)), ' ')
        @setting = array('broadcast', false)
        _broadcast(@sender_name, @sender_uuid, @imploded_message, @setting, @bots, @log_data)
      } else {
        console(color('yellow')'/'.@command'<message>')
      }
    }
  }
))

proc _whisper(@data, @log_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_setting = @data['sender_setting']
  @target_name = @data['target_name']
  @target_uuid = @data['target_uuid']
  @unmodified_message = @data['message']
  #리시버 설정
  @receivers = @data['receivers']
  #로깅
  if(is_proc('_logging_whisper')) {
    _logging_whisper('whisper', @sender_uuid, @sender_name, @target_uuid, @target_name, @unmodified_message)
  }
  #메시지 생성 부분
  @modified_message = array(
    array('text': '')
  )
  foreach(@key: @string in parse_args(@unmodified_message)) {
    @is_modified_message = false
    if(string_starts_with(@string, './')) {
      @string = replace(@string, './', '/')
      @string = replace(@string, '_', ' ')
      @is_modified_message = true
      @message = array(
        'text': @string,
        'color': 'yellow',
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
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) != 1) {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '
        }
      }
      @modified_message[] = @message
    } else {
      @pre_message = @modified_message[array_size(@modified_message) -1]
      if(array_size(@modified_message) == 1) {
        @modified_message[] = array(
          'text': @string
        )
      } else {
        if(array_index_exists(@pre_message, 'color')) {
          @modified_message[] = array(
            'text': ' '.@string
          )
        } else {
          @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '.@string
        }
      }
    }
  }
  #이름 부분
  @target_raw = array(
    array(
      'text': 'From ',
      'color': 'gray',
    ),
    array(
      'text': @sender_name,
      'hoverEvent': array(
        'action': 'show_text',
        'value': array(
          '좌클릭 시, 유저에게 귓속말을 보냅니다'
        )
      ),
      'clickEvent': array(
        'action': 'suggest_command',
        'value': '/w'@sender_name''
      )
    ),
    array(
      'text': ' :: ',
    ),
    @modified_message
  )
  @observer_raw = array(
    array(
      'text': @sender_name.' To '.@target_name,
      'color': 'gray',
    ),
    array(
      'text': ' :: ',
    ),
    @modified_message
  )
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    @receiver_name = @receiver_data['name']
    if(ponline(@receiver_name)) {
      if(@receiver_data['is_target']) {
        _tellraw(@receiver_name, @target_raw)
        play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
      } else {
        _tellraw(@receiver_name, @observer_raw)
        play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
      }
    }
  }
}

register_command('whisper', array(
  'description': 'can whisper',
  'usage': '/whisper <player> <msg>',
  'aliases': array('w', 'm', 'msg', 'tell'),
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 1) {
      @online_players = array()
      foreach(@target_uuid in _all_players(@bots)) {
        @online_players[] = bukkitlinked_get_player_name(@target_uuid)
      }
      array_remove_values(@online_players, @player)
      @input = @args[-1]
      return(array_filter(@online_players, closure(@key, @value) {
        return(length(@input) <= length(@value) && equals_ic(@input, substr(@value, 0, length(@input))))
      }))
    } else {
      return(array())
    }
  },
  'executor': closure(@command, @player, @args) {
    @sender_name = @player
    @sender_uuid = puuid(@sender_name)
    if(array_index_exists(@players_data, @sender_uuid)) {
      if(array_size(@args) > 1) {
        @data = array(
          'sender_name': @sender_name,
          'sender_uuid': @sender_uuid,
          'sender_setting': @players_data[@sender_uuid]['setting']
        )
        @is_target_exists = false
        @all_players_uuid = _all_players(@bots)
        array_remove_values(@all_players_uuid, @sender_uuid)
        @receivers = array()
        foreach(@receiver_uuid in @all_players_uuid) {
          @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
          if(@receiver_name == @args[0]) {
            @is_target_exists = true
            @receivers[@receiver_uuid] = array(
              'name': @receiver_name,
              'is_target': true
            )
            @data['target_name'] = @receiver_name
            @data['target_uuid'] = @receiver_uuid
          } else {
            if(ponline(@receiver_name) && array_index_exists(@players_data, @receiver_uuid)) {
              @receiver_setting = @players_data[@receiver_uuid]['setting']
              if(@receiver_setting[8]) {
                @receivers[@receiver_uuid] = array(
                  'name': @receiver_name,
                  'is_target': false
                )
              }
            } else {
              @receiver_setting = cup_get('SETTING', @receiver_uuid)
              if(!is_null(@receiver_setting) && @receiver_setting[8]) {
                @receivers[@receiver_uuid] = array(
                  'name': @receiver_name,
                  'is_target': false
                )
              }
            }
          }
        }
        @data['receivers'] = @receivers
        if(@is_target_exists) {
          if(@data['sender_setting'][1]) {
            @data['message'] = _en_to_ko(array_implode(array_get(@args, cslice(1, array_size(@args) - 1)), ' '))
          } else {
            @data['message'] = array_implode(array_get(@args, cslice(1, array_size(@args) - 1)), ' ')
          }
          _bungeecord_foward(@sender_name, 'ch_whisper', @data)
          @modified_message = array(
            array('text': '')
          )
          foreach(@key: @string in parse_args(@data['message'])) {
            @is_modified_message = false
            if(string_starts_with(@string, './')) {
              @string = replace(@string, './', '/')
              @string = replace(@string, '_', ' ')
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'yellow',
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
              @pre_message = @modified_message[array_size(@modified_message) -1]
              if(array_size(@modified_message) != 1) {
                if(array_index_exists(@pre_message, 'color')) {
                  @modified_message[] = array(
                    'text': ' '
                  )
                } else {
                  @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '
                }
              }
              @modified_message[] = @message
            } else {
              @pre_message = @modified_message[array_size(@modified_message) -1]
              if(array_size(@modified_message) == 1) {
                @modified_message[] = array(
                  'text': @string
                )
              } else {
                if(array_index_exists(@pre_message, 'color')) {
                  @modified_message[] = array(
                    'text': ' '.@string
                  )
                } else {
                  @modified_message[array_size(@modified_message) -1]['text'] = @pre_message['text'].' '.@string
                }
              }
            }
          }
          #이름 부분
          @sender_raw = array(
            array(
              'text': 'To ',
              'color': 'gray',
            ),
            array(
              'text': @data['target_name'],
              'hoverEvent': array(
                'action': 'show_text',
                'value': array(
                  '좌클릭 시, 유저에게 귓속말을 보냅니다'
                )
              ),
              'clickEvent': array(
                'action': 'suggest_command',
                'value': '/w'@data['target_name']''
              )
            ),
            array(
              'text': ' :: ',
            ),
            @modified_message
          )
          #센더에게 tellraw
          _tellraw(@sender_name, @sender_raw)
          play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
          _whisper(@data, @log_data)
        } else {
          tmsg(@player, '\ue4de'color('gray').'플레이어를 찾을 수 없습니다.')
        }
      } else {
        tmsg(@player, '\ue4dd'color('yellow').'/'.@command'<플레이어> <할 말>'.color('gray').'을 통해 귓속말을 보낼 수 있습니다.')
      }
    }
  }
))