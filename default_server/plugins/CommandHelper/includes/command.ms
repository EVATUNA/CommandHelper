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
        kafka_send('ch.resourcepack_url_update', @args[0])
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
    msg(@text['prefix']['info'].' §b서버 정보')
    msg(' §7서버명: §f에바참치 §7(§fEvatuna§7)')
    msg(' §7총 관리자: 앨리스(§btele§f: @alicearcade, §7dis§f: AA_2#1787)')
    msg(' §7공식 이메일: support@evatuna.fish')
    msg(' §7공식 홈페이지 : §7/site')
    msg(' §7공식 네이버 카페 : /cafe')
    msg(' §7공식 디스코드: §7/discord')
    msg(' §7공식 블로그: §7/blog')
    msg(' §7마인리스트: §7/vote')
    msg(' §7서버오픈일: 2022년 03월 19일')
  }
  if(_is_command_registered('info')) { unregister_command('info') }
  //if(_is_command_registered('version')) { unregister_command('version') }
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
    'executor': closure(@command, @player, @args) {
      msg(@text['prefix']['info']'§aNaverCafe §r : https://cafe.evatuna.fish')
    }
  ))
  register_command('discord', array(
    'executor': closure(@command, @player, @args) {
      msg(@text['prefix']['info']'§7Discord §r : https://discord.evatuna.fish/')
    }
  ))
  register_command('site', array(
    'executor': closure(@command, @player, @args) {
      msg(@text['prefix']['info']'§9EvatunaOffical §r : https://evatuna.fish/')
    }
  ))
  register_command('blog', array(
    'executor': closure(@command, @player, @args) {
      msg(@text['prefix']['info']'§9EvatunaBlog §r : https://blog.evatuna.fish/')
    }
  ))
  /*
  register_command('guide', array(
    'executor': closure(@command, @player, @args) {
      if(array_size(@args) != 1) {
        @arg = ''
      } else {
        @arg = @args[0]
      }
      switch(@arg) {
      case 'usershop':
        msg(@text['prefix']['info']'§7유저 상점 가이드\n §7https://lavender-tugboat-45a.notion.site/9189f462fa7047af809d3aa8fa90edb0')
      default:
        msg(@text['prefix']['info']'§7가이드 목록')
        msg(' §7usershop')
      }
    }
  ))
  */

  ###
  ### 도움말 명령어
  ###
  if(_is_command_registered('help')) { unregister_command('help') }

  proc _show_help_page_message(@player, @command, @page, @max_page, @text) {
    @command_text = '/'.@command
    @translate = string_multiply(' %s', @max_page)
    @withs = array()
    for(@i = 1, @i <= @max_page, @i ++) {
      @with = array(
        'text': '<'.@i.'>'
      )
      if(@i == @page) {
        @with['color'] = 'aqua'
      } else {
        @with['clickEvent'] = array(
          'action': 'run_command',
          'value': '/'.@command @i
        )
        @with['hoverEvent'] = array(
          'action': 'show_text',
          'value': '좌클릭 시,'@i.'번째 페이지를 볼 수 있습니다.'
        )
      }
      @withs[] = @with
    }
    @raw = array(
      array(
        'text': '',
        'color': 'gray'
      ),
      array(
        'text': @text['prefix']['info'].' ',
        'color': 'white'
      ),
      array(
        'text': @command_text,
        'color': 'yellow'
      ),
      array(
        'translate': @translate,
        'with': @withs
      )
    )
    _tellraw(@player, @raw)
  }
  
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
    @max_page = 5
    if(!is_null(@page)) {
      msg('')
      _show_help_page_message(@player, @command, @page, @max_page, @text)
      msg('§7 위의 숫자 좌클릭하여 페이지 변경이 가능합니다.')
      msg('§e 아래의 명령어를 좌클릭할 시, 채팅창에 명령어가 입력됩니다.')
      switch(@page) {
      case 1:
        msg(' §b# 도움말')
        _help_message(@player, 'help', array('command', 'commands', 'cmd', 'cmds', '도움말', '명령어', '헬프', '커맨드'), '[페이지]', '서버 명령어를 확인합니다.')
        _help_message(@player, 'info', array('about', 'version', 'ver', '서버', '서버정보'), null, '서버 정보를 확인합니다.')
        //_help_message(@player, 'guide', array('가이드'), '[가이드 이름]', '가이드를 봅니다.')
        break()
      case 2:
        msg(' §b# 채팅')
        _help_message(@player, 'whisper', array('w', 'm', 'msg', 'tell', '귓속말', '귓'), '<닉네임> [할 말]', '플레이어에게 귓속말을 보냅니다.')
        _help_message(@player, 'reply', array('r', '답장'), '[할 말]', '마지막으로 귓말을 보낸 사람에게 귓속말을 보냅니다.')
        msg(' §7whisper 명령어와 reply 명령어 사용 시 할 말을 비워두면 귓속말을 보낼 유저를 대상으로한 귓속말 채널로 전환이 가능합니다.')
        _help_message(@player, 'channel', array('ch', '채널'), '[채널]', '채팅 채널을 변경합니다.')
        _help_message(@player, 'enko', array(), null, '한영 치환 입력을 활성/비활성합니다.')
        break()
        //msg(' §b# 설정')
        //_help_message(@player, 'setting', array('설정'), null, '설정 GUI를 엽니다.')
        //_help_message(@player, 'screen', array('graphics', '화면설정'), null, '화면 설정 GUI를 엽니다.')
        //_help_message(@player, 'hud', array(), '<너비>', 'HUD 표시 너비를 조정합니다.')
      case 3:
        msg(' §b# 유틸')
        _help_message(@player, 'util', array('gui', '유틸'), null, '유틸 GUI를 엽니다.')
        msg(' §b# 텔레포트')
        _help_message(@player, 'spawn', array(), null, '스폰으로 이동합니다.')
        _help_message(@player, 'home', array(), null, '홈으로 이동합니다.')
        _help_message(@player, 'warp', array('워프'), null, '워프 GUI를 엽니다.')
        _help_message(@player, 'randomteleport', array('rt', '랜덤텔포', '랜덤티피',), null, '랜덤 텔레포트 GUI를 엽니다.')
        break()
      case 4:
        msg(' §b# 스킬')
        _help_message(@player, 'skillbook', array('skill', 'abilitybook', 'ability', 'masterybook', 'mastery', '스킬북', '스킬', '어빌리티북', '어빌리티', '마스터리북', '마스터리'), null, '스킬북을 엽니다.')
        msg(' §b# 로그 조사')
        _help_message(@player, 'co i', array(), null, '로그조사 (토글)')
        msg(' §b# 돈')
        _help_message(@player, 'money', array(), null, '현재 소지한 돈을 확인합니다.')
        _help_message(@player, 'pay', array(), '<닉네임> <수량>', '플레이어에게 돈을 송금합니다.')
        break()
      case 5:
        msg(' §b# 튜나랜드 (마을)')
        _help_message(@player, 'tunaland', array('tl'), null, '거주 월드 청크 관리 명령어입니다.')
        msg(' §b# 유저 상점')
        _help_message(@player, 'usershop', array('us', '유저상점'), null, '유저 상점 GUI를 엽니다.')
        _help_message(@player, 'usershop', array('us', '유저상점'), 'sell <가격> [수량]', '손에든 아이템을 판매합니다.')
        msg(' §b# 레이드')
        _help_message(@player, 'raid', array(), null, '레이드 GUI를 엽니다.')
        break()
      default:
        msg(' §7해당 페이지의 도움말이 존재하지 않습니다.')
        break()
      }
    } else {
      msg(@text['prefix']['warn'].' §e/'.@command.' [페이지]')
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

proc _usershop_command(@command, @player, @args, @text) {
  @args_string = array_implode(@args, ' ')
  run("/zauction @args_string")
}

register_command('usershop', array(
  'aliases': array('us', '유저상점'),
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 1) {
      return(array('sell'))
    } else {
      return(array())
    }
  },
  'executor': closure(@command, @player, @args) {
    _usershop_command(@command, @player, @args, @text)
  }
))

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
  @inventory[16]['meta']['lore'] = array('§c준 비 중')
  //@inventory[16]['meta']['lore'] = array('§7좌클릭 시, 설정 GUI를 엽니다.')
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @text) {
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @id) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 10:
          runas(@player, '/warp')
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
          break()
        case 12:
          runas(@player, '/skill')
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
          break()
        case 14:
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
          break()
        case 16:
          //runas(@player, '/setting')
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
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
/*
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
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @text) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 12:
          runas(@player, '/chat')
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
          break()
        case 14:
          runas(@player, '/screen')
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
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
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text) {
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
*/


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
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_spec, @text) {
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
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @server) {
      cancel()
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 0..2:
        case 9..11:
        case 18..20:
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
          runas(@player, '/spawn')
          break()
        case 3..5:
        case 12..14:
        case 21..23:
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
          runas(@player, '/home')
          break()
        case 6..8:
        case 15..17:
        case 24..26:
          play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
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
/*
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
*/

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
  permission: 'sendwarn',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @target_name = @args[0]
    @target_uuid = puuid(@target_name)
    @text = import('text')
    @prefix_index = @args[1]
    if(array_index_exists(@text['prefix'], @prefix_index)) {
      @prefix = @text['prefix'][@prefix_index]
      @message = array_implode(array_get(@args, cslice(2, array_size(@args) - 1)), ' ')
      _send_instance_tooltip_msg(@target_name, @target_uuid, @prefix @message)
    } else {
      @prefix = @text['prefix']['warn']
      @message = array_implode(array_get(@args, cslice(1, array_size(@args) - 1)), ' ')
      _send_instance_tooltip_msg(@target_name, @target_uuid, @prefix @message)
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
      if(@selected_combat_method != '' && array_index_exists(@player_data['active_skill'], @selected_combat_method)) {
        @active_skill = @player_data['active_skill'][@selected_combat_method]
        _save_active_skill(@target_uuid, @selected_combat_method, @active_skill)
      }

      @selected_sowing_method = @selected_methods['sowing_method']
      if(@selected_sowing_method != '' && array_index_exists(@player_data['active_skill'], @selected_sowing_method)) {
        @active_skill = @player_data['active_skill'][@selected_sowing_method]
        _save_active_skill(@target_uuid, @selected_sowing_method, @active_skill)
      }

      @selected_harvesting_method = @selected_methods['harvesting_method']
      if(@selected_harvesting_method != '' && array_index_exists(@player_data['active_skill'], @selected_harvesting_method)) {
        @active_skill = @player_data['active_skill'][@selected_harvesting_method]
        _save_active_skill(@target_uuid, @selected_harvesting_method, @active_skill)
      }

      // 룬에 액티브 스킬 생길시 액티브 스킬도 불어와 저장해야함
    }
  }
  set_timeout(1, closure() {
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