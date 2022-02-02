# enko
export('Cho', split(' ', 'ㄱ ㄲ ㄴ ㄷ ㄸ ㄹ ㅁ ㅂ ㅃ ㅅ ㅆ ㅇ ㅈ ㅉ ㅊ ㅋ ㅌ ㅍ ㅎ'))
export('Cho.eng', split(' ', 'r R s e E f a q Q t T d w W c z x v g'))
export('Jung', split(' ', 'ㅏ ㅐ ㅑ ㅒ ㅓ ㅔ ㅕ ㅖ ㅗ ㅘ ㅙ ㅚ ㅛ ㅜ ㅝ ㅞ ㅟ ㅠ ㅡ ㅢ ㅣ'))
export('Jung.eng', split(' ', 'k o i O j p u P h hk ho hl y n nj np nl b m ml l'))
@temp = split(' ', 'ㄱ ㄲ ㄳ ㄴ ㄵ ㄶ ㄷ ㄹ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅁ ㅂ ㅄ ㅅ ㅆ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ ㅎ')
array_insert(@temp, ' ', 0)
export('Jong', @temp)

proc _is_korean(@txt) {
	if(length(reg_match('[가-힣]', @txt)) <= 0) {
		return(false)
	}
	return(true)
}

proc _uncrafting(@txt) {
	@code = unicode_from_char(substr(@txt, 0, 1)) - 44032
	@var = array_resize(array(), 3)
	@var[0] = floor(@code / 588)
	@var[1] = floor((@code % 588) / 28)
	@var[2] = floor((@code % 588) - (@var[1] * 28))
	return(array(import('Cho')[@var[0]], import('Jung')[@var[1]], import('Jong')[@var[2]]))
}

proc _crafting(@cho, @jung, @jong) {
	if(!array_contains(import('Cho'), @cho) || !array_contains(import('Jung'), @jung) || !array_contains(import('Jong'), @jong)) {
		return(@cho.''.@jung.''.@jong)
	}
	@choi = multiply(array_index(import('Cho'), @cho), 588)
	@jungi = multiply(array_index(import('Jung'), @jung), 28)
	@jongi = array_index(import('Jong'), @jong)
	@txt = char_from_unicode(add(@choi, @jungi, @jongi, 44032))
	return(@txt)
}

proc _txt_backspace(@txt) {
	if(@txt == '', return(''));
	@arr = split('', @txt);
	@ret = ''
	for(@i = 0, @i < subtract(array_size(@arr), 1), @i++){
		@ret = concat(@ret, @arr[@i]);
	}
	return(@ret);
}

proc _deduction_jong(@txt) {
	@txt1 = replace(replace(replace(replace(replace(replace(@txt, 'ㄱㅅ', 'ㄳ'), 'ㄴㅈ', 'ㄵ'), 'ㄴㅎ', 'ㄶ'), 'ㄹㄱ', 'ㄺ'), 'ㄹㅁ', 'ㄻ') ,'ㄹㅂ', 'ㄼ')
	@txt2 = replace(replace(replace(replace(replace(@txt1, 'ㄹㅅ', 'ㄽ'), 'ㄹㅌ', 'ㄾ'), 'ㄹㅍ', 'ㄿ'), 'ㄹㅎ', 'ㅀ'), 'ㅂㅅ', 'ㅄ')
	return(@txt2)
}

proc _deduction_jung(@txt) {
	@txt1 = replace(replace(replace(replace(replace(replace(replace(@txt, 'ㅗㅏ', 'ㅘ'), 'ㅗㅐ', 'ㅙ'), 'ㅗㅣ', 'ㅚ'), 'ㅜㅓ', 'ㅝ'), 'ㅜㅣ', 'ㅟ'), 'ㅡㅣ', 'ㅢ'), 'ㅜㅔ', 'ㅞ');
	return(@txt1)
}

proc _convert_eng_to_kor(@txt) {
	foreach(@k:@t in split('', @txt)) { //한국어섞이면 번역 X
		if(_is_korean(@t), return(false))
	}
	@txts = split(' ', @txt); //스페이스바로 번역할 영어들 구분
	@txtarr = array();
	for(@i = 0, @i < array_size(@txts), @i++) { //영어에서 한글로 이동.
		@txtpush = '';
		foreach(@k:@t in split('', @txts[@i])) {
			if(array_contains(import('Cho.eng'), @t)) {
				@key = array_index(import('Cho.eng'), @t);
				@txtpush = concat(@txtpush, import('Cho')[@key])
			}else if(array_contains_ic(import('Cho.eng'), @t)) {
				@key = array_index(import('Cho.eng'), to_lower(@t));
				@txtpush = concat(@txtpush, import('Cho')[@key]);
			}else if(array_contains(import('Jung.eng'), @t)) {
				@key = array_index(import('Jung.eng'), @t);
				@txtpush = concat(@txtpush, import('Jung')[@key])
			}else if(array_contains_ic(import('Jung.eng'), @t)) {
				@key = array_index(import('Jung.eng'), to_lower(@t));
				@txtpush = concat(@txtpush, import('Jung')[@key])
			}else{@txtpush = concat(@txtpush, @t); }
		}
		array_push(@txtarr, @txtpush)
	}
	foreach(@k:@t in @txtarr) { // 모음들 중 ㅘ 같은 합성들을 조합.
		array_set(@txtarr, @k, _deduction_jung(@t));
	}
	@txtarr2 = array();
	for(@i = 0, @i < array_size(@txtarr), @i++) { // 받침없는 글자 조합.
		@txtpush = '';
		foreach(@k:@t in split('', @txtarr[@i])) {
			if(array_contains(import('Jung'), @t) && @k != 0) {
				@cho = split('', @txtarr[@i])[subtract(@k, 1)];
				@jung = @t;
				@txtpush = _txt_backspace(@txtpush)
				@dummytxt = _crafting(@cho, @jung, ' ')
			}else{ @dummytxt = @t; }
			@txtpush = concat(@txtpush, @dummytxt)
		}
		array_push(@txtarr2, @txtpush)
	}
	@txtarr3 = array();
	foreach(@k:@t in @txtarr2) { // 받침들 중 ㄶ 같은 합성들을 조합.
		array_push(@txtarr3, _deduction_jong(@t));
	}
	@txtarr4 = array();
	for(@i = 0, @i < array_size(@txtarr3), @i++) { //글자와 받침 조합.
		@txtpush = '';
		@split = split('', @txtarr3[@i]); array_reverse(@split);
		foreach(@k:@t in @split) {
			if(array_contains(import('Jong'), @t)) {
				if(array_index_exists(@split, @k+1) && _is_korean(@split[@k+1])) {
					@chojung = _uncrafting(@split[@k+1])
					array_set(@chojung, 2, @t);
					array_remove(@split, @k+1);
					@dummytxt = _crafting(@chojung[0], @chojung[1], @chojung[2]);
				}else{ @dummytxt = @t; }
			}else{ @dummytxt = @t }
			@txtpush = concat(@txtpush ,@dummytxt)
		}
		array_push(@txtarr4, @txtpush)
	} // 글자가 뒤집어져서 반환.
	@result = '';
	foreach(@k:@t in @txtarr4) { //뒤집어진걸 정상화 시킨후 String화
		@rettxt = '';
		@split = split('', @t);
		array_reverse(@split);
		foreach(@t2 in @split){
			@rettxt = concat(@rettxt, @t2);
		}
		if(@k == 0, @result = concat(@result, @rettxt), @result = sconcat(@result, @rettxt))
	}
	return(@result)
}

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

# Channel Tag
proc _update_channel_tag(@uuid, @player_data, @text) {
  @channel_tags = array(
    'general_en': '\ue3f9',
    'general_ko': '\ue3fa',
    'town_en': '\ue3fb',
    'town_ko': '\ue3fc',
    'local_en': '\ue3fd',
    'local_ko': '\ue3fe',
    'admin_en': '\ue3ff',
    'admin_ko': '\ue400',
    'party_en': '\ue401',
    'party_ko': '\ue402',
    'dummy_en': '\ue403',
    'dummy_ko': '\ue404'
  )
  switch(@player_data['chat'][1]) {
  case true:
    switch(@player_data['chat'][0]) {
    case 'general':
      @channel_tag = 'general_ko'
    case 'town':
      @channel_tag = 'town_ko'
    case 'local':
      @channel_tag = 'local_ko'
    case 'admin':
      @channel_tag = 'admin_ko'
    case 'party':
      @channel_tag = 'party_ko'
    default:
      @channel_tag = 'general_ko'
    }
  case false:
  switch(@player_data['chat'][0]) {
    case 'general':
      @channel_tag = 'general_en'
    case 'town':
      @channel_tag = 'town_en'
    case 'local':
      @channel_tag = 'local_en'
    case 'admin':
      @channel_tag = 'admin_en'
    case 'party':
      @channel_tag = 'party_en'
    default:
      @channel_tag = 'general_en'
    }
  }
  _set_sidebar(@uuid, 0, color('#feff00').@channel_tags[@channel_tag], @text)
}

# Default Chat
proc _default_chat(@data, @players_data) {
  # 변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_chat_data = @data['sender_chat_data']
  @sender_badge = @data['sender_badge']
  @unmodified_message = @data['message']
  # 리시버 데이터 세팅
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(ponline(@receiver_name)) {
      if(array_index_exists(@players_data, @receiver_uuid)) {
        # Data
        @receiver_data = @players_data[@receiver_uuid]
        @chat_data = @receiver_data['chat']
        # Listening Chanel
        @listening_chanels = json_decode(@chat_data[2])
        if(array_contains(@listening_chanels, 'default')) {
          @is_listening = true
        } else {
          @is_listening = false
        }
        # Receiver Setting
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'is_online': true,
          'is_op': pisop(@receiver_name),
          'channel': @chat_data[0],
          'is_listening': @is_listening,
          'is_observer': @chat_data[3],
          'is_mentioned': false
        )
      }
    } else {
      # Data
      @chat_data = cup_get('CHAT', @receiver_uuid)
      if(!is_null(@chat_data)) {
        # Listening Chanel
        @listening_chanels = json_decode(@chat_data[2])
        if(array_contains(@listening_chanels, 'default')) {
          @is_listening = true
        } else {
          @is_listening = false
        }
        # Receiver Setting
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'is_online': false,
          'is_op': bukkitlinked_is_player_op(@receiver_uuid),
          'channel': @chat_data[0],
          'is_listening': @is_listening,
          'is_observer': @chat_data[3],
          'is_mentioned': false
        )
      }
    }
  }
  #이름 부분
  @name = array(
    array(
      'text': @sender_badge.' ',
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
  @sender_chat_data = @data['sender_chat_data']
  @sender_badge = @data['sender_badge']
  @unmodified_message = @data['message']
  @town_members = @data['town_members']
  # 리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(array_contains(@town_members, @receiver_name)) { // 마을원일시
      @receiver_role = tunalands_get_player_rank(@receiver_uuid)
    } else {
      @receiver_role = null
    }
    if(ponline(@receiver_name)) {
      if(array_index_exists(@players_data, @receiver_uuid)) {
        # Data
        @receiver_data = @players_data[@receiver_uuid]
        @chat_data = @receiver_data['chat']
        # Listening Chanel
        @listening_chanels = json_decode(@chat_data[2])
        if(array_contains(@listening_chanels, 'town')) {
          @is_listening = true
        } else {
          @is_listening = false
        }
        # Receiver Setting
        if(!is_null(@receiver_role) || @chat_data[3]) {
          @receivers[@receiver_uuid] = array(
            'name': @receiver_name,
            'is_online': true,
            'channel': @chat_data[0],
            'town_role': @receiver_role,
            'is_listening': @is_listening,
            'is_observer': @chat_data[3],
            'is_mentioned': false
          )
        }
      }
    } else {
      # Data
      @chat_data = cup_get('CHAT', @receiver_uuid)
      if(!is_null(@chat_data)) {
        # Listening Chanel
        @listening_chanels = json_decode(@chat_data[2])
        if(array_contains(@listening_chanels, 'town')) {
          @is_listening = true
        } else {
          @is_listening = false
        }
        if(!is_null(@receiver_role) || @chat_data[3]) {
          # Receiver Setting
          @receivers[@receiver_uuid] = array(
            'name': @receiver_name,
            'is_online': false,
            'channel': @chat_data[0],
            'town_role': @receiver_role,
            'is_listening': @is_listening,
            'is_observer': @chat_data[3],
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
      'text': @sender_badge.' ',  // 길드 뱃지로 대체할 것
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
          switch(@mentioned_message) {
          case '알바':
            if(!array_contains(@mentioned_messages, '알바')) {
              @mentioned_messages[] = '알바'
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'red',
                'hoverEvent': array(
                  'action': 'show_text',
                  'value': array(
                    '접속중인 알바:'
                  )
                )
              )
              foreach(@receiver_uuid: @receiver_data in @receivers) {
                if(@receiver_data['town_role'] == 'MEMBER') { //알바 로 설정
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
          case '주민':
            if(!array_contains(@mentioned_messages, '주민')) {
              @mentioned_messages[] = '주민'
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'red',
                'hoverEvent': array(
                  'action': 'show_text',
                  'value': array(
                    '접속중인 주민:'
                  )
                )
              )
              foreach(@receiver_uuid: @receiver_data in @receivers) {
                if(@receiver_data['town_role'] == 'MEMBER') {
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
          case '부이장':
            if(!array_contains(@mentioned_messages, '부이장')) {
              @mentioned_messages[] = '부이장'
              @is_modified_message = true
              @message = array(
                'text': @string,
                'color': 'red',
                'hoverEvent': array(
                  'action': 'show_text',
                  'value': array(
                    '접속중인 부이장:'
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
          case '이장':
            if(!array_contains(@mentioned_messages, '이장')) {
              @mentioned_messages[] = '이장'
              @is_modified_message = true
              foreach(@town_member in @town_members) {
                @town_member_uuid = bukkitlinked_get_player_uuid(@town_member)
                if(array_index_exists(@receivers,  @town_member_uuid) && @receivers[@town_member_uuid]['town_role'] == 'OWNER') {
                  @town_owner = array(
                    'name': @town_member,
                    'uuid':@town_member_uuid
                  )
                  break()
                }
              }
              if(array_contains(bukkitlinked_get_all_players(), @town_owner['uuid'])) {
                @receivers[@town_owner['uuid']]['is_mentioned'] = true
                @message = array(
                  'text': @string,
                  'color': 'red',
                  'hoverEvent': array(
                    'action': 'show_text',
                    'value': array(
                      '이장:'@town_owner['name']'(온라인)'
                    )
                  )
                )
              } else {
                @message = array(
                  'text': @string,
                  'color': 'red',
                  'hoverEvent': array(
                    'action': 'show_text',
                    'value': array(
                      '이장:'@town_owner['name']'(오프라인)'
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

proc _local_chat(@data, @players_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_chat_data = @data['sender_chat_data']
  @sender_badge = @data['sender_badge']
  @is_server_same = @data['is_server_same']
  @near_players = @data['near_players']
  @unmodified_message = @data['message']
  #리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(array_contains(@near_players, @receiver_name) && array_index_exists(@players_data, @receiver_uuid)) {
      # Data
      @receiver_data = @players_data[@receiver_uuid]
      @chat_data = @receiver_data['chat']
      # Listening Chanel
      @listening_chanels = json_decode(@chat_data[2])
      if(array_contains(@listening_chanels, 'local')) {
        @is_listening = true
      } else {
        @is_listening = false
      }
      # Receiver Setting
      @receivers[@receiver_uuid] = array(
        'name': @receiver_name,
        'channel': @chat_data[0],
        'is_near_player': true,
        'is_listening': @is_listening,
        'is_observer': @chat_data[3],
        'is_mentioned': false
      )
    } else {
      # Data
      @chat_data = cup_get('CHAT', @receiver_uuid)
      if(!is_null(@chat_data) && @chat_data[3]) {
        # Listening Chanel
        @listening_chanels = json_decode(@chat_data[2])
        if(array_contains(@listening_chanels, 'local')) {
          @is_listening = true
        } else {
          @is_listening = false
        }
        # Receiver Setting
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'channel': @chat_data[0],
          'is_near_player': false,
          'is_listening': @is_listening,
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
      'text': @sender_badge.' ',
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

proc _admin_chat(@data, @players_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_chat_data = @data['sender_chat_data']
  @sender_badge = @data['sender_badge']
  @unmodified_message = @data['message']
  #리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(ponline(@receiver_name)) {
      if(array_index_exists(@players_data, @receiver_uuid) && pisop(@receiver_name)) {
        # Data
        @receiver_data = @players_data[@receiver_uuid]
        @chat_data = @receiver_data['chat']
        # Listening Chanel
        @listening_chanels = json_decode(@chat_data[2])
        if(array_contains(@listening_chanels, 'admin')) {
          @is_listening = true
        } else {
          @is_listening = false
        }
        # Receiver Setting
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'is_online': true,
          'channel': @chat_data[0],
          'is_listening': @is_listening,
          'is_observer': @chat_data[3],
          'is_mentioned': false
        )
      }
    } else {
      # Data
      @chat_data = cup_get('CHAT', @receiver_uuid)
      if(!is_null(@chat_data) && bukkitlinked_is_player_op(@receiver_uuid)) {
        # Listening Chanel
        @listening_chanels = json_decode(@chat_data[2])
        if(array_contains(@listening_chanels, 'admin')) {
          @is_listening = true
        } else {
          @is_listening = false
        }
        # Receiver Setting
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'is_online': false,
          'channel': @chat_data[0],
          'is_listening': @is_listening,
          'is_observer': @chat_data[3],
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
      'text': @sender_badge.' ',
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
    @data['sender_chat_data'] = @players_data[@data['sender_uuid']]['chat']
    @data['sender_badge'] = @players_data[@data['sender_uuid']]['decoration'][0]
    if(@data['sender_chat_data'][1]) {
      @data['message'] = _en_to_ko(@event['message'])
    } else {
      @data['message'] = @event['message']
    }
    switch(@players_data[@data['sender_uuid']]['chat'][0]) {
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
        @players_data[@sender_uuid]['chat'][0] = 'default'
        cup_set('CHAT', @sender_uuid, @players_data[@sender_uuid]['chat'])
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

proc _broadcast(@sender_name, @sender_uuid, @unmodified_message, @setting) {
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
  @sender_chat_data = @data['sender_chat_data']
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