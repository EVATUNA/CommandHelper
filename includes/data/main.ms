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
    )
  )
  @gamemode = pmode(@player)
  if(@gamemode != 'CREATIVE') {
    @gamemode = 'SURVIVAL'
  }
  @player_state['join_spec']['gamemode'] = @gamemode
  @players_state[@uuid] = @player_state
  set_pmode(@player, 'SPECTATOR') #고정 기능 추가?
  title(@player, '§a예§7를 눌러주세요!', '§7서버 리소스팩 사용은 필수입니다.', 0, 99999999, 0)
}

proc _set_player_state(@player, @uuid, @players_state) {
  @player_state = array(
    'player': @player,
    'is_op': pisop(@player),
    'quit_countdown': -1
  )
  @player_state['guild'] = null
  @players_state[@uuid] = @player_state
  @data = array(
    'player': @player,
    'uuid': @uuid,
    'is_op': @player_state['is_op'],
    'guild': @player_state['guild']
  )
  _bungeecord_foward(@player, 'update_state', @data)
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
    array_remove(@players_state[@uuid], 'join_spec')
    _set_player_state(@player, @uuid, @players_state)
  })
}

bind('player_join', null, null, @event, @players_item, @players_state) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('join_message', null)
  if(!array_contains(array('LopLove', '1L_Bottle') , @player)) {
    if(!array_index_exists(@players_state, @uuid)) {
      _send_resourcepack(@player, @uuid, @players_state)
    } else {
      set_timeout(500, closure() {
        _set_player_state(@player, @uuid, @players_state) 
      })
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
  if(!array_contains(array('LopLove', '1L_Bottle') , @player)) {
    _set_player_state(@player, @uuid, @players_state)
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
  modify_event('quit_message', null)
  if(!array_contains(array('LopLove', '1L_Bottle') , @player)) {
    if(array_index_exists(@players_state, @uuid)) {
      @players_state[@uuid]['quit_countdown'] = 10
    }
    if(array_index_exists(@players_item, @uuid)) {
      array_remove(@players_item, @uuid)
    }
  }
}


@interval_task = set_interval(1000, closure() {
  broadcast('§7'.@players_state)
  foreach(@uuid: @player_state in @players_state) {
    if(array_index_exists(@players_state[@uuid], 'quit_countdown')) {
      if(@players_state[@uuid]['quit_countdown'] > 0) {
        @players_state[@uuid]['quit_countdown'] -= 1
      } else if(@players_state[@uuid]['quit_countdown'] == 0) {
        array_remove(@players_state, @uuid)
        @data = array('uuid': @uuid)
        _bungeecord_foward(@player, 'remove_state', @data)
      } else {
        #broadcast(@player_state)
        @player = @player_state['player']
        if(array_index_exists(@players_data, @uuid)) {
          _send_action_msg(@player, @players_data[@uuid], @text)
          
          #_countdown_skill() {}로 아래 코드 대체
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
          ###

        }
      }
    }
  }
})

#@cron_task = set_cron('*/1 * * * *', closure() {
#  foreach(@player in all_players()) {
#    @uuid = puuid(@player)
#  }
#})

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
  broadcast(AAA @data)
  switch(@data['subchannel']) {
  case 'update_state':
    @players_state[@data['value']['uuid']] = array(
      'player': @data['value']['player'],
      'is_op': @data['value']['is_op'],
      'guild': @data['value']['guild']
    )
    break()
  case 'remove_state':
    array_remove(@players_state, @data['value']['uuid'])
    break()
  case 'chat':
    break()
  }
}