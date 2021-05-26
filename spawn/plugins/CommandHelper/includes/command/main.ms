# 접두사 선언
@prefix = array(
  'success': '\ue4dc',
  'failure': '\ue4de',
  'warn': '\ue4dd',
  'info': '\ue4e3'
)

###
### 서버 정보 명령어
###

proc _info_command(@command, @player, @args, @prefix) {
  msg(@prefix['info'].' §b서버 정보')
  msg(' §7서버명: §f에바참치 §7(§fEvatuna§7)')
  msg(' §7서버 장르: 야생')
  msg(' §7총 관리자: 앨리스(§btele§f: @alicearcade, §7dis§f: AA_2#1787)')
  msg(' §7공식 이메일: support@evatuna.fish')
  msg(' §7공식 홈페이지 : §7/site')
  msg(' §7공식 카페 : §a(네이버)§7/cafe')
  msg(' §7공식 디스코드: §7/discord')
  msg(' §7마인리스트: §7/vote')
  msg(' §7서버오픈일: 2021년 06월 01일')
}

register_command('cafe', array(
  'executor': closure(@cmd, @sender, @cArgs){
    msg('\ue4dc §aNaverCafe §r : https://cafe.evatuna.fish')
  }
))
register_command('discord', array(
  'executor': closure(@cmd, @sender, @cArgs){
    msg('\ue4dc §7Discord §r : https://discord.evatuna.fish/')
  }
))
register_command('site', array(
  'executor': closure(@cmd, @sender, @cArgs){
    msg('\ue4dc §9EvatunaOffical §r : https://evatuna.fish/')
  }
))
register_command('info', array(
  'aliases': array('about', 'version', 'ver', '서버', '서버정보'),
  'tabcompleter': closure(@command, @player, @args) {
    return(array())
  },
  'executor': closure(@command, @player, @args) {
    _info_command(@command, @player, @args, @prefix)
  }
))

###
### 도움말 명령어
###

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
proc _help_commnad(@command, @player, @args, @prefix) {
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
    msg(@prefix['info'].' §b/'.@command.' ['.@page.'/'.@max_page.'] §7< > = 필수 인자, [ ] = 선택 인자')
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
      break()
    case 4:
      msg(' §b# 돈')
      _help_message(@player, 'money', array(), null, '현재 소지한 돈을 확인합니다.')
      _help_message(@player, 'pay', array(), '<닉네임> <수량>', '플레이어에게 돈을 송금합니다.')
      msg(' §b# 기타')
      _help_message(@player, 'co i', array(), null, '로그조사 (토글)')
      #_help_message(@player, '', array(), null, '')
      break()
    default:
      msg(' §7해당 페이지의 도움말이 존재하지 않습니다.')
      break()
    }
  } else {
    msg(@prefix['warn'].' §e'.@command.' [페이지]')
  }
}

unregister_command('minecraft:help')
unregister_command('bukkit:help')
register_command('help', array(
  'aliases': array('command', 'commands', 'cmd', 'cmds', '도움말', '명령어', '헬프', '커맨드'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    _help_commnad(@command, @player, @args, @prefix)
  }
))

/*


  // set_timeout(4000, closure(){
  //   msg('')
  //   msg('§7  유저분들의 놀거리와 재미를 위해 기초를 탄탄하게 §6계획§7하였고')
  //   msg('§7  기반으로 §9설계§7, §8개발§7하였습니다.')
  //   msg('')
  //   set_timeout(4000, closure(){
  //       msg('')
  //       msg('§7  부족한 부분이 있다면 여러 시스템들이 더 잘 어우러질 수 있도록')
  //       msg('§7  §e보완§7하고, §a업데이트§7해 나갈 것 입니다.')
  //       msg('')
  //       set_timeout(4000, closure(){
  //         msg('')
  //         msg('§7  여러 시스템이 적용되어 있고 야생 유저분들께는 생소할 수 있다 생각하여')
  //         msg('§7  Wiki를 자세히 써 두었습니다.')
  //         msg('')
  //         set_timeout(3000, closure(){
  //           msg('')
  //           msg('§7  Wiki : /wiki')
  //           msg('§7  그리고 /'.@cmd'info 명령어를 통해 저희 서버의 정보를 받아보세요.')
  //           msg('')
  //         })
  //       })
  //   })
  // })
*/

###
### 관리자 명령어 (모든 서버에서 작동되도록 수정 해야함)
###
/*
proc _admincmdArgs() { return(array('hga','event','vote','autoquiz')); }
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
      if(@players_data[@uuid]['setting'][1]) {
        @players_data[@uuid]['setting'][1] = false
        cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
      } else {
        @players_data[@uuid]['setting'][1] = true
        cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
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
      if(!is_null(moori_get_player_guild_id(@uuid))) {
        @return[] = 'guild'
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
        switch(@players_data[@uuid]['setting'][0]) {
        case 'local':
          if(!is_null(moori_get_player_guild_id(@uuid))) {
            @players_data[@uuid]['setting'][0] = 'guild'
          } else {
            if(pisop(@player)) {
              @players_data[@uuid]['setting'][0] = 'admin'
            } else {
              @players_data[@uuid]['setting'][0] = 'default'
            }
          }
          cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          break()
        case 'guild':
          if(pisop(@player)) {
            @players_data[@uuid]['setting'][0] = 'admin'
          } else {
            @players_data[@uuid]['setting'][0] = 'default'
          }
          cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          break()
        case 'admin':
          @players_data[@uuid]['setting'][0] = 'default'
          cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          break()
        default:
          @players_data[@uuid]['setting'][0] = 'local'
          cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          break()
        }
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
      } else if(array_size(@args) == 1) {
        switch(@args[0]) {
        case 'local':
          @players_data[@uuid]['setting'][0] = 'local'
          cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          break()
        case 'guild':
          if(!is_null(moori_get_player_guild_id(@uuid))) {
            @players_data[@uuid]['setting'][0] = 'guild'
            cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          }
          break()
        case 'admin':
          if(pisop(@player)) {
            @players_data[@uuid]['setting'][0] = 'admin'
            cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          }
          break()
        default:
          @players_data[@uuid]['setting'][0] = 'default'
          cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
          break()
        }
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
      }
    }
  }
))

register_command('whisper', array(
  'aliases': array('w', 'm', 'msg', 'tell', '귓속말', '귓'),
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

###
### GUI 명령어 (유틸, 설정)
###

# 유틸
proc _util_command(@command, @player, @args, @prefix, @text) {
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
    bind('inventory_click', array('id': 'click'.@id), array('player'; @player, 'virtual': true), @event, @player) {
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
    _util_command(@command, @player, @args, @prefix, @text)
  }
))
# 설정
proc _setting_command(@command, @player, @args, @prefix, @text) {
  @texture_layer = ''
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
  @inventory[11]['meta']['display'] = '§f채팅 설정'
  @inventory[11]['meta']['lore'] = array('§7좌클릭 시, 채팅 설정 GUI를 엽니다.')
  @inventory[15]['meta']['display'] = '§f화면 설정'
  @inventory[15]['meta']['lore'] = array('§7좌클릭 시, 화면 설정 GUI를 엽니다.')
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @text) {
    bind('inventory_click', array('id': 'click'.@id), array('player'; @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @text) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 11:
          runas(@player, '/chat')
          break()
        case 15:
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
    _setting_command(@command, @player, @args, @prefix, @text)
  }
))
# 화면 설정 (GUI)
proc _screen_command(@command, @player, @args, @prefix, @uuid, @players_data, @skills_spec, @text) {
  @texture_layer = ''
  @message = 'HUD 표시 너비 설정 :: '.@players_data[@uuid]['setting'][12]
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
  @inventory[4]['meta']['display'] = '클릭시, HUD 표시 너비를 기본(427)으로 되돌립니다.'
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
  @inventory[6]['meta']['display'] = '§f클릭시, HUD 표시 너비를 §e100§f 넓힙니다.'
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
    bind('inventory_click', array('id': 'click'.@id), array('player'; @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        @is_size_changed = false
        @new_resolution = @players_data[@uuid]['setting'][12]
        switch(@event['rawslot']) {
        case 1:
          @new_resolution = @players_data[@uuid]['setting'][12] - 100
          break()
        case 2:
          @new_resolution = @players_data[@uuid]['setting'][12] - 10
          break()
        case 3:
          @new_resolution = @players_data[@uuid]['setting'][12] - 1
          break()
        case 4:
          @new_resolution = 427
          break()
        case 5:
          @new_resolution = @players_data[@uuid]['setting'][12] + 1
          break()
        case 6:
          @new_resolution = @players_data[@uuid]['setting'][12] + 10
          break()
        case 7:
          @new_resolution = @players_data[@uuid]['setting'][12] + 100
          break()
        }
        if(@new_resolution < 256) {
          @new_resolution = 256
        } else if(@new_resolution > 32767) {
          @new_resolution = 32767
        }
        if(@new_resolution != @players_data[@uuid]['setting'][12]) {
          @players_data[@uuid]['setting'][12] = @new_resolution
          @is_size_changed = true
        }
        if(@is_size_changed) {
          _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
          @message = 'HUD 표시 너비 설정 :: '.@players_data[@uuid]['setting'][12]
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
    _screen_command(@command, @player, @args, @prefix, @uuid, @players_data, @skills_spec, @text)
  }
))
# 화면 설정 (명령어)
proc _hud_command(@command, @player, @args, @prefix, @uuid, @players_data, @skills_spec, @text) {
  switch(array_size(@args)) {
  case 0:
    msg('\ue4dd §e/hud <너비>§7를 통해 HUD 표시 너비를 수정할 수 있습니다. (현재 너비:'.@players_data[@uuid]['setting'][12].')')
    break()
  case 1:
    if(is_integral(@args[0]) && integer(@args[0]) >= 256 && integer(@args[0]) < 32768 ) {
      @players_data[@uuid]['setting'][12] = integer(@args[0])
      _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
      cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
    } else {
      msg('\ue4de §7256이상 32768미만의 정수만 입력 가능합니다.')
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
    _hud_command(@command, @player, @args, @prefix, @uuid, @players_data, @skills_spec, @text)
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
    bind('inventory_click', array('id': 'click'.@id), array('player'; @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text) {
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