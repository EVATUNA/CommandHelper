console('EvaData loaded')

## Data Procedure
proc _load_data(@player, @uuid, @players_data, @skills_spec, @text) {
  # cache (cup에 저장 x)
  @players_data[@uuid]['cache'] = array(
    'resolution_setting': false
  )
  # setting (cup에 저장)
  @players_data[@uuid]['setting'] = cup_get('SETTING', @uuid)
  if(is_null(@players_data[@uuid]['setting'])) {
    _new_data(@uuid, @players_data)
  }
  # skill (cup에 저장)
  _load_skills(@uuid, @players_data, @skills_spec)
  # item (cup에 저장 x)
  @players_data[@uuid]['item'] = array(
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
  _update_item(@player, @uuid, @items, @players_data, @skills_spec, @text)
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
  @resourcepack = 'https://drive.google.com/uc?export=download&id=1WDSOp3NGhZGfy6OhzGPOuY1qFa8tzs4l'
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
  set_pmode(@player, 'SPECTATOR')
  title(@player, '§a예§7를 눌러주세요!', '§7서버 리소스팩 사용은 필수입니다.', 0, 99999999, 0)
}

proc _apply_join_spec(@player, @uuid, @players_state, @players_data, @skills_spec, @text) {
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
    _set_player_state(@player, @uuid, @players_state, @players_data, @skills_spec, @text)
  })
}

proc _set_player_state(@player, @uuid, @players_state, @players_data, @skills_spec, @text) {
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
  _bungeecord_foward(@player, 'ch_update_state', @data)
  # players_data
  _load_data(@player, @uuid, @players_data, @skills_spec, @text)
}

proc _join_event(@player, @uuid, @players_state, @players_data, @server, @bots, @skills_spec, @text) {
  if(!array_contains(@bots, @player)) {
    if(!array_index_exists(@players_state, @uuid)) {
      _send_resourcepack(@player, @uuid, @players_state)
    } else {
      set_timeout(500, closure() {
        _set_player_state(@player, @uuid, @players_state, @players_data, @skills_spec, @text)
      })
    }
  } else {
    #if(!array_contains(@server['bots'], @player)) {
      @server['bots'][] = @player
      if(!@server['loaded']) {
        @server['loaded'] = true
        @data = array('request_bot': @player)
        _bungeecord_foward(@server['bots'][0], 'ch_request_states', @new_data)
      }
    #}
  }
}

proc _quit_event(@player, @uuid, @players_state, @server, @bots) {
  if(!array_contains(@bots , @player)) {
    if(array_index_exists(@players_state, @uuid)) {
      @players_state[@uuid]['quit_countdown'] = 10
    }
  } else {
    if(array_contains(@server['bots'], @player)) {
      array_remove(@server['bots'], @player)
    }
  }
}

# EVENT / TASK BINDER

foreach(@player in _all_players(@bots)) { #조인 이벤트로 변경 리로드 명령어
  @uuid = puuid(@player)
  set_timeout(1000, closure() {
    _set_player_state(@player, @uuid, @players_state, @players_data, @skills_spec, @text) 
  })
}

bind('player_join', null, null, @event, @players_state, @players_data, @server, @bots, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('join_message', null)
  _join_event(@player, @uuid, @players_state, @players_data, @server, @bots, @skills_spec, @text)
}

bind('resource_pack_status', null,, null, @event, @players_state, @players_data, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  switch(@event['status']) {
  case 'DECLINED':
    pkick(@player, hexcolor('#ff4040').'§l서버 리소스팩을 사용하도록 설정해 주시기 바랍니다.\n'.hexcolor('#c0c0c0').'§l에바참치 서버를 선택한 후, 수정 버튼을 눌러\n서버 리소스팩을 사용으로 설정해 주세요.\n\n'.hexcolor('#ffff80').'§l버그 문의: ')
    break()
  case 'SUCCESSFULLY_LOADED':
    _apply_join_spec(@player, @uuid, @players_state, @players_data, @skills_spec, @text)
    break()
  }
}

bind('player_quit', null, null, @event, @players_state, @players_data, @server, @bots) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('message', null)
  _quit_event(@player, @uuid, @players_state, @server, @bots)
}

@interval_task = set_interval(1000, closure() { #bungee 완전 로그아웃
  foreach(@uuid: @player_state in @players_state) {
    if(array_index_exists(@players_state[@uuid], 'quit_countdown')) {
      if(@players_state[@uuid]['quit_countdown'] > 0) {
        @players_state[@uuid]['quit_countdown'] -= 1
      } else if(@players_state[@uuid]['quit_countdown'] == 0) {
        if(array_index_exists(@players_data, @uuid)) {
          array_remove(@players_data, @uuid)
        }
        if(array_index_exists(@players_state, @uuid)) {
          array_remove(@players_state, @uuid)
        }
        @data = array('uuid': @uuid)
        _bungeecord_foward(@server['bots'][0], 'ch_remove_state', @data) #@player 봇으로 대체하기 
      } else {
        @player = @player_state['player']
        if(array_index_exists(@players_data, @uuid)) {
          _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
          #_countdown_skill() {}로 아래 코드 대체
          
          #combat_combat_inclination
          @category = 'combat_inclination'
          foreach(@skill in json_decode(@players_data[@uuid]['skill_manager'][0])) {
            #broadcast(@skill)
          }

          #combat_method
          @category = 'combat_method'
          @skill = @players_data[@uuid]['skill_manager'][2]
          
          if(@skill != '') {
            @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
            @active_skill = @players_data[@uuid]['active_skill'][@category][@skill]
            switch(@skill) {
            case 'sweeping':
              if(@active_skill[2] != 1) {
                if(@active_skill[1] > 0) {
                  @active_skill[1] -= 1
                  if(@active_skill[1] == 0) {
                    @active_skill[0] = @skills_spec['combat_method'][@skill]['levels'][@level]['active']['cooldown']
                    remove_entity_attribute_modifier(@uuid, 'GENERIC_ATTACK_SPEED', 'sweeping_active')
                  }
                } else {
                  if(@active_skill[0] > 0) {
                    @active_skill[0] -= 1
                  } else {
                    @active_skill[2] = 1
                  }
                }
              }
              break()
            case 'knockback':
              if(@active_skill[2] < 3) { #최대 갯수보다 충전 갯수 작을 시
                if(@active_skill[0] > 0) {
                  @active_skill[0] -= 1
                } else {
                  @active_skill[2] += 1
                }
              }
              break()
            case 'cleaving':
              if(@active_skill[2] != 1) {
                if(@active_skill[1] > 0) {
                  @active_skill[1] -= 1
                  if(@active_skill[1] == 0) {
                    #지속시간 종료
                  }
                } else {
                  if(@active_skill[0] > 0) {
                    @active_skill[0] -= 1
                  } else {
                    @active_skill[2] = 1
                  }
                }
              }
              break()
            #case 'blocking':
            #  break()
            }
          }

          #harvesting_method
          @category = 'harvesting_method'
          @skill = @players_data[@uuid]['skill_manager'][3]
          
          if(@skill != '') {
            @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
            @active_skill = @players_data[@uuid]['active_skill'][@category][@skill]
            #broadcast(@category @skill @active_skill)
            if(@active_skill[2] != 1) {
              if(@active_skill[1] > 0) {
                @active_skill[1] -= 1
                if(@active_skill[1] == 0) {
                  #지속시간 종료
                }
              } else {
                if(@active_skill[0] > 0) {
                  @active_skill[0] -= 1
                } else {
                  @active_skill[2] = 1
                }
              }
            }
          }

          #sowing_method
          @category = 'sowing_method'
          @skill = @players_data[@uuid]['skill_manager'][4]
          
          if(@skill != '') {
            @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
            @active_skill = @players_data[@uuid]['active_skill'][@category][@skill]
            if(@active_skill[2] != 1) {
              if(@active_skill[1] > 0) {
                @active_skill[1] -= 1
                if(@active_skill[1] == 0) {
                  #지속시간 종료
                }
              } else {
                if(@active_skill[0] > 0) {
                  @active_skill[0] -= 1
                } else {
                  @active_skill[2] = 1
                }
              }
            }
          }

          switch(@players_data[@uuid]['item']['enchantments']['armor']) {
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
  #broadcast('state - '@players_state)
  #broadcast('data - '@players_data)
})

bind('plugin_message_received', null, array('channel': 'BungeeCord'), @event, @players_state, @players_data, @bots) {
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
  broadcast(@data)
  switch(@data['identifier']) {
  
  #                          A B서버에서 요청받음 B로 데이터 보내기
  #                        /                                        \
  # B 요청 보냄 (모든서버)                                            B 데이터 받음
  #                        \                                        /
  #                          C B서버에서 요청받음 B로 데이터 보내기

  # B 서버 로드,                      B서버에서 A서버로 데이터 리퀘스트
  # A서버에서 데이터 리퀘스트 받음    A서버에서 B서버로 데이터 전송
  # B서버에서 데이터 받음             B서버에선 받은 데이터 반영

  case 'ch_request_states':
    @request_bot = @data['request_bot']
    @new_data = array()
    foreach(@uuid: @player_state in @players_state) {
      if(array_index_exists(@player_state, 'quit_countdown')) {
        @player = player(@uuid)
        @new_data[@uuid] = array(
          'player': @player['player'],
          'is_op': @player_state['is_op'],
          'guild': @player_state['guild']
        )
      }
    }
    _bungeecord_foward_to_bot(@server_bot, @request_bot 'ch_update_states', @new_data)
    break()
  case 'ch_update_states':
    foreach(@uuid: @player_state in @data['value']) {
      @players_state[@uuid] = @player_state
    }
    break()
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
  case 'ch_chat': #todo 리팩토링, 
    @sender = @data['value']['player']
    foreach(@receiver in _all_players(@bots)) {
      if(array_contains(@data['value']['mentioned_players'], @receiver)) {
        play_named_sound(ploc(@receiver), array('sound': 'message.mention', 'category': 'master', 'volum': 100), array(@receiver))
      }
      play_named_sound(ploc(@receiver), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver))
      _tellraw(@receiver, @raw)
    }
    break()
  }
}

bind('block_break', null, null, @event, @players_data, @hp_blocks, @crops_spec) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(pmode(@player) == 'SURVIVAL') {
    @player_data = @players_data[@uuid]
    @is_farming_allowed = true
    if(@is_farming_allowed) {
      _crop_mine_event(@event, @player, @uuid, @player_data, @crops_spec)
    }
    @is_mining_allowed = true
    if(@is_mining_allowed && array_contains(array('COAL_ORE', 'COPPER_ORE', 'GOLD_ORE', 'IRON_ORE', 'REDSTONE_ORE', 'LAPIS_ORE', 'DIAMOND_ORE', 'EMERALD_ORE', 'ANCIENT_DEBRIS'), @event['block'])) {
      @player_mining_skills = @players_data[@uuid]['skill_data']['mining']
      _mineral_mine_event(@event, @player_item, @player_mining_skills, @hp_blocks)
    }
  }
}

bind('player_interact', null, null, @event, @players_data, @hp_blocks) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(pmode(@player) == 'SURVIVAL') {
    @player_data = @players_data[@uuid]
    @is_sowing_allowed = true
    if(@is_sowing_allowed) {
      _farmland_sow_event(@event, @player, @uuid, @player_item, @hp_blocks)
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
        @uuid = puuid(@player)
        mom_playerparticle(@uuid, 'VILLAGER_HAPPY', @pos['x'], @pos['y'], @pos['z'], 15, @delta['x'], @delta['y'], @delta['z'], 0.0)
        #_particle(@player, 'happy_villager', @pos, @delta, 0, 15)
        set_timeout(0, closure( set_blockdata(@event['location'], @data) ))
      } else {
        cancel()
      }
    }
    # watering
    if(!is_null(@event['item']) && @event['item']['name'] == 'POTION' && @event['item']['meta']['base']['type'] == 'WATER') {
      if(array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'ATTACHED_PUMPKIN_STEM', 'ATTACHED_MELON_STEM', 'SWEET_BERRY_BUSH'), @event['block'])) {
        @event['location']['y'] -= 1
        @is_farmland = true
        cancel()
      } else if(@event['block'] == 'FARMLAND') {
        @is_farmland = true
        cancel()
      } else {
        @is_farmland = false
      }
      if(@is_farmland) {
        @data = get_blockdata(@event['location'])
        play_named_sound(@event['location'], array('sound': 'minecraft:item.bottle.empty', 'category': 'NEUTRAL', 'volum': 1))
        @data['moisture'] = 6
        set_blockdata(@event['location'], @data)
        if(@event['hand'] =='main_hand') {
          @slot = pheld_slot(@player)
        } else {
          @slot = 40
        }
        @event['item']['qty'] -= 1
        if(pmode(@player) != 'CREATIVE') {
          if(@event['item']['qty'] > 0) {
            set_inventory_item(@uuid, @slot, @event['item'])
            pgive_item(@player, array('name': 'GLASS_BOTTLE'))
          } else {
            set_inventory_item(@uuid, @slot, array('name': 'GLASS_BOTTLE'))
          }
        }
      }
    }
  }

  #broadcast(@event)
  if(!is_null(@event['item']) && @event['item']['name'] == 'ENCHANTED_BOOK' && !is_null(@event['item']['meta']) && !is_null(@event['item']['meta']) && @event['item']['meta']['model'] > 0) {

    #broadcast(A)
    #take_from_inventory(@uuid, 'PAPER', 1)
  }
}

bind('block_grow', null, null, @event) {
  if(array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'SWEET_BERRY_BUSH'), @event['block'])) {
    if(get_blockdata(@event['location'])['age'] > 0) {
      if((has_storm(@event['location']['world']) || has_thunder(@event['location']['world'])) && @event['location'] == get_highest_block_at(@event['location'])) {
      
      } else {
        @under_location = array('x': @event['location']['x'], 'y': @event['location']['y'] - 1, 'z': @event['location']['z'], 'world': @event['location']['world'])
        if(get_block(@under_location) == 'FARMLAND') {
          @data = get_blockdata(@under_location)
          if(@data['moisture'] > 0) {
            @data['moisture'] -= rand(1, 3)
            if(@data['moisture'] < 0) { @data['moisture'] = 0}
            set_blockdata(@under_location, @data)
          } else {
            cancel()
          }
        } else {
          cancel()
        }
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