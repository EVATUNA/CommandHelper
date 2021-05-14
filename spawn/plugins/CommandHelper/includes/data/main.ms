console('EvaData loaded')

## Data Procedure
proc _load_data(@player, @uuid, @players_data, @skills_spec, @text) {
  @players_data[@uuid]['cache'] = array(
    'resolution_setting': false,
    'last_weapon_effect': 0,
    'last_armor_effect': 0,
    'indicator': null,
    'tips': array()
  )
  @players_data[@uuid]['setting'] = cup_get('SETTING', @uuid)
  if(is_null(@players_data[@uuid]['setting'])) {
    _new_data(@uuid, @players_data)
  }
  _load_skills(@uuid, @players_data, @skills_spec)
  @bossbars = get_bars()
  @indicator_id = 'indicator.'.@uuid
  @tip_id = 'tip.'.@uuid
  if(array_contains(@bossbars, @indicator_id)) {
    remove_bar(@indicator_id)
  }
  @indicator_bossbar_data = array(
    'title': '',
    'percent': 0
  )
  create_bar(@indicator_id, @indicator_bossbar_data)
  bar_add_player(@indicator_id, @player)
  if(!array_contains(@bossbars, @tip_id)) {
    @tip_bossbar_data = array(
      'title': '',
      'percent': 0
    )
    create_bar(@tip_id, @tip_bossbar_data)
  }
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
    'armor': get_inventory_item(@uuid, 36)
  )
  _update_item(@player, @uuid, @items, @players_data, @skills_spec, @text)
}

proc _new_data(@uuid, @players_data) {
  @players_data[@uuid]['setting'] = array(
    'default',
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
    array('\ue4e3', '\ue4e4', '\ue4e5', '\ue4e6')[rand(0, 4)], #테스트 코드
    427,
    true
  )
  cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
}

proc _send_resourcepack(@player, @uuid, @players_data, @skills_spec, @text, @server) {
  @join_spec = array(
    'location': ploc(@player),
    'effects': get_peffect(@player),
    'health': phealth(@player),
    'hunger': phunger(@player),
    'saturation': psaturation(@player),
    'air': entity_air(@uuid),
    'fall_distance': entity_fall_distance(@uuid),
    'onfire': entity_onfire(@uuid),
    'gamemode': pmode(@player)
  )
  if(@join_spec['gamemode'] != 'CREATIVE') {
    @join_spec['gamemode'] = 'SURVIVAL'
  }
  set_pmode(@player, 'SPECTATOR')
  send_resourcepack(@player, @server['resourcepack'])
  title(@player, '§a예§7를 눌러주세요!', '§7서버 리소스팩 사용은 필수입니다.', 0, 99999999, 0)
  @resource_pack_event_id = 'pack_download_checker.'.@uuid
  if(has_bind(@resource_pack_event_id)) { unbind(@resource_pack_event_id) }
  bind('resource_pack_status', array('id': @resource_pack_event_id), array('player': @player), @event, @player, @uuid, @join_spec, @players_data, @skills_spec, @text) {
    switch(@event['status']) {
    case 'DECLINED':
      pkick(@player, hexcolor('#ff4040').'§l서버 리소스팩을 사용하도록 설정해 주시기 바랍니다.\n'.hexcolor('#c0c0c0').'§l에바참치 서버를 선택한 후, 수정 버튼을 눌러\n서버 리소스팩을 사용으로 설정해 주세요.\n\n'.hexcolor('#ffff80').'§l버그 문의: ')
      unbind()
      break()
    case 'SUCCESSFULLY_LOADED':
      _apply_join_spec(@player, @uuid, @join_spec, @players_data, @skills_spec, @text)
      unbind()
      break()
    }
  }
}

proc _apply_join_spec(@player, @uuid, @join_spec, @players_data, @skills_spec, @text) {
  title(@player, '', '', 0, 1, 0)
  set_timeout(1000, closure() {
    set_ploc(@player, @join_spec['location'])
    set_pmode(@player, @join_spec['gamemode'])
    foreach(@effect in @join_spec['effects']) {
      set_peffect(@player, @effect['id'], @effect['strength'], @effect['seconds'], @effect['ambient'], @effect['particles'])
    }
    set_phealth(@player, @join_spec['health'])
    set_phunger(@player, @join_spec['hunger'])
    set_psaturation(@player, @join_spec['saturation'])
    set_entity_air(@uuid, @join_spec['air'])
    set_entity_fall_distance(@uuid, @join_spec['fall_distance'])
    if(@join_spec['onfire'] > 0) {
      set_entity_onfire(@uuid, @join_spec['onfire'])
    }
    _load_data(@player, @uuid, @players_data, @skills_spec, @text)
  })
}

proc _join_event(@player, @uuid, @reconnectable_players, @players_data, @bots, @skills_spec, @text, @server) {
  if(!array_contains(@bots, @uuid)) {
    if(!array_index_exists(@reconnectable_players, @uuid)) {
      _send_resourcepack(@player, @uuid, @players_data, @skills_spec, @text, @server)
    } else {
      #set_timeout(500, closure() {
        _load_data(@player, @uuid, @players_data, @skills_spec, @text)
        array_remove(@reconnectable_players, @uuid)
      #})
    }
  } else {
    set_pmode(@player, 'SPECTATOR')
  }
}

#게스트 서버에도 적용해야 함
proc _quit_event(@player, @uuid, @players_data, @bots) {
  if(!array_contains(@bots , @uuid)) {
    @all_players = all_players()
    array_remove_values(@all_players, @player)
    @data = array(
      'uuid': @uuid
    )
    _bungeecord_foward(@all_players[0], 'ch_player_quit', @data)
    array_remove(@players_data, @uuid)
  }
}

proc _countdown_reconnectable_players(@reconnectable_players) {
  foreach(@uuid: @remaining_second in @reconnectable_players) {
    if(@remaining_second > 0) {
      @reconnectable_players[@uuid] -= 1
    } else {
      array_remove(@reconnectable_players, @uuid)
    }
  }
}

# EVENT / TASK BINDER
foreach(@player in all_players()) { #조인 이벤트로 변경 리로드 명령어
  @uuid = puuid(@player)
  if(!array_contains(@bots, @uuid)) {
    set_timeout(1000, closure() {
      _load_data(@player, @uuid, @players_data, @skills_spec, @text)
    })
  }
}

bind('player_join', null, null, @event, @reconnectable_players, @players_data, @bots, @skills_spec, @text, @server) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('join_message', null)
  set_timeout(100, closure() {
    _join_event(@player, @uuid, @reconnectable_players, @players_data, @bots, @skills_spec, @text, @server)
  })
}

bind('player_quit', null, null, @event, @players_data, @bots) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('message', null)
  _quit_event(@player, @uuid, @players_data, @bots)
}

bind('player_toggle_sneak', null, null, @event, @players_data, @bots) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!array_contains(@bots , @player)) {
    if(@players_data[@uuid]['item']['enchantments']['armor'] == '깃털') {
      if(@event['sneaking']) {
        set_peffect(@player, 'SLOW_FALLING', 0, 0, false, true)
      } else {
        set_peffect(@player, 'SLOW_FALLING', 4, 11.5, false, true)
      }
    }
  }
}

@interval_task = set_interval(1000, closure() {
  #broadcast(@players_data)
  _countdown_reconnectable_players(@reconnectable_players)
  foreach(@uuid: @player_data in @players_data) {
    @player = player(@uuid)
    # action bar msg
    _send_action_msg(@player, @player_data, @skills_spec, @text)
    # boss bar msg
    if(!is_null(@players_data[@uuid]['cache']['indicator'])) {
      if(@players_data[@uuid]['cache']['indicator']['countdown'] > 0) {
        @players_data[@uuid]['cache']['indicator']['countdown'] -= 1
      } else {
        @players_data[@uuid]['cache']['indicator'] = null
      }
      _set_indicator(@player, @uuid, @players_data, @text)
    }

    #_countdown_skill() {}로 아래 코드 대체

    #combat_combat_inclination
    @category = 'combat_inclination'
    foreach(@skill in json_decode(@players_data[@uuid]['skill_manager'][0])) {
      #broadcast(@skill)
    }

    #combat_method
    @category = 'combat_method'
    @skill = @players_data[@uuid]['skill_manager'][2]
    if(@skill != '' && array_index_exists(@player_data['active_skill'], @category) && array_index_exists(@player_data['active_skill'][@category], @skill)) {
      @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
      @active_skill = @players_data[@uuid]['active_skill'][@category][@skill]
      switch(@skill) {
      case 'sweeping':
        if(@active_skill[2] == 0) {
          if(@active_skill[1] > 0) {
            @active_skill[1] -= 1
            if(@active_skill[1] == 0) {
              @active_skill[0] = @skills_spec[@category][@skill]['levels'][@level]['active']['cooldown']
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
        if(@active_skill[2] < 3) {
          if(@active_skill[0] > 0) {
            @active_skill[0] -= 1
          } else {
            @active_skill[2] += 1
            @active_skill[0] = @skills_spec[@category][@skill]['levels'][@level]['active']['cooldown']
          }
        }
        break()
      case 'cleaving':
        if(@active_skill[2] == 0) {
          if(@active_skill[1] > 0) {
            @active_skill[1] -= 1
            if(@active_skill[1] == 0) {
              @active_skill[0] = @skills_spec[@category][@skill]['levels'][@level]['active']['cooldown']
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
      }
    }

    #harvesting_method
    @category = 'harvesting_method'
    @skill = @players_data[@uuid]['skill_manager'][3]
    if(@skill != '' && array_index_exists(@player_data['active_skill'], @category) && array_index_exists(@player_data['active_skill'][@category], @skill)) {
      @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
      @active_skill = @players_data[@uuid]['active_skill'][@category][@skill]
      if(@active_skill[2] == 0) {
        if(@active_skill[1] > 0) {
          @active_skill[1] -= 1
          if(@active_skill[1] == 0) {
            @active_skill[0] = @skills_spec[@category][@skill]['levels'][@level]['active']['cooldown']
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
    if(@skill != '' && array_index_exists(@player_data['active_skill'], @category) && array_index_exists(@player_data['active_skill'][@category], @skill)) {
      @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
      @active_skill = @players_data[@uuid]['active_skill'][@category][@skill]
      if(@active_skill[2] == 0) {
        if(@active_skill[1] > 0) {
          @active_skill[1] -= 1
          if(@active_skill[1] == 0) {
            @active_skill[0] = @skills_spec[@category][@skill]['levels'][@level]['active']['cooldown']
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

    #apply enchantment effects
    _apply_passive_armor_enchantment(@player, @player_data)

    #apply nether field effects
    if(@server['name'] == 'nether') {
      if(array_contains(array('SURVIVAL', 'ADVENTURE'), pmode(@player)) && !array_index_exists(get_peffect(@player), 'fire_resistance') && entity_onfire(@uuid) < 20) {
        switch(@player_data['item']['enchantments']['armor']) {
        case '반엔트로피':
          break()
        case '원소 보호':
          if(rand() < 0.2) {
            set_entity_onfire(@uuid, entity_onfire(@uuid) + 3)
          }
          break()
        default:
          if(rand() < 0.3) {
            set_entity_onfire(@uuid, entity_onfire(@uuid) + 4)
          }
          break()
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

bind('plugin_message_received', null, array('channel': 'BungeeCord'), @event, @reconnectable_players, @players_data, @server, @bots) {
  @identifier_size = -1
  foreach(@key: @byte in @event['bytes']) {
    #broadcast(@key @byte )
    if(@key != 0) {
      #if(@byte == 0) {
      if(@byte == 123) {
        @identifier_size = @key - 6 #-2
        break()
      }
    }
  }
  #
  if(@identifier_size != -1) {
    @value_string = string(ba_get_bytes(@event['bytes'], array_size(@event['bytes']) - @identifier_size - 6, @identifier_size + 6))
    if(string_ends_with(@value_string, '}')) {
      @data = array(
        'identifier': string(ba_get_bytes(@event['bytes'], @identifier_size, 2)),
        'value': json_decode(@value_string)
      )
      switch(@data['identifier']) {
      case 'ch_player_quit':
        @uuid = @data['value']['uuid']
        @reconnectable_players[@uuid] = 10
        break()
      case 'ch_default_chat':
        _default_chat(@data['value'], @players_data, @bots)
        break()
      case 'ch_local_chat':
        _local_chat(@data['value'], @players_data, @bots)
        break()
      case 'ch_guild_chat':
        _guild_chat(@data['value'], @players_data, @bots)
        break()
      case 'ch_admin_chat':
        _admin_chat(@data['value'], @players_data, @bots)
        break()
      case 'ch_whisper':
        _whisper(@data['value'])
        break()
      case 'ch_broadcast':
        @receiver_uuids = _all_players(@bots)
        foreach(@receiver_uuid in @receiver_uuids) {
          @receiver_name = bukkitlinked_get_player_name(@receiver_uuid)
          if(ponline(@receiver_name)) {
            tellraw(@receiver_name, @data['value']['raw'])
            play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
          }
        }
        break()
      case 'ch_resourcepack_url_update':
        @server['resourcepack'] = @data['value']['url']
        store_value('resourcepack', @data['value']['url'])
      }
    }
  }
}

bind('block_place', null, null, @event, @players_data, @skills_spec, @server) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && pmode(@player) == 'SURVIVAL') {
    @is_farming_allowed = true
    if(@is_farming_allowed) {
      @crop = @event['block']
      @crops = array(
        'WHEAT',
        'BEETROOTS',
        'POTATOS',
        'CARROTS',
        'SWEET_BERRY_BUSH',
        'PUMPKIN_STEM',
        'MELON_STEM'
      )
      if(array_contains(@crops, @event['block'])) {
        @sowing_method = @players_data[@uuid]['skill_manager'][4]
        if(@sowing_method != '' && @players_data[@uuid]['active_skill']['sowing_method'][@sowing_method][1] > 0) {
          switch(@sowing_method) {
          case 'wet_hands':
            @farmland_location = array_deep_clone(@event['location'])
            @farmland_location['y'] -= 1
            @farmland_blockdata = get_blockdata(@farmland_location)
            if(@farmland_blockdata['block'] == 'farmland') {
              @farmland_blockdata['moisture'] = 6
              set_blockdata(@farmland_location, @farmland_blockdata)
            }
            break()
          case 'fertile_touch':
            @crop_location = array_deep_clone(@event['location'])
            @crop_blockdata = get_blockdata(@crop_location)
            @crop_blockdata['age'] = 1
            set_blockdata(@crop_location, @crop_blockdata)
            break()
          }
        }
        broadcast(@event)
      }
    }
  }
}

bind('block_break', null, null, @event, @players_data, @hp_blocks, @minerals_spec, @crops_spec, @skills_spec, @text, @server) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && pmode(@player) == 'SURVIVAL') {
    @is_farming_allowed = true
    if(@is_farming_allowed) {
      _crop_mine_event(@event, @player, @uuid, @players_data, @crops_spec, @skills_spec, @text)
    }
    @is_mining_allowed = true
    if(@is_mining_allowed) {
      _mineral_mine_event(@event, @player, @uuid, @players_data, @hp_blocks, @minerals_spec, @skills_spec, @text)
      @stones = array(
        'STONE': 1,
        'GRANITE': 0.25,
        'DIORITE': 0.25,
        'ANDESITE': 0.25,
        'BASALT': 0.5,
        'BLACKSTONE': 1,
        'NETHERRACK': 0.25,
        'CRIMSON_NYLIUM': 0.25,
        'WARPED_NYLIUM': 0.25,
        'MAGMA_BLOCK': 0.5
      )
      if(array_index_exists(@stones, @event['block'])) {
        @default_xp = integer(@stones[@event['block']])
        @extra_xp = @stones[@event['block']] - @default_xp
        @skill = 'tough_shoulder'
        @skill_data = @players_data[@uuid]['skill_data']['mining'][@skill]
        _add_epxerience(@uuid, @skill, @skill_data, @default_xp, @extra_xp)
      }

      if(@server['name'] == 'nether') {
        if(array_contains(array('SURVIVAL', 'ADVENTURE'), pmode(@player))) {
          @location = array('x': @event['location']['x'], 'y': @event['location']['y'], 'z': @event['location']['z'], 'world': @event['location']['world'])
          switch(@players_data[@uuid]['item']['enchantments']['main_hand']) {
          case '빙결':
            @probability = 0
            break()
          case '냉기':
            @probability = 0.25
            break()
          default:
            @probability = 0.5
            break()
          }
          switch(@event['block']) {
          case 'ANCIENT_DEBRIS':
            @probability *= 1
            switch(rand(0, 6)) {
            case 0:
              @location['x'] += 1
              break()
            case 1:
              @location['x'] -= 1
              break()
            case 2:
              @location['y'] += 1
              break()
            case 3:
              @location['y'] -= 1
              break()
            case 4:
              @location['z'] += 1
              break()
            case 5:
              @location['z'] -= 1
              break()
            }
            break()
          case 'MAGMA_BLOCK':
            @probability *= 1.5
            break()
          case 'NETHERRACK':
          case 'BALCKSTONE':
            @probability *= 0.1
            break()
          case 'CRIMSON_NYLIUM':
          case 'WARPED_NYLIUM':
            @probability *= 0.05
            break()
          default:
            @probability *= 0
            break()
          }
          if(rand() < @probability) {
            @meltable_blocks = array(
              'AIR',
              'CAVE_AIR',
              'NETHERRACK',
              'BALCKSTONE',
              'CRIMSON_NYLIUM',
              'WARPED_NYLIUM',
              'MAGMA_BLOCK'
            )
            set_timeout(1, closure() {
              if(array_contains(@meltable_blocks, get_block(@location))) {
                set_blockdata(@location, array('block': 'lava', 'level': 0))
              }
            })
            set_timeout(500, closure() {
              if(array_contains(@meltable_blocks, get_block(@location))) {
                set_blockdata(@location, array('block': 'lava', 'level': 1))
              }
            })
          }
        }
      }
    }
  }
}

bind('player_interact', null, null, @event, @players_data, @hp_blocks, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && pmode(@player) == 'SURVIVAL') {
    @is_sowing_allowed = true
    if(@is_sowing_allowed) {
      _farmland_sow_event(@event, @player, @uuid, @players_data, @hp_blocks, @skills_spec, @text)
    }
  }
  @armors = array(
    'LEATHER_BOOTS',
    'CHAINMAIL_BOOTS',
    'IRON_BOOTS',
    'GOLDEN_BOOTS',
    'DIAMOND_BOOTS',
    'NETHERITE_BOOTS'
  )
  if(is_null(get_inventory_item(@uuid, 36)) && !is_null(@event['item']) && array_contains(@armors, @event['item']['name']) && array_contains(array('right_click_block', 'right_click_air'), @event['action'])) {
    _update_item(@player, @uuid, array('armor': @event['item']), @players_data, @skills_spec, @text)
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
        @pos = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.2, 'z': @event['location']['z'] + 0.5)
        @delta = array('x': 0.25, 'y': 0.125, 'z': 0.25)
        @uuid = puuid(@player)
        #mom_playerparticle(@uuid, 'VILLAGER_HAPPY', @pos['x'], @pos['y'], @pos['z'], 15, @delta['x'], @delta['y'], @delta['z'], 0.0)
        _add_epxerience(@uuid, 'fertile_touch', @players_data[@uuid]['skill_data']['sowing_method']['fertile_touch'], 1, 0)
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
        _add_epxerience(@uuid, 'wet_hands', @players_data[@uuid]['skill_data']['sowing_method']['wet_hands'], 1, 0)
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