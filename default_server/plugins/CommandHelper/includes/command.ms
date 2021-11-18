# 리소스팩 링크 업데이트
register_command('resourceurl', array(
  'description': 'You can set resourcepack download url.',
  'permission': '*',
  'usage': '/resourceurl <url>',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(pisop(@player)) {
      if(array_size(@args) == 1) {
        store_value('resourcepack', @args[0])
        @resourcepack['url'] = @args[0]
        kafka_send('ch_resourcepack_url_update', @args[0])
        return(true)
      } else {
        return(false)
      }
    } else {
      return(false)
    }
  }
))

# 프로시저
proc _is_command_registered(@command) {
  return(array_index_exists(get_commands(), @command))
}

# 프리셋 명령어( help 등 )
set_timeout(1000, closure() {
  ###
  ### 서버 정보 명령어
  ###
  proc _info_command(@command, @player, @args, @text) {
    @raw = array(
      array(
        'text': '                              \ue008\n\n\n\n\n\n'
      ),
      array(
        'text': '     환영합니다! 에바참치는 색다른 경험을 제공해주는 성장형 야생 서버입니다.\n\n',
        'color': '#80c8ff'
      ),
      array(
        'text': '      기존의 마인크래프트 야생과 차별화되는 컨텐츠와 시스템들이 많으므로,\n'
      ),
      array(
        'text': '              지침서에서 제공되는 팁들을 꼭 확인하시길 바랍니다!'
      )
    )
    _tellraw(@player, @raw)

    #msg(@text['prefix']['info'].' §b서버 정보')
    #msg(' §7서버명: §f에바참치 §7(§fEvatuna§7)')
    #msg(' §7서버 장르: 야생')
    #msg(' §7총 관리자: 앨리스(§btele§f: @alicearcade, §7dis§f: AA_2#1787)')
    #msg(' §7공식 이메일: support@evatuna.fish')
    #msg(' §7공식 홈페이지 : §7/site')
    #msg(' §7공식 카페 : §a(네이버)§7/cafe')
    #msg(' §7공식 디스코드: §7/discord')
    #msg(' §7마인리스트: §7/vote')
    #msg(' §7서버오픈일: 2021년 06월 03일')
  }
  if(_is_command_registered('info')) { unregister_command('info') }
  #if(_is_command_registered('version')) { unregister_command('version') }
  register_command('info', array(
    'aliases': array('about', 'version', 'ver', '서버', '서버정보'),
    'tabcompleter': closure(@command, @player, @args) {
      return(array())
    },
    'executor': closure(@command, @player, @args) {
      _info_command(@command, @player, @args, @text)
    }
  ))

  register_command('cafe', array(
    'executor': closure(@cmd, @sender, @cArgs){
      msg(@text['prefix']['info']'§aNaverCafe §r : https://cafe.evatuna.fish')
    }
  ))
  register_command('discord', array(
    'executor': closure(@cmd, @sender, @cArgs){
      msg(@text['prefix']['info']'§7Discord §r : https://discord.evatuna.fish/')
    }
  ))
  register_command('site', array(
    'executor': closure(@cmd, @sender, @cArgs){
      msg(@text['prefix']['info']'§9EvatunaOffical §r : https://evatuna.fish/')
    }
  ))
  ###
  ### 도움말 명령어
  ###
  if(_is_command_registered('help')) { unregister_command('help') }
  proc _help_message(@player, @real_command, @sub_commands, @args, @description) {
    if(is_null(@args)) {
      @command_text = '/'.@real_command,
    } else {
      @command_text = '/'.@real_command.' '.@args,
    }
    @raw = array(
      array(
        'text': ' ',
        'color': 'gray'
      ),
      array(
        'text': @command_text,
        'color': 'yellow',
        'clickEvent': array(
          'action': 'suggest_command',
          'value': '/'.@real_command.' '
        )
      ),
      array(
        'text': ' - '.@description
      )
    )
    if(is_array(@sub_commands) && array_size(@sub_commands) > 0) {
      @hover = array(
        array(
          'text': '대안 명령어:'
        )
      )
      foreach(@sub_command in @sub_commands) {
        @hover[] = array(
          'text': '\n/'.@sub_command,
          'color': 'yellow'
        )
      }
      @raw[1]['hoverEvent'] = array(
        'action': 'show_text',
        'value': @hover
      )
    }
    _tellraw(@player, @raw)
  }
  proc _help_commnad(@command, @player, @args, @text) {
    # 페이지 구하기
    switch(array_size(@args)) {
    case 0:
      @page = 1
      break()
    case 1:
      if(is_integral(@args[0])) {
        @page = integer(@args[0])
      } else {
        @page = null
      }
      break()
    default:
      @page = null
      break()
    }
    # 페이지에 따른 메시지
    @max_page = 4
    if(!is_null(@page)) {
      msg(@text['prefix']['info'].' §b/'.@command.' ['.@page.'/'.@max_page.'] §7< > = 필수 인자, [ ] = 선택 인자')
      msg('§e 명령어 좌클릭 시, 채팅창에 명령어가 입력됩니다.')
      switch(@page) {
      case 1:
        msg(' §b# 도움말')
        _help_message(@player, 'help', array('command', 'commands', 'cmd', 'cmds', '도움말', '명령어', '헬프', '커맨드'), '[페이지]', '서버 명령어를 확인합니다.')
        _help_message(@player, 'info', array('about', 'version', 'ver', '서버', '서버정보'), null, '서버 정보를 확인합니다.')
        #_help_message(@player, 'guide', array('newbie', '가이드', '뉴비'), null, '뉴비 가이드를 봅니다.')
        msg(' §b# 채팅')
        _help_message(@player, 'whisper', array('w', 'm', 'msg', 'tell', '귓속말', '귓'), '<닉네임> <할 말>', '플레이어에게 귓속말을 보냅니다.')
        _help_message(@player, 'channel', array('ch', '채널'), '[채널]', '채팅 채널을 변경합니다.')
        _help_message(@player, 'enko', array(), null, '한영 치환 입력을 활성/비활성합니다.')
        break()
      case 2:
        msg(' §b# 유틸')
        _help_message(@player, 'util', array('gui', '유틸'), null, '유틸 GUI를 엽니다.')
        msg(' §b# 텔레포트')
        _help_message(@player, 'spawn', array(), null, '스폰으로 이동합니다.')
        _help_message(@player, 'home', array(), null, '홈으로 이동합니다.')
        _help_message(@player, 'warp', array('워프'), null, '워프 GUI를 엽니다.')
        _help_message(@player, 'randomteleport', array('rt', '랜덤텔포', '랜덤티피',), null, '랜덤 텔레포트 GUI를 엽니다.')
        break()
      case 3:
        msg(' §b# 스킬')
        _help_message(@player, 'skillbook', array('skill', 'abilitybook', 'ability', 'masterybook', 'mastery', '스킬북', '스킬', '어빌리티북', '어빌리티', '마스터리북', '마스터리'), null, '스킬북을 엽니다.')
        msg(' §b# 설정')
        _help_message(@player, 'setting', array('설정'), null, '설정 GUI를 엽니다.')
        _help_message(@player, 'screen', array('graphics', '화면설정'), null, '화면 설정 GUI를 엽니다.')
        _help_message(@player, 'hud', array(), '<너비>', 'HUD 표시 너비를 조정합니다.')
        msg(' §b# 로그 조사')
        _help_message(@player, 'co i', array(), null, '로그조사 (토글)')
        break()
      case 4:
        msg(' §b# 돈')
        _help_message(@player, 'money', array(), null, '현재 소지한 돈을 확인합니다.')
        _help_message(@player, 'pay', array(), '<닉네임> <수량>', '플레이어에게 돈을 송금합니다.')
        msg(' §b# 튜나랜드')
        _help_message(@player, 'tunaland', array('tl'), null, '거주 월드 청크 관리 명령어입니다.')
        msg(' §b# 길드')
        _help_message(@player, 'guild', array(), null, '길드 관리 명령어입니다.')
        #_help_message(@player, '', array(), null, '')
        break()
      default:
        msg(' §7해당 페이지의 도움말이 존재하지 않습니다.')
        break()
      }
    } else {
      msg(@text['prefix']['warn'].' §e'.@command.' [페이지]')
    }
  }

  register_command('help', array(
    'aliases': array('command', 'commands', 'cmd', 'cmds', '도움말', '명령어', '헬프', '커맨드'),
    'tabcompleter': closure(@command, @player, @args) { return(array()) },
    'executor': closure(@command, @player, @args) {
      _help_commnad(@command, @player, @args, @text)
    }
  ))
})

###
### 관리자 명령어 (모든 서버에서 작동되도록 수정 해야함)
###
/*
proc _admincmdArgs() { return(array('hga','event','vote','autoquiz')) }
register_command('admincmd', array(
  permission: 'admin.use',
  noPermMsg: color('RED').'권한이 부족합니다.',
  'executor': closure(@cmd, @sender, @cArgs){
       = '§f[ §3! §f] '
      if(array_size(@cArgs) > 0) {
        @exactArgs = _getArgsExact(_admincmdArgs(), @cArgs[0])
        if(array_size(@exactArgs) > 0) {
          switch(@exactArgs[0]) {
              case 'hga':
                @itemArr = pinv(@sender, null)

                if(array_size(@cArgs) == 1, array_push(@cArgs, 1))
                if(is_numeric(@cArgs[1]), @itemArr['qty'] = @cArgs[1], @itemArr['qty'] = 1)

                foreach(@player in all_players()){
                  if(pgive_item(@player, @itemArr) > 0, drop_item(ploc(@player), @itemArr))
                }
                broadcast('§e관리자가 모든 플레이어에게 아이템을 선물하였습니다.')
              case 'event':
                if(@cArgs[1] == 'hga') {
                  foreach(@player in all_players()) {
                      play_named_sound(ploc(@player), array('sound': 'entity.player.levelup', 'pitch': 0.7), array(@player))
                  }
                  broadcast('§7§m─────────────────────────')
                  broadcast('')
                  broadcast('§f잠시후 §b모든 유저분들§f에게 소정의 §a상품§f을 지급해드립니다!')
                  broadcast('§f반드시 인벤토리를 1-3 칸정도를 §6비워§f두시는걸 §8권장§f드립니다.')
                  broadcast('')
                  broadcast('§7§m─────────────────────────')
                }
              case 'vote':
                if(ponline(@cArgs[1])) {
                  broadcast('§e관리자§6'@sender'§e님이§f'@cArgs[1]'§e님에게 추천보상을 재지급 하였습니다.')
                  runas('~console', '/eco give'@cArgs[1]'250')
                  runas('~console', '/givepercentageexp'@cArgs[1]'2')
                } else {
                  msg('§6해당 플레이어는 온라인상태가 아닙니다.')
                }
              case 'autoquiz':
                export('evaquiz.settime', 0)
                msg('§6AutoQuiz 관련 인자가 초기화되었습니다.')
                msg('§6문제가 조기종료 및 즉시 출제될 수 있습니다.')
              default:
                msg('§6잘못된 인자가 전달되었습니다.')
          }
          exit()
        }
      } else {
        msg(.'/'.@cmd.' hga <개수> - HandGiveAll')
        msg(.'/'.@cmd.' event hga - hga 이벤트 공지')
        msg(.'/'.@cmd.' vote <닉네임> - 추천보상지급')
        msg(.'/'.@cmd.' autoquiz - autoquiz 초기화')
      }
  },
  'tabcompleter': closure(@cmd, @sender, @useArgs) {
      if(array_size(@useArgs) <= 1) {
        return(_getArgsExact(_admincmdArgs(), @useArgs[0]))
      }
      return(array())
  }
))
*/

###
### 채팅 관련 명령어
###
register_command('enko', array(
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      if(@players_data[@uuid]['chat'][1]) {
        @players_data[@uuid]['chat'][1] = false
        cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
      } else {
        @players_data[@uuid]['chat'][1] = true
        cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
      }
    }
  }
))

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
        default:
          @players_data[@uuid]['chat'][0] = 'local'
          cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
          break()
        }
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
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
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
      }
    }
  }
))

register_command('whisper', array( // last whisper 저장해서 /r 명령어 사용 가능하도록 만들기
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
      if(array_size(@args) > 1) {
        @data = array(
          'sender_name': @sender_name,
          'sender_uuid': @sender_uuid,
          'sender_setting': @players_data[@sender_uuid]['setting']
        )
        @is_target_exists = false
        @all_players_uuid = bukkitlinked_get_all_players()
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
              'color': '#7F8C8D',
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

###
### GUI 명령어 (유틸, 설정, 스킬, 워프)
###

#\\uF801\\ue540\\uF801\\ue540\\uF801\\ue540\\uF801\\ue540\\uF801\\ue56f\\uF801\\ue540\\uF801\\ue540\\uF801\\ue540\\uF801\\ue540\\uF81C\\uF81A\\uF802\\uF801\\ue5a0\\uF801\\ue5a0\\uF801\\ue5a0\\uF801\\ue5a0\\uF801\\ue5a0\\uF801\\ue5a0\\uF801\\ue5a0\\uF801\\ue5a0\\uF801\\ue5a0\\uF81C\\uF81A\\uF802\\uF801\\ue600\\uF801\\ue600\\uF801\\ue600\\uF801\\ue600\\uF801\\ue600\\uF801\\ue600\\uF801\\ue600\\uF801\\ue600\\uF801\\ue600\\uF81C\\uF81A\\uF802TunaLands

# 유틸
proc _util_command(@command, @player, @args, @text) {
  @texture_layer = @text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-162'].@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue59f'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue59f'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue59f'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue59f'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-162'].@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-162']
  @message = '유틸'
  @inventory = array()
  for(@index = 0, @index < 27, @index++) {
    @inventory[@index] = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': ' ',
        'model': 1
      )
    )
  }
  @inventory[0]['meta']['model'] = 3
  @inventory[10]['meta']['display'] = '§f워프'
  @inventory[10]['meta']['lore'] = array('§7좌클릭 시, 워프 GUI를 엽니다.')
  @inventory[12]['meta']['display'] = '§f스킬'
  @inventory[12]['meta']['lore'] = array('§7좌클릭 시, 스킬 GUI를 엽니다.')
  @inventory[14]['meta']['display'] = '§f치장'
  @inventory[14]['meta']['lore'] = array('§c준 비 중')
  @inventory[16]['meta']['display'] = '§f설정'
  @inventory[16]['meta']['lore'] = array('§7좌클릭 시, 설정 GUI를 엽니다.')
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @text) {
    bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @id) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 10:
          runas(@player, '/warp')
          break()
        case 12:
          runas(@player, '/skill')
          break()
        case 14:
          break()
        case 16:
          runas(@player, '/setting')
          break()
        }
      }
    }
  }
  _show_gui(@player, 'util', 27, @texture_layer, @message, @inventory, @closure, @text)
}
register_command('util', array(
  'aliases': array('유틸'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    _util_command(@command, @player, @args, @text)
  }
))
# 설정
proc _setting_command(@command, @player, @args, @text) {
  @uuid = puuid(@player)
  @texture_layer = @text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-1'].'\ue540'.@text['space_fonts']['space.-162'].@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue59f'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue59f'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-1'].'\ue5a0'.@text['space_fonts']['space.-162'].@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-1'].'\ue600'.@text['space_fonts']['space.-162']
  @message = '설정'
  @inventory = array()
  for(@index = 0, @index < 27, @index++) {
    @inventory[@index] = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': ' ',
        'model': 1
      )
    )
  }
  @inventory[0]['meta']['model'] = 4
  @inventory[12]['meta']['display'] = '§f채팅 설정'
  @inventory[12]['meta']['lore'] = array('§c준 비 중')
  @inventory[14]['meta']['display'] = '§f화면 설정'
  @inventory[14]['meta']['lore'] = array('§7좌클릭 시, 화면 설정 GUI를 엽니다.')
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @text) {
    bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @text) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 12:
          runas(@player, '/chat')
          break()
        case 14:
          runas(@player, '/screen')
          break()
        }
      }
    }
  }
  _show_gui(@player, 'setting', 27, @texture_layer, @message, @inventory, @closure, @uuid, @text)
}
register_command('setting', array(
  'aliases': array('설정'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    _setting_command(@command, @player, @args, @text)
  }
))
# 화면 설정 (GUI)
proc _screen_command(@command, @player, @args, @text, @uuid, @players_data, @skills_spec) {
  @is_using_right_hand = @players_data[@uuid]['setting'][1]
  if(@is_using_right_hand) {
    @left_skill_hud = '\uec1b'
    @right_skill_hud = '\uec1c'
  } else {
    @left_skill_hud = '\uec1c'
    @right_skill_hud = '\uec1b'
  }
  @texture_layer = @text['space_fonts']['space.-8'].'\uebff'.@text['space_fonts']['space.-169'].'\uec00'.@text['space_fonts']['space.-80'].@left_skill_hud.@text['space_fonts']['space.85'].@right_skill_hud.@text['space_fonts']['space.-146']
  @message = 'HUD 표시 너비 설정 :: '.@players_data[@uuid]['setting'][0]
  @inventory = array()
  for(@index = 0, @index < 27, @index++) {
    @inventory[@index] = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': ' ',
        'model': 1
      )
    )
  }
  @inventory[0]['meta']['model'] = 5
  @inventory[1]['meta']['display'] = '§f클릭시, HUD 표시 너비를 §e100§f 좁힙니다.'
  @inventory[1]['meta']['lore'] = array(
    '§7채팅 채널과 입력 언어 표시 HUD의 위치와',
    '§7채광/경작 진행도 표시 HUD의 위치를 조정할 수 있습니다',
    '',
    '§7마인크래프트 창 크기를 조절 했거나',
    '§7비디오 설정의 GUI 비율을 조절한 경우,',
    '§7HUD가 알맞게 위치할 수 있도록',
    '§7HUD 표시 너비를 수정해 주셔야 합니다.',
    '',
    '§7화면 좌우의 분홍색 면이 가려지며,',
    '§7채팅 정보 표시 HUD가 좌측 하단에 알맞게',
    '§7위치하도록 조절해주시면 됩니다.',
    '',
    '§7HUD 표시 너비 = 마인크래프트 해상도 / GUI 비율'
  )
  @inventory[2]['meta']['display'] = '§f클릭시, HUD 표시 너비를 §e10§f 좁힙니다.'
  @inventory[2]['meta']['lore'] = array(
    '§7채팅 채널과 입력 언어 표시 HUD의 위치와',
    '§7채광/경작 진행도 표시 HUD의 위치를 조정할 수 있습니다',
    '',
    '§7마인크래프트 창 크기를 조절 했거나',
    '§7비디오 설정의 GUI 비율을 조절한 경우,',
    '§7HUD가 알맞게 위치할 수 있도록',
    '§7HUD 표시 너비를 수정해 주셔야 합니다.',
    '',
    '§7화면 좌우의 분홍색 면이 가려지며,',
    '§7채팅 정보 표시 HUD가 좌측 하단에 알맞게',
    '§7위치하도록 조절해주시면 됩니다.',
    '',
    '§7HUD 표시 너비 = 마인크래프트 해상도 / GUI 비율'
  )
  @inventory[3]['meta']['display'] = '§f클릭시, HUD 표시 너비를 §e1§f 좁힙니다.'
  @inventory[3]['meta']['lore'] = array(
    '§7채팅 채널과 입력 언어 표시 HUD의 위치와',
    '§7채광/경작 진행도 표시 HUD의 위치를 조정할 수 있습니다',
    '',
    '§7마인크래프트 창 크기를 조절 했거나',
    '§7비디오 설정의 GUI 비율을 조절한 경우,',
    '§7HUD가 알맞게 위치할 수 있도록',
    '§7HUD 표시 너비를 수정해 주셔야 합니다.',
    '',
    '§7화면 좌우의 분홍색 면이 가려지며,',
    '§7채팅 정보 표시 HUD가 좌측 하단에 알맞게',
    '§7위치하도록 조절해주시면 됩니다.',
    '',
    '§7HUD 표시 너비 = 마인크래프트 해상도 / GUI 비율'
  )
  @inventory[4]['meta']['display'] = '§f클릭시, HUD 표시 너비를 기본(427)으로 되돌립니다.'
  @inventory[4]['meta']['lore'] = array(
    '§7채팅 채널과 입력 언어 표시 HUD의 위치와',
    '§7채광/경작 진행도 표시 HUD의 위치를 조정할 수 있습니다',
    '',
    '§7마인크래프트 창 크기를 조절 했거나',
    '§7비디오 설정의 GUI 비율을 조절한 경우,',
    '§7HUD가 알맞게 위치할 수 있도록',
    '§7HUD 표시 너비를 수정해 주셔야 합니다.',
    '',
    '§7화면 좌우의 분홍색 면이 가려지며,',
    '§7채팅 정보 표시 HUD가 좌측 하단에 알맞게',
    '§7위치하도록 조절해주시면 됩니다.',
    '',
    '§7HUD 표시 너비 = 마인크래프트 해상도 / GUI 비율'
  )
  @inventory[5]['meta']['display'] = '§f클릭시, HUD 표시 너비를 §e1§f 넓힙니다.'
  @inventory[5]['meta']['lore'] = array(
    '§7채팅 채널과 입력 언어 표시 HUD의 위치와',
    '§7채광/경작 진행도 표시 HUD의 위치를 조정할 수 있습니다',
    '',
    '§7마인크래프트 창 크기를 조절 했거나',
    '§7비디오 설정의 GUI 비율을 조절한 경우,',
    '§7HUD가 알맞게 위치할 수 있도록',
    '§7HUD 표시 너비를 수정해 주셔야 합니다.',
    '',
    '§7화면 좌우의 분홍색 면이 가려지며,',
    '§7채팅 정보 표시 HUD가 좌측 하단에 알맞게',
    '§7위치하도록 조절해주시면 됩니다.',
    '',
    '§7HUD 표시 너비 = 마인크래프트 해상도 / GUI 비율'
  )
  @inventory[6]['meta']['display'] = '§f클릭시, HUD 표시 너비를 §e10§f 넓힙니다.'
  @inventory[6]['meta']['lore'] = array(
    '§7채팅 채널과 입력 언어 표시 HUD의 위치와',
    '§7채광/경작 진행도 표시 HUD의 위치를 조정할 수 있습니다',
    '',
    '§7마인크래프트 창 크기를 조절 했거나',
    '§7비디오 설정의 GUI 비율을 조절한 경우,',
    '§7HUD가 알맞게 위치할 수 있도록',
    '§7HUD 표시 너비를 수정해 주셔야 합니다.',
    '',
    '§7화면 좌우의 분홍색 면이 가려지며,',
    '§7채팅 정보 표시 HUD가 좌측 하단에 알맞게',
    '§7위치하도록 조절해주시면 됩니다.',
    '',
    '§7HUD 표시 너비 = 마인크래프트 해상도 / GUI 비율'
  )
  @inventory[7]['meta']['display'] = '§f클릭시, HUD 표시 너비를 §e100§f 넓힙니다.'
  @inventory[7]['meta']['lore'] = array(
    '§7채팅 채널과 입력 언어 표시 HUD의 위치와',
    '§7채광/경작 진행도 표시 HUD의 위치를 조정할 수 있습니다',
    '',
    '§7마인크래프트 창 크기를 조절 했거나',
    '§7비디오 설정의 GUI 비율을 조절한 경우,',
    '§7HUD가 알맞게 위치할 수 있도록',
    '§7HUD 표시 너비를 수정해 주셔야 합니다.',
    '',
    '§7화면 좌우의 분홍색 면이 가려지며,',
    '§7채팅 정보 표시 HUD가 좌측 하단에 알맞게',
    '§7위치하도록 조절해주시면 됩니다.',
    '',
    '§7HUD 표시 너비 = 마인크래프트 해상도 / GUI 비율'
  )

  @inventory[19]['meta']['display'] = '§f클릭시, 액티브 스킬 HUD가 좌측에 보여지게 됩니다.'
  @inventory[19]['meta']['lore'] = array(
    '§7스킨 사용자 지정 설정의 "주로 사용하는 손"이',
    '§7오른손으로 설정되어 있을 시,',
    '§7액티브 스킬 HUD가 좌측에 보이도록 설정해야 합니다.',
    '',
    '§7왼손에 아이템을 들었을 시,',
    '§7핫바의 좌측에 왼손의 아이템이 보이며',
    '§7액티브 스킬을 사용할수 있을 시,',
    '§7핫바의 우측에 액티브 스킬 HUD가 보이게 됩니다.'
  )

  @inventory[21]['meta']['display'] = '§8핫바'
  @inventory[22]['meta']['display'] = '§8핫바'
  @inventory[23]['meta']['display'] = '§8핫바'

  @inventory[25]['meta']['display'] = '§f클릭시, 액티브 스킬 HUD가 우측에 보여지게 됩니다.'
  @inventory[25]['meta']['lore'] = array(
    '§7스킨 사용자 지정 설정의 "주로 사용하는 손"이',
    '§7왼손으로 설정되어 있을 시,',
    '§7액티브 스킬 HUD가 우측에 보이도록 설정해야 합니다.',
    '',
    '§7오른손에 아이템을 들었을 시,',
    '§7핫바의 우측에 오른손의 아이템이 보이며',
    '§7액티브 스킬을 사용할수 있을 시,',
    '§7핫바의 좌측에 액티브 스킬 HUD가 보이게 됩니다.'
  )

  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @players_data, @skills_spec, @text) {
    bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text) {
      @is_using_right_hand = @players_data[@uuid]['setting'][1]
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        @is_size_changed = false
        @new_resolution = @players_data[@uuid]['setting'][0]
        @new_is_using_right_hand = null
        switch(@event['rawslot']) {
        case 1:
          @new_resolution = @players_data[@uuid]['setting'][0] - 100
          break()
        case 2:
          @new_resolution = @players_data[@uuid]['setting'][0] - 10
          break()
        case 3:
          @new_resolution = @players_data[@uuid]['setting'][0] - 1
          break()
        case 4:
          @new_resolution = 427
          break()
        case 5:
          @new_resolution = @players_data[@uuid]['setting'][0] + 1
          break()
        case 6:
          @new_resolution = @players_data[@uuid]['setting'][0] + 10
          break()
        case 7:
          @new_resolution = @players_data[@uuid]['setting'][0] + 100
          break()
        case 19:
          @new_is_using_right_hand = false
          #@players_data[@uuid]['setting'][13] = true
          break()
        case 25:
          @new_is_using_right_hand = true
          #@players_data[@uuid]['setting'][13] = false
          break()
        }
        if(!is_null(@new_is_using_right_hand) && @is_using_right_hand != @new_is_using_right_hand) {
          @players_data[@uuid]['setting'][1] = @new_is_using_right_hand
          cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          if(@new_is_using_right_hand) {
            @left_skill_hud = '\uec1b'
            @right_skill_hud = '\uec1c'
          } else {
            @left_skill_hud = '\uec1c'
            @right_skill_hud = '\uec1b'
          }
          @texture_layer = @text['space_fonts']['space.-8'].'\uebff'.@text['space_fonts']['space.-169'].'\uec00'.@text['space_fonts']['space.-80'].@left_skill_hud.@text['space_fonts']['space.85'].@right_skill_hud.@text['space_fonts']['space.-146']
          @is_size_changed = true
        }
        if(@new_resolution < 256) {
          @new_resolution = 256
        } else if(@new_resolution > 32767) {
          @new_resolution = 32767
        }
        if(@new_resolution != @players_data[@uuid]['setting'][0]) {
          @players_data[@uuid]['setting'][0] = @new_resolution
          cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          @is_size_changed = true
        }
        if(@is_size_changed) {
          _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
          @message = 'HUD 표시 너비 설정 :: '.@players_data[@uuid]['setting'][0]
          _show_gui(@player, 'screen_setting', 27, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text)
        }
      }
    }
  }
  _show_gui(@player, 'screen_setting', 27, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text)
}
register_command('screen', array(
  'aliases': array('graphics', '화면설정'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    _screen_command(@command, @player, @args, @text, @uuid, @players_data, @skills_spec)
  }
))

# 화면 설정 (명령어)
proc _hud_command(@command, @player, @args, @text, @uuid, @players_data, @skills_spec) {
  switch(array_size(@args)) {
  case 0:
    msg(@text['prefix']['info']'§e/hud <너비>§7를 통해 HUD 표시 너비를 수정할 수 있습니다. (현재 너비:'.@players_data[@uuid]['setting'][0].')')
    break()
  case 1:
    if(is_integral(@args[0]) && integer(@args[0]) >= 256 && integer(@args[0]) < 32768 ) {
      @players_data[@uuid]['setting'][0] = integer(@args[0])
      _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
      cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
    } else {
      msg(@text['prefix']['failure']'§7256이상 32768미만의 정수만 입력 가능합니다.')
    }
    break()
  }
}
register_command('hud', array(
  'description': '',
  'usage': '/hud [width]',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    _hud_command(@command, @player, @args, @text, @uuid, @players_data, @skills_spec)
  }
))


/*
# 채팅 설정
  @texture_layer = ''
  @message = '채팅 설정'
  @inventory = array()
  for(@index = 0, @index < 27, @index++) {
    @inventory[@index] = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': ' ',
        'model': 1
      )
    )
  }
  @inventory[9] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f채팅 입력 :: 영어',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @inventory[10] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f채팅 채널 :: 기본',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @inventory[11] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f일반 채널 메시지 보기 :: 활성화',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @inventory[12] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f거리 채널 메시지 보기 :: 활성화',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @inventory[13] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f길드 채널 메시지 보기 :: 활성화',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @inventory[14] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f관리 채널 메시지 보기 :: 활성화',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @inventory[15] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f채팅 감시 :: 비활성화',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @inventory[16] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f호출 소리 :: 활성화',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @inventory[17] = array(
    'name': 'LIME_DYE',
    'meta': array(
      'display': '§f채팅 소리 :: 활성화',
      'lore': array(
        '§7',
      ),
      'model': 1
    )
  )
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @players_data, @skills_spec, @text) {
    bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 1:
          break()
        }
      }
    }
  }
  _show_gui(@player, 'chat_setting', 27, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text)
*/
# 워프
proc _warp_command(@command, @player, @args, @text, @server) {
  if(@server == 'main') {
    @random_teleport = @text['space_fonts']['space.-1'].'\uec09'.@text['space_fonts']['space.-1'].'\uec10'.@text['space_fonts']['space.-1'].'\uec17'
    @random_teleport_item = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§f랜덤 텔레포트',
        'lore': array('§7좌클릭 시, 랜덤 텔레포트 GUI를 엽니다.'),
        'model': 1
      )
    )
  } else {
    @random_teleport = @text['space_fonts']['space.-1'].'\uec0c'.@text['space_fonts']['space.-1'].'\uec13'.@text['space_fonts']['space.-1'].'\uec1a'
    @random_teleport_item = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§f랜덤 텔레포트',
        'lore': array('§c해당 월드에선 사용하실 수 없습니다.'),
        'model': 1
      )
    )
  }
  @texture_layer = @text['space_fonts']['space.-1'].'\uec03'.@text['space_fonts']['space.-1'].'\uec04'.@text['space_fonts']['space.-1'].'\uec05'.@text['space_fonts']['space.-1'].'\uec06'.@text['space_fonts']['space.-1'].'\uec07'.@text['space_fonts']['space.-1'].'\uec08'.@random_teleport.@text['space_fonts']['space.-162']
  @message = '어디로 갈까요..?'
  @spawn_item = array(
    'name': 'STRUCTURE_VOID',
    'meta': array(
      'display': '§f스폰',
      'lore': array('§7좌클릭 시, 스폰으로 이동합니다.'),
      'model': 1
    )
  )
  @home_item = array(
    'name': 'STRUCTURE_VOID',
    'meta': array(
      'display': '§f홈',
      'lore': array('§7좌클릭 시, 홈으로 이동합니다.'),
      'model': 1
    )
  )
  @inventory = array(
    0: @spawn_item,
    1: @spawn_item,
    2: @spawn_item,
    3: @home_item,
    4: @home_item,
    5: @home_item,
    6: @random_teleport_item,
    7: @random_teleport_item,
    8: @random_teleport_item,
    9: @spawn_item,
    10: @spawn_item,
    11: @spawn_item,
    12: @home_item,
    13: @home_item,
    14: @home_item,
    15: @random_teleport_item,
    16: @random_teleport_item,
    17: @random_teleport_item,
    18: @spawn_item,
    19: @spawn_item,
    20: @spawn_item,
    21: @home_item,
    22: @home_item,
    23: @home_item,
    24: @random_teleport_item,
    25: @random_teleport_item,
    26: @random_teleport_item,
  )
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @server) {
    bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @server) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 0..2:
        case 9..11:
        case 18..20:
          runas(@player, '/spawn')
          break()
        case 3..5:
        case 12..14:
        case 21..23:
          runas(@player, '/home')
          break()
        case 6..8:
        case 15..17:
        case 24..26:
          if(@server == 'main') {
            runas(@player, '/randomteleport')
          }
          break()
        }
      }
    }
  }
  _show_gui(@player, 'setting', 27, @texture_layer, @message, @inventory, @closure, @server)
}
register_command('warp', array(
  'aliases': array('워프'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    _warp_command(@command, @player, @args, @text, @server)
  }
))

# 스킬
proc _skill_command(@command, @player, @args, @text, @players_data, @skills_info, @skills_spec) {
  @uuid = puuid(@player)
  if(array_size(@args) == 0) {
    @args[0] = 'combat'
  }
  switch(@args[0]) {
  case 'combat':
  case 'pvp':
  case '전투':
    _open_combat_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text)
    break()
  case 'farmingmethod':
  case '농사방식':
    _open_farming_method_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text)
    break()
  case 'farming':
  case '농사':
    _open_farming_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text)
    break()
  case 'mining':
  case '채광':
  case '채굴':
    _open_mining_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text)
    break()
  default:
    msg(@text['prefix']['warn']'§7해당 스킬 카테고리를 찾을 수 없습니다.')
    msg(' §e/'.@command.' [스킬 카테고리]§7를 통해 스킬북을 열 수 있습니다.')
    break()
  }
}
register_command('skillbook', array(
  'aliases': array('skill', 'abilitybook', 'ability', 'masterybook', 'mastery', '스킬북', '스킬', '어빌리티북', '어빌리티', '마스터리북', '마스터리'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    _skill_command(@command, @player, @args, @text, @players_data, @skills_info, @skills_spec)
  }
))

# 룬
proc _rune_command(@command, @player, @args, @text, @players_data, @skills_info, @skills_spec) {
  @uuid = puuid(@player)
  if(array_size(@args) == 0) {
    @page = 0
    _open_rune(@player, @uuid, @players_data, @skills_info, @skills_spec, @page, @text)
  } else {
    msg(@text['prefix']['warn']'§7잘못된 인자 입력입니다.')
    msg(' §e/'.@command.'을 통해 룬 백을 열 수 있습니다.')

  }
}
register_command('runebag', array(
  'aliases': array('rune', '룬백', '룬'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    _rune_command(@command, @player, @args, @text, @players_data, @skills_info, @skills_spec)
  }
))
###
### 어드민 명령어
###
proc _setbadge_command(@command, @player, @args, @text, @players_data) {
  if(array_size(@args) == 2) {
    @target_name = @args[0]
    if(ponline(@target_name)) {
      @target_uuid = puuid(@target_name)
      @badge = char_from_unicode(parse_int(replace(@args[1], '\\u', ''), 16))
      @players_data[@target_uuid]['decoration'][0] = @badge
      cup_set('DECORATION', @target_uuid, @players_data[@target_uuid]['decoration'])
    }
  }
}
register_command('setbadge', array(
  permission: 'setbadge',
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 0) {
      @return = all_players()
    } else {
      @return = array()
    }
    return(@return)
  },
  'executor': closure(@command, @player, @args) {
    _setbadge_command(@command, @player, @args, @text, @players_data)
  }
))

proc _chatobserver_command(@command, @player, @args, @text, @players_data) {
  @uuid = puuid(@player)
  @chat_observer_mode = @players_data[@uuid]['chat'][3]
  if(@chat_observer_mode == true) {
    @players_data[@uuid]['chat'][3] = false
    cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
    msg('감시 오프')
  } else {
    @players_data[@uuid]['chat'][3] = true
    cup_set('CHAT', @uuid, @players_data[@uuid]['chat'])
    msg('감시 온')
  }
}
register_command('chatobserver', array(
  permission: 'chatobserver',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    _chatobserver_command(@command, @player, @args, @text, @players_data)
  }
))

register_command('sendwarn', array(
  #permission: 'sendwarn',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @target_name = @args[0]
    @target_uuid = puuid(@target_name)
    @player_data = @players_data[@target_uuid]
    @tooltip_data = array(
      'type': 'warn',
      'message': array_implode(array_get(@args, cslice(1, array_size(@args) - 1)), ' '),
      'countdown': 3
    )
    _add_tooltip(@target_name, @target_uuid, @player_data, @tooltip_data)
    _set_tooltips(@target_name, @target_uuid, @player_data)
  }
))

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

proc _chreload_command(@command, @player, @args, @text, @players_data) {
  foreach(@target_name in all_players()) {
    @target_uuid = puuid(@target_name)
    # 커스텀 인벤 닫기
    @inv_holder = pinventory_holder(@target_name)
    if(is_string(@inv_holder) && @inv_holder != @target_uuid) {
      close_pinv(@target_name)
    }
    
    # 액티브 스킬 저장
    if(array_index_exists(@players_data, @target_uuid)) {
      @player_data = @players_data[@target_uuid]
      @skill_manager = @player_data['skill_manager']

      @selected_methods = json_decode(@skill_manager[4])
      
      @selected_combat_method = @selected_methods['combat_method']
      if(@selected_combat_method != '') {
        @active_skill = @player_data['active_skill'][@selected_combat_method]
        _save_active_skill(@target_uuid, @selected_combat_method, @active_skill)
      }

      @selected_sowing_method = @selected_methods['sowing_method']
      if(@selected_sowing_method != '') {
        @active_skill = @player_data['active_skill'][@selected_sowing_method]
        _save_active_skill(@target_uuid, @selected_sowing_method, @active_skill)
      }

      @selected_harvesting_method = @selected_methods['harvesting_method']
      if(@selected_harvesting_method != '') {
        @active_skill = @player_data['active_skill'][@selected_harvesting_method]
        _save_active_skill(@target_uuid, @selected_harvesting_method, @active_skill)
      }

      // 룬에 액티브 스킬 생길시 액티브 스킬도 불어와 저장해야함
    }
  }
  set_timeout(1, closure() {
    broadcast(@text['prefix']['broadcast'] _color('#80c8ff').'인스턴스 패치가 진행되어 일부 데이터가 초기화 되었습니다.')
    run('/reloadalias')
  })
}
register_command('chreload', array(
  permission: 'chreload',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    _chreload_command(@command, @player, @args, @text, @players_data)
  }
))