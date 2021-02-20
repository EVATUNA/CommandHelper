console('EvaData loaded')

## Data Procedure

proc _load_data(@uuid, @players_data, @skills_spec) {
  @players_data[@uuid]['setting'] = cup_get('SETTING', @uuid)
  if(is_null(@players_data[@uuid]['setting'])) {
    _new_data(@uuid, @players_data)
  }
  _load_skills(@uuid, @players_data, @skills_spec)
}

proc _new_data(@uuid, @players_data) {
  @players_data[@uuid]['setting'] = array(
    'general',
    false,
    'default',
    'default',
    true,
    true,
    true,
    true,
    false,
    true,
    true,
    '',
    427,
    true
  )
  cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
}

proc _send_resourcepack(@player, @uuid, @players_state) {
  @resourcepack = 'https://drive.google.com/uc?export=download&id=1n3aRXulikDxw-Ow5cbE6UmT9yqCuBebY'
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

proc _apply_join_spec(@player, @uuid, @players_state, @players_data, @skills_spec) {
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
    _set_player_state(@player, @uuid, @players_state, @players_data, @skills_spec)
  })
}

proc _set_player_state(@player, @uuid, @players_state, @players_data, @skills_spec) { # bungee
  #players_state
  @player_state = array(
    'player': @player,
    'is_op': pisop(@player),
    'quit_countdown': -1
  )
  @player_state['guild'] = null
  @players_state[@uuid] = @player_state
  # bungee
  @data = array(
    'player': @player,
    'uuid': @uuid,
    'is_op': @player_state['is_op'],
    'guild': @player_state['guild']
  )
  #_bungeecord_foward(@player, 'ch_update_state', @data)
  # players_data
  _load_data(@uuid, @players_data, @skills_spec)
}

proc _join_event(@player, @uuid, @players_state, @players_data, @players_item, @excluded_players, @skills_spec) {
  if(!array_contains(@excluded_players , @player)) {
    broadcast(@players_state)
    if(!array_index_exists(@players_state, @uuid)) {
      _send_resourcepack(@player, @uuid, @players_state)
    } else {
      set_timeout(500, closure() {
        _set_player_state(@player, @uuid, @players_state, @players_data, @skills_spec)
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

proc _quit_event(@player, @uuid, @players_state, @players_item, @excluded_players) {
  if(!array_contains(@excluded_players , @player)) {
    if(array_index_exists(@players_state, @uuid)) {
      @players_state[@uuid]['quit_countdown'] = 10
    }
    if(array_index_exists(@players_item, @uuid)) {
      array_remove(@players_item, @uuid)
    }
  }
}

# EVENT / TASK BINDER
foreach(@player in _all_players(@excluded_players)) { #조인 이벤트로 변경 리로드 명령어
  @uuid = puuid(@player)
  _set_player_state(@player, @uuid, @players_state, @players_data, @skills_spec) 
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

bind('player_join', null, null, @event, @players_state, @players_data, @players_item, @excluded_players, @skills_spec) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('join_message', null)
  _join_event(@player, @uuid, @players_state, @players_data, @players_item, @excluded_players)
}

bind('resource_pack_status', null,, null, @event, @players_state, @players_data, @skills_spec) {
  @player = @event['player']
  @uuid = puuid(@player)
  switch(@event['status']) {
  case 'DECLINED':
    pkick(@player, '리팩사용설정하세오') #todo 더 세세한 설명
    break()
  case 'SUCCESSFULLY_LOADED':
    _apply_join_spec(@player, @uuid, @players_state, @players_data, @skills_spec)
    break()
  }
}

bind('player_quit', null, null, @event, @players_state, @players_data, @players_item, @excluded_players) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('message', null)
  _quit_event(@player, @uuid, @players_state, @players_item, @excluded_players)
}

@interval_task = set_interval(1000, closure() { #bungee 완전 로그아웃
  foreach(@uuid: @player_state in @players_state) {
    if(array_index_exists(@players_state[@uuid], 'quit_countdown')) {
      if(@players_state[@uuid]['quit_countdown'] > 0) {
        @players_state[@uuid]['quit_countdown'] -= 1
      } else if(@players_state[@uuid]['quit_countdown'] == 0) {
        array_remove(@players_state, @uuid)
        @data = array('uuid': @uuid)
        #_bungeecord_foward(@player, 'ch_remove_state', @data)
      } else {
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

@cron_task = set_cron('*/1 * * * *', closure() {
  foreach(@id: @hp_block in @hp_blocks) {
    if(@hp_block['reset_countdown'] > 0) {
      @hp_block['reset_countdown'] -= 1
    } else {
      array_remove(@hp_blocks, @id)
    }
    #broadcast(@hp_block)
  }
})

bind('plugin_message_received', null, array('channel': 'BungeeCord'), @event, @players_state, @players_data, @excluded_players) {
  foreach(@key: @byte in @event['bytes']) {
    if(@key != 0) {
      if(@byte == 0) {
        @identifier_size = @key - 2
        break()
      }
    }
  }
  @data = array(
    'identifier': string(ba_get_bytes(@event['bytes'], @identifier_size, 2)),
    'value': json_decode(string(ba_get_bytes(@event['bytes'], array_size(@event['bytes']) - @identifier_size - 6, @identifier_size + 6)))
  )
  switch(@data['identifier']) {
  case 'ch_update_state':
    @players_state[@data['value']['uuid']] = array(
      'player': @data['value']['player'],
      'is_op': @data['value']['is_op'],
      'guild': @data['value']['guild']
    )
    break()
  case 'ch_remove_state':
    array_remove(@players_state, @data['value']['uuid'])
    break()
  case 'ch_chat':
    @sender = @data['value']['player']
    foreach(@receiver in _all_players(@excluded_players)) {
      if(array_contains(@data['value']['mentioned_players'], @receiver)) {
        play_named_sound(ploc(@receiver), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver))
      }
      play_named_sound(ploc(@receiver), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver))
      _tellraw(@receiver, @raw)
    }
    break()
  }
}

bind('block_break', null, null, @event, @players_data, @players_item, @hp_blocks) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(pmode(@player) == 'SURVIVAL') {
    @player_item = @players_item[@uuid]
    # mining
    @is_mining_allowed = true
    if(@is_mining_allowed && array_contains(array('COAL_ORE', 'COPPER_ORE', 'GOLD_ORE', 'IRON_ORE', 'REDSTONE_ORE', 'LAPIS_ORE', 'DIAMOND_ORE', 'EMERALD_ORE', 'ANCIENT_DEBRIS'), @event['block'])) {
      @player_mining_skills = @players_data[@uuid]['skill']['masteries']['mining']
      _mineral_mine_event(@event, @player_item, @player_mining_skills, @hp_blocks)
    }
    # farming
    @is_farming_allowed = true
    if(@is_mining_allowed && array_contains(array('WHEAT', 'CARROTS', 'POTATOS', 'BEETROOTS', 'SWEET_BERRIES', 'PUMPKIN', 'MELON'), @event['block'])) {
      @player_farming_skills = @players_data[@uuid]['skill']['masteries']['farming']
      _crop_break_event(@event, @player_item, @player_farming_skills, @hp_blocks)
    }
  }
}

bind('player_interact', null, null, @event, @players_data, @players_item, @hp_blocks) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(pmode(@player) == 'SURVIVAL') {
    @player_item = @players_item[@uuid]
    # set_entity_glowing
    @is_sowing_allowed = true
    if(@is_sowing_allowed && !is_null(@event['item']) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @event['item']['name']) && @event['action'] == 'right_click_block' && array_contains(array('GRASS_BLOCK', 'DIRT'), @event['block']) && array_index_exists(@event, 'location') && array_contains(array('AIR', 'CAVE_AIR', 'VOID_AIR'), get_block(array('x': @event['location']['x'], 'y': @event['location']['y'] + 1, 'z': @event['location']['z'], 'world': @event['location']['world'])))) {
      @farming_skills = @players_data[@uuid]['skill']['masteries']['mining']
      @sowing_method_skills = @players_data[@uuid]['skill']['masteries']['sowing_method']
      _farmland_sow_event(@event, @player_item, @farming_skills, @sowing_method_skills, @hp_blocks)
    }

  }
  if(@event['action'] == 'right_click_block') {
    # cancel right click harvest berry
    if(@event['block'] == 'SWEET_BERRY_BUSH') {
      @data = get_blockdata(@event['location'])
      if(@data['age'] >= 2 && (!psneaking(@player) || is_null(@event['item'])) ) {
        cancel()
      }
    }
    # cancel bone mealing
    if(!is_null(@event['item']) && @event['item']['name'] == 'BONE_MEAL' && array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'SWEET_BERRY_BUSH'), @event['block'])) {
      @data = get_blockdata(@event['location'])
      if(@data['age'] == 0) {
        @data['age'] = 1
        cancel()
        @pos = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.2, 'z': @event['location']['z'] + 0.5)
        @delta = array('x': 0.25, 'y': 0.125, 'z': 0.25)
        _particle(@player, 'happy_villager', @pos, @delta, 0, 15)
        set_timeout(0, closure( set_blockdata(@event['location'], @data) ))
      } else {
        cancel()
      }
    }
  }
}

bind('block_grow', null, null, @event) {
  if(array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'SWEET_BERRY_BUSH'), @event['block'])) {
    if(get_blockdata(@event['location'])['age'] > 0) {
      @under_location = array('x': @event['location']['x'], 'y': @event['location']['y'] - 1, 'z': @event['location']['z'], 'world': @event['location']['world'])
      if(get_block(@under_location) == 'FARMLAND') {
        @data = get_blockdata(@under_location)
        if(@data['moisture'] > 0) { # || @data['moisture'] == 7
          @data['moisture'] -= rand(0, 3)
          if(@data['moisture'] < 0) { @data['moisture'] = 0}
          set_blockdata(@under_location, @data)
        } else {
          cancel()
        }
      } else {
        cancel()
      }
    } else {
      cancel()
    }
  }
}

bind('block_fade', null, null, @event) {
  if(@event['block'] == 'FARMLAND') {
    @upper_location = array('x': @event['location']['x'], 'y': @event['location']['y'] + 1, 'z': @event['location']['z'], 'world': @event['location']['world'])
    if(!get_block_info(@upper_location, 'solid')) {
      cancel()
    }
  }
}