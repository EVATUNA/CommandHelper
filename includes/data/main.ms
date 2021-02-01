console('EvaData loaded')

proc _load_data(@uuid, @players_data) {
  pogu_get('setting_data:'.@uuid, closure(@connected, @value) { @players_data[@uuid]['setting'] = json_decode(@value) })
  pogu_get('chating_data:'.@uuid, closure(@connected, @value) { @players_data[@uuid]['chating'] = json_decode(@value) })
}
proc _save_data(@uuid, @players_data, @clear) {
  pogu_set('setting_data:'.@uuid, json_encode(@players_data[@uuid]['setting']), closure(@connected, @value) {})
  pogu_set('chating_data:'.@uuid, json_encode(@players_data[@uuid]['chating']), closure(@connected, @value) {})
  pogu_set('skill_data:'.@uuid, json_encode(@players_data[@uuid]['skill']), closure(@connected, @value) {})
  if(@clear) {
    array_remove(@players_data, @uuid)
  }
}
proc _new_data(@uuid, @players_data) {
  @players_data[@uuid]['chating'] = array(
    'channel': 'general',
    'en_ko': false,
    'selected_badge': ''
  )
  @players_data[@uuid]['setting'] = array(
    'interface': array(
      'resolution': 427,
      'hand': 'right'
    ),
    'chating': array(
      'type': 'general', // general / messenger
      'alignment': 'none', // none / center / left / right
      'listening': array(
        'general': true,
        'local': true,
        'guild': true,
        'admin': true
      ),
      'observer_mode': false
    ),
    "sound": array(
      'chating': false,
      'mention': true
    ),
    'is_premium': false
  )
  @players_data[@uuid]['skill'] = array(
    'skills_manager': array(
      'selected_combat_method': array(
        'name': '베기',
        'remaining': 0,
        'cooldown': 30
      ),
      'unlocked_combat_inclination_slot': 2,
      'selected_combat_inclinations': array(
        '집중 A', '집중D'
      ),
      'selected_harvesting_method': null,
      'selected_sowing_method': null
    ),
    'masteries': array(
      'combat_method': array(
        '베기': array(
          'max_level': 3,
          'level': 2,
          'max_experience': 1,
          'experience': 0,
        ),
        '치기': array(
          'max_level': 3,
          'level': 1,
          'max_experience': 1,
          'experience': 0
        ),
        '찍기': array(
          'max_level': 3,
          'level': 1,
          'max_experience': 1,
          'experience': 0
        ),
        '막기': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        )
      ),
      'combat_inclination': array(
        '저력': array(
          'level': 2
        ),
        '집중': array(
          'level': 2
        ),
        '집중 A': array(
          'level': 2
        ),
        '집중B': array(
          'level': 2
        ),
        '집중C': array(
          'level': 2
        ),
        '집중D': array(
          'level': 2
        )
      ),
      'subcombat': array(
        '활 숙련': array(
          'max_level': 3,
          'level': 1,
          'max_experience': 1,
          'experience': 0
        ),
        '석궁 숙련': array(
          'max_level': 3,
          'level': 1,
          'max_experience': 1,
          'experience': 0
        ),
        '체력 단련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
      ),
      'mining': array(
        '구리 채광 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '철 채광 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '금 채광 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '다이아몬드 채광 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '고대 파편 채광 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '선광 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '강인한 어깨': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
      ),
      'farming': array(
        '밀 농사 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '사탕무 농사 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '감자 농사 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '당근 농사 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '베리 농사 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '호박 농사 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '수박 농사 숙련': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
        '풍년': array(
          'max_level': 3,
          'level': 0,
          'max_experience': 1,
          'experience': 0
        ),
      ),
      'harvesting_method': array(
        '넓은 손': array(
          'max_level': 3,
          'level': 1,
          'max_experience': 1,
          'experience': 0
        ),
        '골든 핑거': array(
          'max_level': 3,
          'level': 1,
          'max_experience': 1,
          'experience': 0
        )
      ),
      'sowing_method': array(
        '젖은 손': array(
          'max_level': 3,
          'level': 1,
          'max_experience': 1,
          'experience': 0
        ),
        '비옥한 손길': array(
          'max_level': 3,
          'level': 1,
          'max_experience': 1,
          'experience': 0
        )
      )
    )
  )
  _save_data(@uuid, @players_data, false)
}
/*

proc _verify_request(@player, @uuid, @players_state, @players_data) {
  @player_state = array(
    'player': @player,
    'verifing': false,
    'verify_countdown': -1,
    'shifting': false,
    'guild': null,
    'guild_role': null,
    'is_op': pisop(@player)
  )
  if(array_index_exists(@players_state, @uuid)) {
    @data = array(
      'player': @player,
      'uuid': @uuid,
      'type': 'join_by_shifting' #타 서버에서 이 데이터를 받을 시 서버 이동중 상태'만!' 이동 완료 상태로 바꾸면 됨
    )
    _bungeecord_foward(@player, 'PlayerStateChangeEvent', @data)
    _verify_accept(@uuid, @players_state, @players_data)
    @players_state[@uuid] = @player_state
  } else {
    @data = array(
      'player': @player,
      'uuid': @uuid,
      'type': 'join_by_logging_in', #타 서버에서 이 데이터를 받을 시 길드 설정 및 오피 설정을 해준 값을 state로 저장함
    )
    _bungeecord_foward(@player, 'PlayerStateChangeEvent', @data)
    @players_state[@uuid] = @player_state
    @players_state[@uuid]['verifing'] = true
    @players_state[@uuid]['verify_countdown'] = 60
  }
}

proc _verify_accept(@uuid, @players_state, @players_data) {
  @players_state[@uuid]['verifing'] = false
  @players_state[@uuid]['verify_countdown'] = -1
  pogu_has('setting_data:'.@uuid, closure(@connected, @has) {
    if(@has && false) {
      _load_data(@uuid, @players_data)
    } else {
      _new_data(@uuid, @players_data)
    }
  })
}
*/
proc _send_resourcepack(@player, @uuid, @players_state) {
  @resourcepack = 'https://drive.google.com/uc?export=download&id=1wYaFx6hogY2_f5tQxYp_iKgKEo-geIOT'
  send_resourcepack(@player, @resourcepack)
  @player_state = array(
    'join_spec': array(
      'location': ploc(@player),
      'effects': get_peffect(@player),
      'health': phealth(@player),
      'hunger': phunger(@player),
      'saturation': psaturation(@player),
      'air': entity_air(@uuid),
      'fall_distance': entity_fall_distance(@uuid),
      'onfire': entity_onfire(@uuid)
    ),
  )
  @gamemode = pmode(@player)
  if(@gamemode != 'CREATIVE') {
    @gamemode = 'SURVIVAL'
  }
  @player_state['join_spec']['gamemode'] = @gamemode
  @player_state['guild'] = null
  @player_state['is_op'] = pisop(@player)
  @players_state[@uuid] = @player_state
  set_pmode(@player, 'SPECTATOR') #고정 기능 추가?
  title(@player, '§a예§7를 눌러주세요!', '§7서버 리소스팩 사용은 필수입니다.', 0, 99999999, 0)
}

proc _apply_join_spec(@player, @uuid, @players_state) {
  title(@player, '', '', 0, 1, 0)
  set_timeout(1000, closure() {
    set_ploc(@player, @players_state[@uuid]['join_spec']['location'])
    set_pmode(@player, @players_state[@uuid]['join_spec']['gamemode'])
    @effects = @players_state[@uuid]['join_spec']['effects']
    foreach(@effect in @effects) {
      set_peffect(@player, @effect['id'], @effect['strength'], @effect['seconds'], @effect['ambient'], @effect['particles'])
    }
    set_phealth(@player, @players_state[@uuid]['join_spec']['health'])
    set_phunger(@player, @players_state[@uuid]['join_spec']['hunger'])
    set_psaturation(@player, @players_state[@uuid]['join_spec']['saturation'])
    set_entity_air(@uuid, @players_state[@uuid]['join_spec']['air'])
    set_entity_fall_distance(@uuid, @players_state[@uuid]['join_spec']['fall_distance'])
    if(@players_state[@uuid]['join_spec']['onfire'] > 0) {
      set_entity_onfire(@uuid, @players_state[@uuid]['join_spec']['onfire'])
    }
  })
}

@resourcepack = 'https://drive.google.com/uc?export=download&id=1wYaFx6hogY2_f5tQxYp_iKgKEo-geIOT'
bind('player_join', null, null, @event, @players_item, @players_state, @resourcepack) {
  if(true) { #서버 봇 플레이어가 아닐시
    @player = @event['player']
    @uuid = puuid(@player)
    modify_event('join_message', null)
    if(!array_index_exists(@players_state, @uuid)) {
      _send_resourcepack(@player, @uuid, @players_state)
    }
    @players_item[@uuid] = array(
      'is_inv_open': false,
      'main_hand': null,
      'off_hand': null,
      'armor': null,
      'enchantments': array(
        'main_hand': null,
        'off_hand': null,
        'armor': null
      )
    )
    @items = array(
      'main_hand': get_inventory_item(@uuid, pheld_slot(@player)),
      'off_hand': get_inventory_item(@uuid, 40),
      'armor': get_inventory_item(@uuid, 38)
    )
    _update_item(@player, @uuid, @items, @players_item)
  }
}

foreach(@player in all_players()) { #올 플레이어에서 봇 플레이어 제외하기 _all_players 사용
  @uuid = puuid(@player)
  if(!array_index_exists(@players_state, @uuid)) {
    _send_resourcepack(@player, @uuid, @players_state)
  }
  @players_item[@uuid] = array(
    'is_inv_open': false,
    'main_hand': null,
    'off_hand': null,
    'armor': null,
    'enchantments': array(
      'main_hand': null,
      'off_hand': null,
      'armor': null
    )
  )
  @items = array(
    'main_hand': get_inventory_item(@uuid, pheld_slot(@player)),
    'off_hand': get_inventory_item(@uuid, 40),
    'armor': get_inventory_item(@uuid, 38)
  )
  _update_item(@player, @uuid, @items, @players_item)
}

bind('resource_pack_status', null,, null, @event, @players_state, @players_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  switch(@event['status']) {
  case 'DECLINED':
    pkick(@player, '리팩사용설정하세오')
    break()
  case 'SUCCESSFULLY_LOADED':
    _apply_join_spec(@player, @uuid, @players_state)
    break()
  }
}



bind('player_quit', null, null, @event, @players_state, @players_data, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_state, @uuid)) {
    array_remove(@players_state, @uuid)
  }
  /*
  if(!@players_state[@uuid]['shifting']) {
    if(array_index_exists(@players_state, @uuid)) {
      array_remove(@players_state, @uuid)
    }
    @data = array(
      'player': @player,
      'uuid': @uuid,
      'type': 'quit'
    )
    #_bungeecord_foward(@player, 'PlayerStateChangeEvent', @data)  #@player를 서버마다 배치해둔 임시 플레이어로 설정해야 함 타 서버에서 로그아웃 한 경우 포워드 읽은걸로 이 배열 지워줘야 함
  }
  */
  if(array_index_exists(@players_data, @uuid)) {
    _save_data(@uuid, @players_data, true)
  }
  if(array_index_exists(@players_item, @uuid)) {
    array_remove(@players_item, @uuid)
  }
}
/*
bind('player_command', null, null, @event, @players_state, @players_data, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(@players_state[@uuid]['verifing']) {
    cancel()
    if(@event['command'] == '/resourcepackverify') {
      @player = player(@uuid)
      tellraw(@player, array(string_multiply('\n', 100).'인증이 완료되었습니다.'))
      @data = array(
        'player': @player,
        'uuid': @uuid,
        'type': 'verify_resourcepack'
      )
      _bungeecord_foward(@player, 'PlayerStateChangeEvent', @data)
      _verify_accept(@uuid, @players_state, @players_data)
    }
  }
}
*/
proc _send_request_msg(@player, @players_state) {
  @uuid = puuid(@player)
  @message = array(
    'translate': '%1$s%3$s',
    'with': array(
      array(
        array(
          'text': string_multiply('\n', 100)
        ),
        array(
          'text': '설정된 에바참치 리소스팩을 찾을 수 없습니다!\n\n',
          'color': 'red'
        ),
        array(
          'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
          'with': array(
            array(
              'text': @players_state[@uuid]['verify_countdown'],
              'color': 'yellow'
            )
          ),
          'color': 'white'
        ),
        array(
          'text': '리소스팩을 설정한 후, 채팅메시지를 클릭해주세요.\n'
        ),
        array(
          'text': '리소스팩을 다운로드하려면 이 채팅메시지를 클릭해주세요.',
          'underlined': true,
          'color': 'gray',
          'clickEvent': array(
            'action': 'open_url',
            'value': 'https://evatuna.fish/'
          )
        ),
      ),
      array(
        'translate': '%1$s%4$s',
        'with': array(
          array(
            array(
              'text': string_multiply('\n', 100)
            ),
            array(
              'text': '에바참치 리소스팩의 업데이트가 필요합니다!\n\n',
              'color': 'red'
            ),
            array(
              'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
              'with': array(
                array(
                  'text': @players_state[@uuid]['verify_countdown'],
                  'color': 'yellow'
                )
              ),
              'color': 'white'
            ),
            array(
              'text': '최신 버전으로 리소스팩을 설정한 후, 채팅메시지를 클릭해주세요.\n'
            ),
            array(
              'text': '최신 버전의 리소스팩을 다운로드하려면 이 채팅메시지를 클릭해주세요.',
              'underlined': true,
              'color': 'gray',
              'clickEvent': array(
                'action': 'open_url',
                'value': 'https://evatuna.fish/'
              )
            )
          ),
          array(
            array(
              'text': string_multiply('\n', 100)
            ),
            array(
              'text': '최신 버전의 에바참치 리소스팩이 확인되었습니다\n\n',
              'color': 'green'
            ),
            array(
              'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
              'with': array(
                array(
                  'text': @players_state[@uuid]['verify_countdown'],
                  'color': 'yellow'
                )
              ),
              'color': 'white'
            ),
            array(
              'text': '이 채팅메시지를 클릭할 시, 인증이 완료됩니다.',
              'underlined': true,
              'color': 'gray',
              'clickEvent': array(
                'action': 'run_command',
                'value': '/resourcepackverify'
              )
            )
          )
        )
      )
    ),
  )
  tellraw(@player, @message)
}

@interval_task = set_interval(1000, closure() {
  #broadcast(@players_state)
  foreach(@player in all_players()) {
    @uuid = puuid(@player)
    /* 
    if(array_index_exists(@players_data, @uuid)) {
      _send_action_msg(@player, @players_data[@uuid], @text)
    } else {
      if(@players_state[@uuid]['verifing']) {
        if(@players_state[@uuid]['verify_countdown'] > 0) {
          _send_request_msg(@player, @players_state)
          @players_state[@uuid]['verify_countdown'] -= 1
        } else {
          if(@players_state[@uuid]['verify_countdown'] != -1) {
          @players_state[@uuid]['verify_countdown'] -= 1 #인증 서버기준 데이터 설정
          #인증 서버 이동으로 대채 예정
          pkick(@player, '리소스팩 설정 후, 다시 접속하여 인증해 주세요!')
          }
        }
      }
    }
    
    switch(@players_item[@uuid]['enchantments']['armor']) {
    case '날렵함':
      break()
    case '심안':
      set_peffect(@player, 'NIGHT_VISION', 0, 16.5, false, true)
      @effects = get_peffect(@player)
      if(array_index_exists(@effects, 'blindness')) {
        set_peffect(@player, 'BLINDNESS', 0, 0, false, true)
      }
      if(array_index_exists(@effects, 'nausea')) {
        set_peffect(@player, 'NAUSEA', 0, 0, false, true)
      }
      break()
    default:

      #broadcast(A) #/summon minecraft:experience_orb ~ ~ ~ {Value:10}
    }
    */
  }
})

@cron_task = set_cron('*/1 * * * *', closure() {
  foreach(@player in all_players()) {
    @uuid = @player
    if(import('state.'@uuid) == 'none') {
      if(array_index_exists(@players_data, @uuid)) {
        _save_data(@uuid, @players_data, false)
      }
    }
  }
})

bind('plugin_message_received', null, array('channel': 'BungeeCord'), @event, @players_state) {
  foreach(@key: @byte in @event['bytes']) {
    if(@key != 0) {
      if(@byte == 0) {
        @subchannel_size = @key - 2
        break()
      }
    }
  }
  @data = array(
    'subchannel': string(ba_get_bytes(@event['bytes'], @subchannel_size, 2)),
    'value': json_decode(string(ba_get_bytes(@event['bytes'], array_size(@event['bytes']) - @subchannel_size - 6, @subchannel_size + 6)))
  )
  broadcast(@data)
  switch(@data['subchannel']) {
  case 'PlayerStateChangeEvent':
    @player = @data['value']['player']
    @uuid = @data['value']['uuid']
    switch(@data['value']['type']) {
    case 'join_by_logging_in':
      @players_state[@uuid] = array(
        'player': @player,
        'verifing': true,
        'verify_countdown': -1,
        'shifting': false,
        'guild': null,
        'guild_role': null,
        'is_op': pisop(@player)
      )
      break()
    case 'verify_resourcepack':
      @players_state[@uuid] = array(
        'player': @player,
        'verifing': false,
        'verify_countdown': -1,
        'shifting': false,
        'guild': null,
        'guild_role': null,
        'is_op': pisop(@player)
      )
      break()
    case 'shift':
      @players_state[@uuid] = array(
        'player': @player,
        'verifing': false,
        'verify_countdown': -1,
        'shifting': true,
        'guild': null,
        'guild_role': null,
        'is_op': pisop(@player)
      )
      break()
    case 'join_by_shifting':
      @players_state[@uuid] = array(
        'player': @player,
        'verifing': false,
        'verify_countdown': -1,
        'shifting': false,
        'guild': null,
        'guild_role': null,
        'is_op': pisop(@player)
      )
      break()
    case 'quit':
      array_remove(@players_state, @uuid)
      break()
    }
    break()
  case 'PlayerChatEvent':
    break()
  }
}