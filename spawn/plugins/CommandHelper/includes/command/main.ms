register_command('enko', array(
  'description': '',
  'usage': '/enko',
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

register_command('ch', array(
  'description': '',
  'usage': '/ch [channel]',
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

register_command('hud', array(
  'description': '',
  'usage': '/hud [width]',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
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
))

register_command('util', array(
  'description': '/util',
  'usage': '/util',
  'tabcompleter': closure(@command, @player, @args) {
    @return = array()
    return(@return)
  },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      if(array_size(@args) == 0) {
        @texture_layer = ''
        @message = '유틸 GUI'
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
        @inventory[10]['meta']['lore'] = array('§7좌클릭 시, 워프 GUI를 엽니다')
        @inventory[12]['meta']['display'] = '§f스킬'
        @inventory[12]['meta']['lore'] = array('§7좌클릭 시, 스킬 GUI를 엽니다')
        @inventory[14]['meta']['display'] = '§f치장'
        @inventory[14]['meta']['lore'] = array('§c준 비 중')
        @inventory[16]['meta']['display'] = '§f설정'
        @inventory[16]['meta']['lore'] = array('§7좌클릭 시, 설정 GUI를 엽니다')
        @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @text) {
          bind('inventory_click', array('id': 'click'.@id), array('player'; @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @text) {
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
        _show_gui(@player, 'util', 27, @texture_layer, @message, @inventory, @closure, @uuid, @text)
      } else {
        #X오류메시지
      }
    }
  }
))

register_command('setting', array(
  'description': '',
  'usage': '/setting [category]',
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 1) {
      @return = array('chat', 'screen')
    } else {
      @return = array()
    }
    return(@return)
  },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      switch(array_size(@args)) {
      case 0:
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
        @inventory[11]['meta']['lore'] = array('§7좌클릭 시, 채팅 설정 GUI를 엽니다')
        @inventory[15]['meta']['display'] = '§f화면 설정'
        @inventory[15]['meta']['lore'] = array('§7좌클릭 시, 화면 설정 GUI를 엽니다')
        @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @text) {
          bind('inventory_click', array('id': 'click'.@id), array('player'; @player, 'virtual': true), @event, @player, @texture_layer, @message, @inventory, @closure, @uuid, @text) {
            cancel()
            if(@event['action'] == 'PICKUP_ALL') {
              switch(@event['rawslot']) {
              case 11:
                runas(@player, '/chatsetting')
                break()
              case 15:
                runas(@player, '/screensetting')
                break()
              }
            }
          }
        }
        _show_gui(@player, 'setting', 27, @texture_layer, @message, @inventory, @closure, @uuid, @text)
        break()
      case 1:
        switch(@args[0]) {
        case 'screen':
        case 'graphics':
        case 'hud':
          runas(@player, '/screensetting')
          break()
        case 'chat':
        case 'chating':
          runas(@player, '/chatsetting')
          break()
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
          break()
        }
        break()
      }
    }
  }
))

register_command('screensetting', array(
  'description': '',
  'usage': '/screensetting',
  'aliases': array('화면설정', 'graphicssetting'),
  'tabcompleter': closure(@command, @player, @args) {
    if(array_size(@args) == 1) {
      @return = array('chat', 'screen')
    } else {
      @return = array()
    }
    return(@return)
  },
  'executor': closure(@command, @player, @args) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      if(array_size(@args) == 0) {
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
      } else {
        #명령어 실패
      }
    }
  }
))