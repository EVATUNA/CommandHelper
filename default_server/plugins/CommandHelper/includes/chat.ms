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

# enko proc
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

# Channel ,EnKo Tag
proc _get_whisper_tag_name(@name, @text) {
  @chars = split('', @name)
  @res = res_create_resource('STRING_BUILDER')
  foreach(@char in @chars) {
    @unicode = unicode_from_char(@char)
    if(@unicode >= 48 && @unicode <= 57) { // 숫자
      string_append(@res, char_from_unicode(@unicode + 61254), @text['space_fonts']['space.-1'])
    } else if(@unicode >= 65 && @unicode <= 90) { // 대문자
      string_append(@res, char_from_unicode(@unicode + 61183), @text['space_fonts']['space.-1'])
    } else if(@unicode >= 97 && @unicode <= 122) { // 소문자
      string_append(@res, char_from_unicode(@unicode + 61177), @text['space_fonts']['space.-1'])
    } else if(@char == '_') { // 언더바
      string_append(@res, '\uef75', @text['space_fonts']['space.-1'])
    } else { // 그외
      string_append(@res, '\uef74', @text['space_fonts']['space.-1'])
    }
  }
  @replaced_name = string(@res)
  res_free_resource(@res)
  return(@replaced_name)
}

proc _update_channel_tag(@uuid, @player_data, @text) {
  @channel_tags = array(
    'default': '\ue400',
    'local': '\ue401',
    'town': '\ue402',
    'admin': '\ue403',
    'dummy': '\ue404'
  )
  @channel = @player_data['chat'][0]
  if(@channel == 'whisper') {
    if(@player_data['cache']['whisper_target'] == '') { //귓말 채널일시 채널 초기화
      @player_data['chat'][0] = 'default'
      @channel = @player_data['chat'][0]
      cup_set('CHAT', @uuid, @player_data['chat'])
    }
    @channel_tag = '\ue3fd'.@text['space_fonts']['space.-1']._get_whisper_tag_name(@player_data['cache']['whisper_target'], @text).'\ue3fe'
  }
  if(@channel != 'whisper') {
    @channel_tag = @channel_tags[@channel]
  }
  @enko = @player_data['chat'][1]
  if(@enko) {
    @enko_tag = '\ue3ff'
  } else {
    @enko_tag = ''
  }
  _set_sidebar(@uuid, 0, color('#fe0000').@text['space_fonts']['space.1'].@channel_tag.@text['space_fonts']['space.1'].@enko_tag, @text)
}

# 한영 치환 입력 활성 여부 변경
register_command('enko', array(
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      if(@players_data[@uuid]['chat'][1]) {
        @players_data[@uuid]['chat'][1] = false
        cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
      } else {
        @players_data[@uuid]['chat'][1] = true
        cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
      }
      _update_channel_tag(@uuid, @players_data[@uuid], @text)
    }
  }
))

# 채팅 채널 변경
register_command('channel', array(
  'aliases': array('ch', '채널'),
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 1) {
      @return = array('default', 'local')
      @uuid = puuid(@player)
      if(!is_null(tunalands_get_player_rank(@uuid))) {
        @return[] = 'town'
      }
      if(pisop(@player)) {
        @return[] = 'admin'
      }
    } else {
      @return = array()
    }
    return(@return)
  },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      if(array_size(@args) == 0) {
        switch(@players_data[@uuid]['chat'][0]) {
        case 'local':
          if(!is_null(tunalands_get_player_rank(@uuid))) {
            @players_data[@uuid]['chat'][0] = 'town'
          } else {
            if(pisop(@player)) {
              @players_data[@uuid]['chat'][0] = 'admin'
            } else {
              @players_data[@uuid]['chat'][0] = 'default'
            }
          }
          cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          break()
        case 'town':
          if(pisop(@player)) {
            @players_data[@uuid]['chat'][0] = 'admin'
          } else {
            @players_data[@uuid]['chat'][0] = 'default'
          }
          cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          break()
        case 'admin':
          @players_data[@uuid]['chat'][0] = 'default'
          cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          break()
        case 'default':
          @players_data[@uuid]['chat'][0] = 'local'
          cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          break()
        case 'whisper':
        default:
          @players_data[@uuid]['chat'][0] = 'default'
          cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          break()
        }
        _update_channel_tag(@uuid, @players_data[@uuid], @text)
      } else if(array_size(@args) == 1) {
        switch(@args[0]) {
        case 'local':
          @players_data[@uuid]['chat'][0] = 'local'
          cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          break()
        case 'town':
          if(!is_null(tunalands_get_player_rank(@uuid))) {
            @players_data[@uuid]['chat'][0] = 'town'
            cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          }
          break()
        case 'admin':
          if(pisop(@player)) {
            @players_data[@uuid]['chat'][0] = 'admin'
            cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          }
          break()
        default:
          @players_data[@uuid]['chat'][0] = 'default'
          cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          break()
        }
        _update_channel_tag(@uuid, @players_data[@uuid], @text)
      }
    }
  }
))

proc _get_name_raws(@is_sender_same, @is_type_messenger, @channel, @sender_name, @sender_badge, @color, @target) {
  switch(@channel) {
  case 'Default':
  case 'Town':
  case 'Local':
  case 'Admin':
    if(@is_type_messenger) {
      if(@is_sender_same) {
        @name_raws = array(
          array(
            'text': ' > ',
            'color': @color
          )
        )
      } else {
        @name_raws = array(
          array(
            'text': '',
            'color': @color
          ),
          array(
            'text': @sender_badge.' ',
            'color': '#ffffff'
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
            'text': '\n > ',
          )
        )
      }
    } else {
      @name_raws = array(
        array(
          'text': '',
          'color': @color
        ),
        array(
          'text': @sender_badge.' ',
          'color': '#ffffff'
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
    }
    break()
  case 'Whisper':
    if(!@is_type_messenger) {
      if(@is_sender_same) {
        @name_raws = array(
          array(
            'text': ' > ',
            'color': @color
          )
        )
      } else {
        switch(@sender_badge) {
        case 'sender':
          @name_raws = array(
            array(
              'text': '',
              'color': @color
            ),
            array(
              'text': 'To '
            ),
            array(
              'text': @target,
              'insertion': '@'.@target'',
              'hoverEvent': array(
                'action': 'show_text',
                'value': array(
                  '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
                  '좌클릭 시, 유저에게 귓속말을 보냅니다',
                )
              ),
              'clickEvent': array(
                'action': 'suggest_command',
                'value': '/w'@target''
              )
            ),
            array(
              'text': '\n > ',
            )
          )
          break()
        case 'target':
          @name_raws = array(
            array(
              'text': '',
              'color': @color
            ),
            array(
              'text': 'From '
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
              'text': '\n > ',
            )
          )
          break()
        case 'other':
          @name_raws = array(
            array(
              'text': '',
              'color': @color
            ),
            array(
              'text': 'From '
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
              'text': ' To '
            ),
            array(
              'text': @target,
              'insertion': '@'.@target'',
              'hoverEvent': array(
                'action': 'show_text',
                'value': array(
                  '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
                  '좌클릭 시, 유저에게 귓속말을 보냅니다',
                )
              ),
              'clickEvent': array(
                'action': 'suggest_command',
                'value': '/w'@target''
              )
            ),
            array(
              'text': '\n > ',
            )
          )
          break()
        }
      }
    } else {
      switch(@sender_badge) {
      case 'sender':
        @name_raws = array(
          array(
            'text': '',
            'color': @color
          ),
          array(
            'text': 'To '
          ),
          array(
            'text': @target,
            'insertion': '@'.@target'',
            'hoverEvent': array(
              'action': 'show_text',
              'value': array(
                '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
                '좌클릭 시, 유저에게 귓속말을 보냅니다',
              )
            ),
            'clickEvent': array(
              'action': 'suggest_command',
              'value': '/w'@target''
            )
          ),
          array(
            'text': ' :: ',
          )
        )
        break()
      case 'target':
        @name_raws = array(
          array(
            'text': '',
            'color': @color
          ),
          array(
            'text': 'From '
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
        break()
      case 'other':
        @name_raws = array(
          array(
            'text': '',
            'color': @color
          ),
          array(
            'text': 'From '
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
            'text': ' To '
          ),
          array(
            'text': @target,
            'insertion': '@'.@target'',
            'hoverEvent': array(
              'action': 'show_text',
              'value': array(
                '쉬프트 좌클릭 시, 커서에 유저 호출 메시지가 입력됩니다.\n',
                '좌클릭 시, 유저에게 귓속말을 보냅니다',
              )
            ),
            'clickEvent': array(
              'action': 'suggest_command',
              'value': '/w'@target''
            )
          ),
          array(
            'text': ' :: ',
          )
        )
        break()
      }
    }
    break()
  }
  return(@name_raws)
}

proc _get_message_raws(@channel, @message, @receivers, @town_members) {
  @mentioned_messages = array()
  @message_raws = array(
    array('text': '')
  )
  switch(@channel) {
  case 'Default':
    foreach(@key: @string in parse_args(@message)) {
      @is_message_modified = false
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
                  @is_message_modified = true
                  @message_raw = array(
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
              @is_message_modified = true
              @message_raw = array(
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
                @is_message_modified = true
                @message_raw = array(
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
                    @message_raw['hoverEvent']['value'][] = '\n'.@receiver_data['name']
                  }
                }
                @op_list_message = @message_raw
              } else {
                @is_message_modified = true
                @message_raw = @op_list_message
                @message_raw['text'] = @string
              }
            }
          }
        }
      } else if(string_starts_with(@string, './')) {
        @string = replace(@string, './', '/')
        @string = replace(@string, '_', ' ')
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'yellow',
          'clickEvent': array(
            'action': 'suggest_command',
            'value': @string
          )
        )
      } else if(string_starts_with(@string, 'https://') || string_starts_with(@string, 'http://')) {
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'blue',
          'clickEvent': array(
            'action': 'open_url',
            'value': @string
          )
        )
      }
      if(@is_message_modified) {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) != 1) {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '
          }
        }
        @message_raws[] = @message_raw
      } else {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) == 1) {
          @message_raws[] = array(
            'text': @string
          )
        } else {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '.@string
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '.@string
          }
        }
      }
    }
    break()
  case 'Town':
    foreach(@key: @string in parse_args(@message)) {
      @is_message_modified = false
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
                  @is_message_modified = true
                  @message_raw = array(
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
              @is_message_modified = true
              @message_raw = array(
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
                @is_message_modified = true
                @message_raw = array(
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
                    @message_raw['hoverEvent']['value'][] = '\n'.@receiver_data['name']
                  }
                }
                @member_list_message = @message_raw
              } else {
                @is_message_modified = true
                @message_raw = @member_list_message
              }
              break()
            case '주민':
              if(!array_contains(@mentioned_messages, '주민')) {
                @mentioned_messages[] = '주민'
                @is_message_modified = true
                @message_raw = array(
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
                    @message_raw['hoverEvent']['value'][] = '\n'.@receiver_data['name']
                  }
                }
                @member_list_message = @message_raw
              } else {
                @is_message_modified = true
                @message_raw = @member_list_message
              }
              break()
            case '부이장':
              if(!array_contains(@mentioned_messages, '부이장')) {
                @mentioned_messages[] = '부이장'
                @is_message_modified = true
                @message_raw = array(
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
                    @message_raw['hoverEvent']['value'][] = '\n'.@receiver_data['name']
                  }
                }
                @staff_list_message = @message_raw
              } else {
                @is_message_modified = true
                @message_raw = @staff_list_message
              }
              break()
            case '이장':
              if(!array_contains(@mentioned_messages, '이장')) {
                @mentioned_messages[] = '이장'
                @is_message_modified = true
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
                  @message_raw = array(
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
                  @message_raw = array(
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
                @member_list_message = @message_raw
              } else {
                @is_message_modified = true
                @message_raw = @member_list_message
              }
              break()
            }
          }
        }
      } else if(string_starts_with(@string, './')) {
        @string = replace(@string, './', '/')
        @string = replace(@string, '_', ' ')
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'yellow',
          'clickEvent': array(
            'action': 'suggest_command',
            'value': @string
          )
        )
      } else if(string_starts_with(@string, 'https://') || string_starts_with(@string, 'http://')) {
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'blue',
          'clickEvent': array(
            'action': 'open_url',
            'value': @string
          )
        )
      }
      if(@is_message_modified) {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) != 1) {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '
          }
        }
        @message_raws[] = @message_raw
      } else {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) == 1) {
          @message_raws[] = array(
            'text': @string
          )
        } else {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '.@string
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '.@string
          }
        }
      }
    }
    break()
  case 'Local':
    foreach(@key: @string in parse_args(@message)) {
      @is_message_modified = false
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
                  @is_message_modified = true
                  @message_raw = array(
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
              @is_message_modified = true
              @message_raw = array(
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
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'yellow',
          'clickEvent': array(
            'action': 'suggest_command',
            'value': @string
          )
        )
      } else if(string_starts_with(@string, 'https://') || string_starts_with(@string, 'http://')) {
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'blue',
          'clickEvent': array(
            'action': 'open_url',
            'value': @string
          )
        )
      }
      if(@is_message_modified) {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) != 1) {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '
          }
        }
        @message_raws[] = @message_raw
      } else {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) == 1) {
          @message_raws[] = array(
            'text': @string
          )
        } else {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '.@string
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '.@string
          }
        }
      }
    }
    break()
  case 'Admin':
    foreach(@key: @string in parse_args(@message)) {
      @is_message_modified = false
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
                  @is_message_modified = true
                  @message_raw = array(
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
              @is_message_modified = true
              @message_raw = array(
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
                @is_message_modified = true
                @message_raw = array(
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
                  @message_raw['hoverEvent']['value'][] = '\n'.@receiver_data['name']
                }
                @op_list_message = @message_raw
              } else {
                @is_message_modified = true
                @message_raw = @op_list_message
                @message_raw['text'] = @string
              }
            }
          }
        }
      } else if(string_starts_with(@string, './')) {
        @string = replace(@string, './', '/')
        @string = replace(@string, '_', ' ')
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'yellow',
          'clickEvent': array(
            'action': 'suggest_command',
            'value': @string
          )
        )
      } else if(string_starts_with(@string, 'https://') || string_starts_with(@string, 'http://')) {
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'blue',
          'clickEvent': array(
            'action': 'open_url',
            'value': @string
          )
        )
      }
      if(@is_message_modified) {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) != 1) {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '
          }
        }
        @message_raws[] = @message_raw
      } else {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) == 1) {
          @message_raws[] = array(
            'text': @string
          )
        } else {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '.@string
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '.@string
          }
        }
      }
    }
    break()
  case 'Whisper':
    foreach(@key: @string in parse_args(@message)) {
      @is_message_modified = false
      if(string_starts_with(@string, './')) {
        @string = replace(@string, './', '/')
        @string = replace(@string, '_', ' ')
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'yellow',
          'clickEvent': array(
            'action': 'suggest_command',
            'value': @string
          )
        )
      } else if(string_starts_with(@string, 'https://') || string_starts_with(@string, 'http://')) {
        @is_message_modified = true
        @message_raw = array(
          'text': @string,
          'color': 'blue',
          'clickEvent': array(
            'action': 'open_url',
            'value': @string
          )
        )
      }
      if(@is_message_modified) {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) != 1) {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '
          }
        }
        @message_raws[] = @message_raw
      } else {
        @pre_message_raw = @message_raws[-1]
        if(array_size(@message_raws) == 1) {
          @message_raws[] = array(
            'text': @string
          )
        } else {
          if(array_index_exists(@pre_message_raw, 'color')) {
            @message_raws[] = array(
              'text': ' '.@string
            )
          } else {
            @message_raws[-1]['text'] = @pre_message_raw['text'].' '.@string
          }
        }
      }
    }
    break()
  }
  return(@message_raws)
}

# Default Chat
proc _default_chat(@data, @players_data) {
  # 변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_server = @data['sender_server']
  @sender_badge = @data['sender_badge']
  @sender_chat_data = @data['sender_chat_data']
  @message = @data['message']
  @channel = 'Default'
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
  # 메시지 부분 raw (해당 함수에서 @receivers를 수정할 수 있음)
  @message_raws = _get_message_raws(@channel, @message, @receivers)
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    if(@receiver_data['is_online']) {
      if(@receiver_data['channel'] == 'default' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        # 이름 부분 raw
        @is_sender_same = @players_data[@receiver_uuid]['cache']['last_sender'] == "default.@sender_name"
        @is_type_messenger = @players_data[@receiver_uuid]['chat'][6]
        @name_raws = _get_name_raws(@is_sender_same, @is_type_messenger, @channel, @sender_name, @sender_badge, '#ffffff')
        # 메시지 보내기
        _tellraw(@receiver_name, array_merge(@name_raws, @message_raws))
        # ls 세팅
        @players_data[@receiver_uuid]['cache']['last_sender'] = "default.@sender_name"
        # 사운드
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
  # 로깅
  mom_log('INFO', "[@channel] @sender_name(@sender_server): @message")
}

proc _town_chat(@data, @players_data) {
  # 변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_server = @data['sender_server']
  @sender_badge = @data['sender_badge']
  @sender_chat_data = @data['sender_chat_data']
  @message = @data['message']
  @channel = 'Town'
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
  # 메시지 부분 raw (해당 함수에서 @receivers를 수정할 수 있음)
  @message_raws = _get_message_raws(@channel, @message, @receivers, @town_members)
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    if(@receiver_data['is_online']) {
      if(@receiver_data['channel'] == 'town' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        # 이름 부분 raw
        @is_sender_same = @players_data[@receiver_uuid]['cache']['last_sender'] == "town.@sender_name"
        @is_type_messenger = @players_data[@receiver_uuid]['chat'][6]
        @name_raws = _get_name_raws(@is_sender_same, @is_type_messenger, @channel, @sender_name, @sender_badge, '#c3f2a2')
        # 메시지 보내기
        _tellraw(@receiver_name, array_merge(@name_raws, @message_raws))
        # ls 세팅
        @players_data[@receiver_uuid]['cache']['last_sender'] = "town.@sender_name"
        # 사운드
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
  # 로깅
  mom_log('INFO', "[@channel] @sender_name(@sender_server): @message")
}

proc _local_chat(@data, @players_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_server = @data['sender_server']
  @sender_badge = @data['sender_badge']
  @sender_chat_data = @data['sender_chat_data']
  @message = @data['message']
  @channel = 'Local'
  @near_players = @data['near_players']
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
    } else { // 오프라인이나 근처 플레이어 아닐시
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
  # 메시지 부분 raw (해당 함수에서 @receivers를 수정할 수 있음)
  @message_raws = _get_message_raws(@channel, @message, @receivers)
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    if(ponline(@receiver_data['name']) && array_index_exists(@players_data, @receiver_uuid)) {
      if(@receiver_data['channel'] == 'local' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        # 이름 부분 raw
        @is_sender_same = @players_data[@receiver_uuid]['cache']['last_sender'] == "local.@sender_name"
        @is_type_messenger = @players_data[@receiver_uuid]['chat'][6]
        @name_raws = _get_name_raws(@is_sender_same, @is_type_messenger, @channel, @sender_name, @sender_badge, '#f7f9c4')
        # 메시지 보내기
        _tellraw(@receiver_name, array_merge(@name_raws, @message_raws))
        # ls 세팅
        @players_data[@receiver_uuid]['cache']['last_sender'] = "local.@sender_name"
        # 사운드
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
  # 로깅
  mom_log('INFO', "[@channel] @sender_name(@sender_server): @message")
}

proc _admin_chat(@data, @players_data) {
  #변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_server = @data['sender_server']
  @sender_badge = @data['sender_badge']
  @sender_chat_data = @data['sender_chat_data']
  @message = @data['message']
  @channel = 'Admin'
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
  # 메시지 부분 raw (해당 함수에서 @receivers를 수정할 수 있음)
  @message_raws = _get_message_raws(@channel, @message, @receivers)
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    if(@receiver_data['is_online']) {
      if(@receiver_data['channel'] == 'admin' || @receiver_data['is_listening'] || @receiver_data['is_observer'] || @receiver_data['is_mentioned']) {
        @receiver_name = @receiver_data['name']
        # 이름 부분 raw
        @is_sender_same = @players_data[@receiver_uuid]['cache']['last_sender'] == "admin.@sender_name"
        @is_type_messenger = @players_data[@receiver_uuid]['chat'][6]
        @name_raws = _get_name_raws(@is_sender_same, @is_type_messenger, @channel, @sender_name, @sender_badge, '#fbc8c8')
        # 메시지 보내기
        _tellraw(@receiver_name, array_merge(@name_raws, @message_raws))
        # ls 세팅
        @players_data[@receiver_uuid]['cache']['last_sender'] = "admin.@sender_name"
        # 사운드
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
  # 로깅
  mom_log('INFO', "[@channel] @sender_name(@sender_server): @message")
}

proc _whisper_chat(@data, @players_data, @server) {
  # 변수 선언
  @sender_name = @data['sender_name']
  @sender_uuid = @data['sender_uuid']
  @sender_server = @data['sender_server']
  @sender_badge = @data['sender_badge']
  @sender_chat_data = @data['sender_chat_data']
  @message = @data['message']
  @channel = 'Whisper'
  @target_name = @data['target_name']
  @target_uuid = @data['target_uuid']
  @target_server = 'other'
  # 리시버 설정
  @receivers = array()
  foreach(@receiver_uuid in bukkitlinked_get_all_players()) {
    @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
    if(@sender_name == @receiver_name) {
      # Data
      if(ponline(@receiver_name) && array_index_exists(@players_data, @receiver_uuid)) {
        @receiver_data = @players_data[@receiver_uuid]
        @chat_data = @receiver_data['chat']
      } else {
        @chat_data = cup_get('CHAT', @receiver_uuid)
      }
      # Receiver Setting
      @receivers[@receiver_uuid] = array(
        'name': @receiver_name,
        'is_online': true,
        'channel': @chat_data[0],
        'type': 'sender',
        'is_observer': @chat_data[3],
        'is_mentioned': false
      )
    } else if(@target_name == @receiver_name) {
      # Data
      if(ponline(@receiver_name) && array_index_exists(@players_data, @receiver_uuid)) {
        @receiver_data = @players_data[@receiver_uuid]
        @chat_data = @receiver_data['chat']
        @target_server = @server
      } else {
        @chat_data = cup_get('CHAT', @receiver_uuid)
      }
      # Receiver Setting
      @receivers[@receiver_uuid] = array(
        'name': @receiver_name,
        'is_online': false,
        'channel': @chat_data[0],
        'type': 'target',
        'is_observer': @chat_data[3],
        'is_mentioned': false
      )
    } else { // 오프라인이거나 타켓 플레이어 아닐시
      # Data
      if(ponline(@receiver_name) && array_index_exists(@players_data, @receiver_uuid)) {
        @receiver_data = @players_data[@receiver_uuid]
        @chat_data = @receiver_data['chat']
      } else {
        @chat_data = cup_get('CHAT', @receiver_uuid)
      }
      if(!is_null(@chat_data) && @chat_data[3]) {
        # Receiver Setting
        @receivers[@receiver_uuid] = array(
          'name': @receiver_name,
          'channel': @chat_data[0],
          'type': 'other',
          'is_observer': true,
          'is_mentioned': false
        )
      }
    }
  }
  # 메시지 부분 raw (해당 함수에서 @receivers를 수정할 수 있음)
  @message_raws = _get_message_raws(@channel, @message, @receivers)
  # 메시지 보내기
  foreach(@receiver_uuid: @receiver_data in @receivers) {
    @receiver_name = @receiver_data['name']
    if(@receiver_data['is_online']) {
      @is_sender_same = @players_data[@receiver_uuid]['cache']['last_sender'] == "whisper.@sender_name.to.@target_name"
      @is_type_messenger = @players_data[@receiver_uuid]['chat'][6]
      switch(@receiver_data['type']) {
      case 'sender':
        # 이름 부분 raw
        @name_raws = _get_name_raws(@is_sender_same, @is_type_messenger, @channel, @sender_name, 'sender', '#fbc8f5', @target_name)
        # 사운드
        play_named_sound(ploc(@sender_name), array('sound': 'message.out', 'category': 'master', 'volum': 100), array(@sender_name))
        break()
      case 'target':
        # 이름 부분 raw
        @name_raws = _get_name_raws(@is_sender_same, @is_type_messenger, @channel, @sender_name, 'target', '#fbc8f5', @target_name)
        # 사운드
        play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
        # lws 세팅
        @players_data[@receiver_uuid]['cache']['last_whisper_sender'] = @sender_name
        break()
      case 'other':
        # 이름 부분 raw
        @name_raws = _get_name_raws(@is_sender_same, @is_type_messenger, @channel, @sender_name, 'other', '#fbc8f5', @target_name)
        # 사운드
        play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
        break()
      }
      # 메시지 보내기
      _tellraw(@receiver_name, array_merge(@name_raws, @message_raws))
      # ls 세팅
      @players_data[@receiver_uuid]['cache']['last_sender'] = "whisper.@sender_name.to.@target_name"
    }
  }
  # 로깅
  mom_log('INFO', "[@channel] @sender_name(@sender_server) → @target_name(@target_server) @message")
}

bind('async_player_chat', null , null, @event, @players_data, @text, @server) {
  cancel()
  @sender_name = @event['player']
  @sender_uuid = puuid(@sender_name)
  if(array_index_exists(@players_data, @sender_uuid)) {
    # 플레이어 데이터
    @player_data = @players_data[@sender_uuid]
    # 카프카 데이터 세팅
    @data = array(
      'sender_name': @sender_name,
      'sender_uuid': @sender_uuid,
      'sender_server': @server,
      'sender_chat_data': @player_data['chat'],
      'sender_badge': @player_data['decoration'][0]
    )
    # enko여부에 따라 채팅 내용 수정
    if(@data['sender_chat_data'][1]) {
      @message = _en_to_ko(@event['message'])
    } else {
      @message = @event['message']
    }
    @data['message'] = @message
    # 카프카 보내기 (마을 채팅 입력시 마을 없으면 기본으로, 귓말 보낼시 타겟 없으면 기본으로, 이상한 채널이면 기본 채널로 설정)
    switch(@player_data['chat'][0]) {
    case 'default':
    case 'admin':
      kafka_send('ch.send_chat', json_encode(@data))
      break()
    case 'local':
      @data['near_players'] = players_in_radius(ploc(@data['sender_name']), 64)
      kafka_send('ch.send_chat', json_encode(@data))
      break()
    case 'town':
      @town_members = tunalands_get_player_lands_member_list(@sender_uuid)
      if(!is_null(@town_members)) {
        @data['town_members'] = @town_members
        kafka_send('ch.send_chat', json_encode(@data))
      } else {
        @player_data['chat'][0] = 'default'
        cup_set('CHAT', @sender_uuid, @player_data['chat'])
        tmsg(@sender_name, @text['prefix']['warn'] '§7가입된 마을을 찾을 수 없어 일반 채널로 이동됩니다.')
        _update_channel_tag(@sender_uuid, @player_data, @text)
      }
      break()
    case 'whisper':
      @target_name = @player_data['cache']['whisper_target']
      @target_uuid = bukkitlinked_get_player_uuid(@target_name)
      if(array_contains(bukkitlinked_get_all_players(), @target_uuid)) {
        @data['target_name'] = @target_name
        @data['target_uuid'] = @target_uuid
        kafka_send('ch.send_chat', json_encode(@data))
      } else {
        @player_data['chat'][0] = 'default'
        cup_set('CHAT', @sender_uuid, @player_data['chat'])
        tmsg(@sender_name, @text['prefix']['warn'] '§7해당 플레이어를 찾을 수 없어 일반 채널로 이동됩니다.')
        _update_channel_tag(@sender_uuid, @player_data, @text)
      }
      break()
    default:
      @player_data['chat'][0] = 'default'
      cup_set('CHAT', @sender_uuid, @player_data['chat'])
      tmsg(@sender_name, @text['prefix']['warn'] '§7알 수 없는 채널에서 채팅을 입력하여 일반 채널로 이동됩니다.')
      _update_channel_tag(@sender_uuid, @player_data, @text)
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

register_command('broadcast', array(
  'description': 'can broadcast',
  'usage': '/broadcast <msg>',
  'aliases': array('say'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(ponline(@player)) {
      if(pisop(@player)) {
        @sender_name = @player
        @sender_uuid = puuid(@sender_name)
        if(array_index_exists(@players_data, @sender_uuid) && array_size(@args) > 0) {
          @imploded_message = array_implode(array_get(@args, cslice(0, array_size(@args) - 1)), ' ')
          @setting = @players_data[@sender_uuid]['setting']
          _broadcast(@sender_name, @sender_uuid, @imploded_message, @setting)
        } else {
          tmsg(@player, color('yellow')'/'.@command'<message>')
        }
      } else {
        return(false)
      }
    } else {
      @sender_name = 'console'
      @sender_uuid = 'console'
      if(array_size(@args) > 0) {
        @imploded_message = array_implode(array_get(@args, cslice(0, array_size(@args) - 1)), ' ')
        @setting = array('broadcast', false)
        _broadcast(@sender_name, @sender_uuid, @imploded_message, @setting)
      } else {
        console(color('yellow')'/'.@command'<message>')
      }
    }
  }
))

register_command('whisper', array(
  'aliases': array('w', 'm', 'msg', 'tell', '귓속말', '귓'),
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 1) {
      @online_players = array()
      foreach(@target_uuid in bukkitlinked_get_all_players()) {
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
      switch(array_size(@args)) {
      case 0:
        tmsg(@player, '\ue4dd'color('yellow').'/'.@command'<플레이어> <할 말>'.color('gray').'을 통해 귓속말을 보낼 수 있습니다.\n 또는,'color('yellow').'/'.@command'<플레이어>'.color('gray').'를 통해 귓속말을 채팅으로 보낼 수 있습니다.')
        break();
      case 1:
        @online_players = array()
        foreach(@target_uuid in bukkitlinked_get_all_players()) {
          @online_players[] = bukkitlinked_get_player_name(@target_uuid)
        }
        array_remove_values(@online_players, @player) // 본인 제외
        if(array_contains(@online_players, @args[0])) {
          @player_data = @players_data[@sender_uuid]
          @player_data['cache']['whisper_target'] = @args[0]
          @player_data['chat'][0] = 'whisper'
          cup_set('CHAT', @sender_uuid, @player_data['chat'])
          _update_channel_tag(@sender_uuid, @players_data[@sender_uuid], @text)
          tmsg(@player, @text['prefix']['info'] color('gray').'채팅 채널이 귓속말로 전환되었습니다.')
        } else {
          tmsg(@player, @text['prefix']['failure'] color('gray').'플레이어를 찾을 수 없습니다.')
        }
        break();
      default:
        @is_target_exists = false
        @all_players_uuid = bukkitlinked_get_all_players()
        array_remove_values(@all_players_uuid, @sender_uuid)
        foreach(@target_uuid in @all_players_uuid) {
          @target_name = bukkitlinked_get_player_name(@target_uuid)
          if(@target_name == @args[0]) {
            @is_target_exists = true
            break()
          }
        }
        if(@is_target_exists) {
          # 카프카 데이터 세팅
          @data = array(
            'sender_name': @sender_name,
            'sender_uuid': @sender_uuid,
            'sender_server': @server,
            'sender_chat_data': @players_data[@sender_uuid]['chat'],
            'sender_badge': @players_data[@sender_uuid]['decoration'][0],
            'target_name': @target_name,
            'target_uuid': @target_uuid,
          )
          if(@data['sender_chat_data'][1]) {
            @message = _en_to_ko(array_implode(array_get(@args, cslice(1, array_size(@args) - 1)), ' '))
          } else {
            @message = array_implode(array_get(@args, cslice(1, array_size(@args) - 1)), ' ')
          }
          @data['message'] = @message
          @channel = @data['sender_chat_data'][0]
          @data['sender_chat_data'][0] = 'whisper'
          # 카프카 보내기
          kafka_send('ch.send_chat', json_encode(@data))
          @data['sender_chat_data'][0] = @channel
        } else {
          tmsg(@player, @text['prefix']['failure'] color('gray').'플레이어를 찾을 수 없습니다.')
        }
      }
    }
  }
))

register_command('reply', array(
  'aliases': array('r', '답장'),
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 1) {
      @online_players = array()
      foreach(@target_uuid in bukkitlinked_get_all_players()) {
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
      //tmsg(@player, '\ue4dd'color('yellow').'/'.@command'<할 말>'.color('gray').'을 통해 답장을 보낼 수 있습니다.\n 또는,'color('yellow').'/'.@command.color('gray').'를 통해 답장을 채팅으로 보낼 수 있습니다.')
      @online_players = array()
      foreach(@target_uuid in bukkitlinked_get_all_players()) {
        @online_players[] = bukkitlinked_get_player_name(@target_uuid)
      }
      @player_data = @players_data[@sender_uuid]
      @last_whisper_sender = @player_data['cache']['last_whisper_sender']
      if(array_size(@args) == 0) {
        if(@last_whisper_sender != '' && array_contains(@online_players, @last_whisper_sender)) {
          @player_data['cache']['whisper_target'] = @last_whisper_sender
          @player_data['chat'][0] = 'whisper'
          cup_set('CHAT', @sender_uuid, @player_data['chat'])
          _update_channel_tag(@sender_uuid, @players_data[@sender_uuid], @text)
          tmsg(@player, @text['prefix']['info'] color('gray').'채팅 채널이 귓속말로 전환되었습니다.')
        } else {
          tmsg(@player, @text['prefix']['failure'] color('gray').'답장할 플레이어를 찾을 수 없습니다.')
        }
      } else {
        if(@last_whisper_sender != '' && array_contains(@online_players, @last_whisper_sender)) {
          @target_name = @last_whisper_sender
          @target_uuid = bukkitlinked_get_player_uuid(@target_name)
          # 카프카 데이터 세팅
          @data = array(
            'sender_name': @sender_name,
            'sender_uuid': @sender_uuid,
            'sender_server': @server,
            'sender_chat_data': @player_data['chat'],
            'sender_badge': @player_data['decoration'][0],
            'target_name': @target_name,
            'target_uuid': @target_uuid,
          )
          if(@data['sender_chat_data'][1]) {
            @message = _en_to_ko(array_implode(@args, ' '))
          } else {
            @message = array_implode(@args, ' ')
          }
          @data['message'] = @message
          @channel = @data['sender_chat_data'][0]
          @data['sender_chat_data'][0] = 'whisper'
          # 카프카 보내기
          kafka_send('ch.send_chat', json_encode(@data))
          @data['sender_chat_data'][0] = @channel
        } else {
          tmsg(@player, @text['prefix']['failure'] color('gray').'답장할 플레이어를 찾을 수 없습니다.')
        }
      }
    }
  }
))