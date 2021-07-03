# enko
include('eng_to_kor_translater.ms')

/* 구 로깅
  @log_data = array()
  if(@server['name'] == 'main') {
    proc _logging_message(@type, @uuid, @player, @message) {
      @time = simple_date('yyyy-MM-dd HH:mm:ss')
      @message = replace(@message, '\\', '\\\\')
      @message = replace(@message, '\'', '\\\'')
      query_async('evatuna', "INSERT INTO log_chat(`time`, `type`, `uuid`, `name`, `message`) VALUES (\'".@time."\', \'".@type."\', \'".@uuid."\', \'".@player."\', \'".@message."\')", closure())
    }
    proc _logging_whisper(@type, @sender_uuid, @sender_name, @receiver_uuid, @receiver_name, @message) {
      @time = simple_date('yyyy-MM-dd HH:mm:ss')
      @message = replace(@message, '\\', '\\\\')
      @message = replace(@message, '\'', '\\\'')
      query_async('evatuna', "INSERT INTO log_whisper(`time`, `sender_uuid`, `sender_name`, `receiver_uuid`, `receiver_name`, `message`) VALUES (\'".@time."\', \'".@sender_uuid."\', \'".@sender_name."\', \'".@receiver_uuid."\', \'".@receiver_name."\', \'".@message."\')", closure())
    }
  }
*/

/* 이모지
  @emoji_data = array(
    'player': array(),
    'guild': array()
  )

  proc _load_player_emoji(@player) {}
  proc _save_player_emoji(@player) {}
  proc _load_guilds_emoji() {}
  proc _load_guild_emoji(@guild) {}
  proc _save_guild_emoji(@guild) {}
*/

# tellraw 메인 쓰레드로 보내기
proc _tellraw(@player, @raw) {
  if(x_get_current_thread() == 'Server thread') {
    tellraw(@player, @raw)
  } else {
    x_run_on_main_thread_now(closure() {
      tellraw(@player, @raw)
    })
  }
}

# 채팅 로깅
proc _chat_logging(@log) {
  if(x_get_current_thread() == 'Server thread') {
    # 로그 남기는 펑션
  } else {
    x_run_on_main_thread_now(closure() {
      # 로그 남기는 펑션
    })
  }
}

# enko
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

# 기본 채팅
proc _default_chat(@data, @players_data) {
  # 변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_setting = @data['sender_setting']
  @unmodified_message = @data['message']
  # 리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
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
          if(ponline(@sender_name)) {
            play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
          }
        } else {
          if(@receiver_data['is_mentioned']) {
            if(ponline(@receiver_name)) {
              play_named_sound(ploc(@receiver_name), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver_name))
            }
          } else {
            if(ponline(@receiver_name)) {
              play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
            }
          }
        }
      }
    }
  }
}

proc _town_chat(@data, @players_data) {
  # 변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_setting = @data['sender_setting']
  @sender_guild = @data['sender_guild']
  @unmodified_message = @data['message']
  @town_members = @data['town_members']
  # 리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
    if(array_contains(@town_members, @receiver_uuid)) { // 마을원일시
      @receiver_role = tunalands_get_player_rank(@receiver_uuid)
    } else {
      @receiver_role = null
    }
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(ponline(@receiver_name)) {
      if(array_index_exists(@players_data, @receiver_uuid)) {
        @receiver_setting = @players_data[@receiver_uuid]['setting']
        if(!is_null(@receiver_role) || @receiver_setting[8]) {
          @receivers[@receiver_uuid] = array(
            'name': @receiver_name,
            'is_online': true,
            'channel': @receiver_setting[0],
            'town_role': @receiver_role,
            'is_listening': @receiver_setting[6],
            'is_observer': @receiver_setting[8],
            'is_mentioned': false
          )
        }
      }
    } else {
      @receiver_setting = cup_get('SETTING', @receiver_uuid)
      if(!is_null(@receiver_setting)) {
        if(!is_null(@receiver_role) || @receiver_setting[8]) {
          @receivers[@receiver_uuid] = array(
            'name': @receiver_name,
            'is_online': false,
            'channel': @receiver_setting[0],
            'town_role': @receiver_role,
            'is_listening': @receiver_setting[6],
            'is_observer': @receiver_setting[8],
            'is_mentioned': false
          )
        }
      }
    }
  }
  # 이름 부분
  @name = array(
    array(
      'text': '',
      'color': '#16A085'
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
              if(@mentioned_message == @receiver_data['name'] && !is_null(@receiver_data['town_role'])) {
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
          /*
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
                if(@receiver_data['town_role'] == 'member') {
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
                if(@receiver_data['town_role'] == 'staff') {
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
              if(!is_null(@town_owner)) {
                @receivers[@town_owner['uuid']]['is_mentioned'] = true
                @message = array(
                  'text': @string,
                  'color': 'red',
                  'hoverEvent': array(
                    'action': 'show_text',
                    'value': array(
                      '길드장:'@town_owner['name']'(온라인)'
                    )
                  )
                )
              } else {
                @town_owner_name = bukkitlinked_get_player_name(moori_get_guild_all_members(@sender_town)[0])
                @message = array(
                  'text': @string,
                  'color': 'red',
                  'hoverEvent': array(
                    'action': 'show_text',
                    'value': array(
                      '길드장:'@town_owner['name']'(오프라인)'
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
          */
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
      if(@receiver_data['channel'] == 'town' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        _tellraw(@receiver_name, array_merge(@name, @modified_message))
        if(@sender_name == @receiver_name) {
          if(ponline(@sender_name)) {
            play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
          }
        } else {
          if(@receiver_data['is_mentioned']) {
            if(ponline(@receiver_name)) {
              play_named_sound(ploc(@receiver_name), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver_name))
            }
          } else {
            if(ponline(@receiver_name)) {
              play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
            }
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
  #리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
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
      'color': '#D35400'
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
          if(ponline(@sender_name)) {
            play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
          }
        } else {
          if(@receiver_data['is_mentioned']) {
            if(ponline(@receiver_name)) {
              play_named_sound(ploc(@receiver_name), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver_name))
            }
          } else {
            if(ponline(@receiver_name)) {
              play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
            }
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
  #리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
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
      'color': '#C0392B',
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
          if(ponline(@sender_name)) {
            play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
          }
        } else {
          if(@receiver_data['is_mentioned']) {
            if(ponline(@receiver_name)) {
              play_named_sound(ploc(@receiver_name), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver_name))
            }
          } else {
            if(ponline(@receiver_name)) {
              play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
            }
          }
        }
      }
    }
  }
}

bind('async_player_chat', null , null, @event, @players_data, @text) {
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
      # 카프카
      kafka_send('send_defaultchat', json_encode(@data))
      # proc
      _default_chat(@data, @players_data)
      # logging
      sys_out('[DefaultChat]'@data['sender_name'].':'@event['message'])
      break()
    case 'town':
      @town_members = tunalands_get_player_lands_member_list(@data['sender_uuid'])
      if(!is_null(@town_members)) {
        @data['town_members'] = @town_members
        # 카프카
        kafka_send('send_townchat', json_encode(@data))
        # proc
        _town_chat(@data, @players_data)
        # logging
        sys_out('[TownChat]'@data['sender_name'].':'@event['message'])
      } else {
        # 마을을 찾을수 없어서 채팅 채널 초기화
        @players_data[@sender_uuid]['setting'][0] = 'default'
        cup_set('SETTING', @sender_uuid, @players_data[@sender_uuid]['setting'])
        tmsg(@data['sender_name'], @text['prefix'] '§7가입된 마을이 없어 일반 채널로 변경됩니다.')
      }
      break()
    case 'local':
      @data['near_players'] = players_in_radius(ploc(@data['sender_name']), 64)
      # 카프카
      @data['is_server_same'] = false
      kafka_send('send_localchat', json_encode(@data))
      # proc
      @data['is_server_same'] = true
      _local_chat(@data, @players_data)
      # logging
      sys_out('[LocalChat]'@data['sender_name'].':'@event['message'])
      break()
    case 'admin':
      # 카프카
      kafka_send('send_adminchat', json_encode(@data))
      # proc
      _admin_chat(@data, @players_data)
      # logging
      sys_out('[AdminChat]'@data['sender_name'].':'@event['message'])
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
  # logging
  sys_out('[Broadcast]]'@sender_name.':'@modified_message)

  @raw = array(
    array(
      'text': '\ue4db '
    ),
    array(
      'text': @modified_message,
      'color': '#80c8ff'
    )
  )
  @receiver_uuids = bukkitlinked_get_all_players()
  foreach(@receiver_uuid in @receiver_uuids) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(ponline(@receiver_name)) {
      tellraw(@receiver_name, @raw)
      if(ponline(@receiver_name)) {
        play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
      }
    }
  }
  @data = array(
    'raw': @raw
  )
  kafka_send('send_broadcast', json_encode(@data))
}

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
      'color': '#7F8C8D',
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
      'color': '#7F8C8D',
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
        if(ponline(@receiver_name)) {
          play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
        }
      } else {
        _tellraw(@receiver_name, @observer_raw)
        if(ponline(@receiver_name)) {
          play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
        }
      }
    }
  }
}