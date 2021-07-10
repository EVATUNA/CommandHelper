## Data Procedure
proc _load_data(@player, @uuid, @players_data, @skills_spec, @text) {
  # cache
  @players_data[@uuid]['cache'] = array(
    'resolution_setting': false,
    'last_weapon_effect': 0,
    'last_armor_effect': 0,
    'indicator': null,
    'tips': array()
  )
  # setting
  @players_data[@uuid]['setting'] = cup_get('SETTING', @uuid)
  if(is_null(@players_data[@uuid]['setting'])) {
    _new_setting(@uuid, @players_data)
  }
  # chat
  @players_data[@uuid]['chat'] = cup_get('CHAT', @uuid)
  if(is_null(@players_data[@uuid]['chat'])) {
    _new_chat(@uuid, @players_data)
  }
  # decoration
  @players_data[@uuid]['decoration'] = cup_get('DECORATION', @uuid)
  if(is_null(@players_data[@uuid]['decoration'])) {
    _new_decoration(@uuid, @players_data)
  }
  # skill
  _load_skills(@uuid, @players_data, @skills_spec)
  
  # bossbar
  @bossbars = get_bars()

  ## 인디케이터
  @indicator_id = 'indicator.'.@uuid
  if(array_contains(@bossbars, @indicator_id)) {
    remove_bar(@indicator_id)
  }
  @indicator_bossbar_data = array(
    'title': '',
    'percent': 0
  )
  create_bar(@indicator_id, @indicator_bossbar_data)
  bar_add_player(@indicator_id, @player)

  ## 툴팁
  @tip_id = 'tip.'.@uuid
  if(array_contains(@bossbars, @tip_id)) {
    remove_bar(@tip_id)
  }
  @tip_bossbar_data = array(
    'title': '',
    'percent': 0
  )
  create_bar(@tip_id, @tip_bossbar_data)
  bar_add_player(@tip_id, @player)

  # item
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
  
  #_load_tip_data(@player, @uuid, @players_data)
}

proc _new_setting(@uuid, @players_data) {
  @players_data[@uuid]['setting'] = array(
    427,  // 해상도
    true, // 오른손 사용중인지
    json_encode(array(  // 소리 들을지 설정
      'mention': true,
      'chat': true,
      'gui': true
    )),
    json_encode(array()) // 더미 세팅
  )
  cup_set('SETTING', @uuid, @players_data[@uuid]['setting'])
}

proc _new_chat(@uuid, @players_data) {
  @players_data[@uuid]['chat'] = array(
    'default', // 사용중인 채팅 채널
    false, // enko여부
    json_encode(array('default', 'local', 'town')), // 듣기 활성화 할 채널들
    false, // 채팅 옵저버모드
    '',    // 마지막 귓말한사람
    '',    // 마지막 채팅친사람
    false, // 메신저채팅 여부
    false  // 채팅 이름부분 정렬 여부
  )
  cup_set('SETTING', @uuid, @players_data[@uuid]['chat'])
}

proc _new_decoration(@uuid, @players_data) {
  @players_data[@uuid]['decoration'] = array(
    array('\uf01e', '\uf01f', '\uf020', '\uf021')[rand(0, 4)], // 임시 뱃지
    '', // 머리장식
    '', // 네임태그
    '', // 더미
    json_encode(array()), // 뱃지 목록
    json_encode(array()), // 머리장식 목록
    json_encode(array()), // 네임태그 목록
    json_encode(array())  // 더미
  )
  cup_set('SETTING', @uuid, @players_data[@uuid]['decoration'])
}

proc _send_resourcepack(@player, @uuid, @players_data, @skills_spec, @text, @resourcepack) {
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
  send_resourcepack(@player, @resourcepack['url'])
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

proc _join_event(@player, @uuid, @reconnectable_players, @players_data, @skills_spec, @text, @resourcepack) {
  runas('~console', '/recipe give '.@player.' *')
  if(!array_index_exists(@reconnectable_players, @uuid)) {
    _send_resourcepack(@player, @uuid, @players_data, @skills_spec, @text, @resourcepack)
  } else {
    #set_timeout(500, closure() {
      _load_data(@player, @uuid, @players_data, @skills_spec, @text)
      array_remove(@reconnectable_players, @uuid)
    #})
  }
}

proc _quit_event(@uuid, @players_data) {
  kafka_send('ch.inform_player_quit', @uuid)
  array_remove(@players_data, @uuid)
  #_update_tip_data(@uuid, @players_data)
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
  set_timeout(1, closure() {
    _load_data(@player, @uuid, @players_data, @skills_spec, @text)
  })
}

bind('player_join', null, null, @event, @reconnectable_players, @players_data, @skills_spec, @text, @resourcepack) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('join_message', null)
  set_timeout(100, closure() {
    _join_event(@player, @uuid, @reconnectable_players, @players_data, @skills_spec, @text, @resourcepack)
  })
}

bind('player_quit', null, null, @event, @players_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('message', null)
  _quit_event(@uuid, @players_data)
}

bind('player_toggle_sneak', null, null, @event, @players_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid) && @players_data[@uuid]['item']['enchantments']['armor'] == '깃털') {
    if(@event['sneaking']) {
      set_peffect(@player, 'SLOW_FALLING', 0, 0, false, true)
    } else {
      set_peffect(@player, 'SLOW_FALLING', 4, 11.5, false, true)
    }
  }
}

@interval_task = set_interval(1000, closure() {
  #broadcast(@players_data)
  _countdown_reconnectable_players(@reconnectable_players)
  foreach(@uuid: @player_data in @players_data) {
    @player = player(@uuid)
    if(ponline(@player)) {
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
      if(array_size(@players_data[@uuid]['cache']['tips']) > 0) {
        if(@players_data[@uuid]['cache']['tips'][0]['countdown'] > 0) {
          @players_data[@uuid]['cache']['tips'][0]['countdown'] -= 1
        } else {
          array_remove(@players_data[@uuid]['cache']['tips'], 0)
        }
        _set_tips(@player, @uuid, @players_data)
      }

      # 액티브 스킬 카운드다운
      foreach(@skill: @active_skill in @player_data['active_skill']) { // 활성화된 액티브 스킬 포리치
        @proc_name = "_apply_countdown_by_@skill"
        if(is_proc(@proc_name)) {
          call_proc(@proc_name, @var)
        }
      }

      #apply enchantment effects
      _apply_passive_armor_enchantment(@player, @player_data)

      #apply nether field effects
      if(@server == 'nether') {
        if(array_contains(array('SURVIVAL', 'ADVENTURE'), pmode(@player)) && !array_index_exists(get_peffect(@player), 'fire_resistance') && entity_onfire(@uuid) < 20) {
          switch(@player_data['item']['enchantments']['armor']) {
          case '반엔트로피':
            break()
          case '원소 보호':
            if(rand() < 0.02) {
              set_entity_onfire(@uuid, entity_onfire(@uuid) + 6)
            }
            break()
          default:
            if(rand() < 0.075) {
              set_entity_onfire(@uuid, entity_onfire(@uuid) + 10)
            }
            break()
          }
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

bind('kafka_receive', null, null, @event, @reconnectable_players, @players_data, @resourcepack) {
  switch(@event['key']) {
  case 'ch.inform_player_quit':
    @uuid = @evnet['value']
    @reconnectable_players[@uuid] = 10
    break()
  case 'ch.update_resourcepack_url':
    @url = @evnet['value']
    @resourcepack['url'] = @url
    store_value('resourcepack', @url)
    break()
  case 'ch.send_defaultchat':
    @data = json_decode(@evnet['value'])
    _default_chat(@data, @players_data)
    break()
  case 'ch.send_townchat':
    @data = json_decode(@evnet['value'])
    _town_chat(@data, @players_data)
    break()
  case 'ch.send_localchat':
    @data = json_decode(@evnet['value'])
    _local_chat(@data, @players_data)
    break()
  case 'ch.send_adminchat':
    @data = json_decode(@evnet['value'])
    _admin_chat(@data, @players_data)
    break()
  case 'ch.send_whisper':
    @data = json_decode(@evnet['value'])
    _whisper(@data)
    break()
  case 'ch.send_broadcast':
    @data = json_decode(@evnet['value'])
    foreach(@receiver_name in all_players()) {
      tellraw(@receiver_name, @data['raw'])
      play_named_sound(ploc(@receiver_name), array('sound': 'message.in', 'category': 'master', 'volum': 100), array(@receiver_name))
    }
    break()
  }
}

bind('block_place', null, null, @event, @players_data, @skills_spec) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && pmode(@player) == 'SURVIVAL') {
    @is_farming_allowed = true
    if(@is_farming_allowed) {
      @crop = @event['block']
      @crops = array(
        'WHEAT',
        'BEETROOTS',
        'POTATOES',
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
      }
    }
  }
}

bind('block_break', null, null, @event, @players_data, @hp_blocks, @minerals_spec, @crops_spec, @skills_spec, @text, @server) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(pmode(@player) == 'SURVIVAL') {
    if(@server == 'main' && pworld(@player) == 'spawn_minecraft_residence') {
      _crop_mine_event(@event, @player, @uuid, @players_data, @crops_spec, @skills_spec, @text)
    }
    if(@server != 'main') {
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
      if(@server == 'nether') {
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
              if(get_block(@location) == 'LAVA') {
                set_blockdata(@location, array('block': 'lava', 'level': 1))
              }
            })
          }
        }
      }
    }
  }
}

bind('player_interact', null, null, @event, @players_data, @hp_blocks, @skills_spec, @essences, @server, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  # equip armor
  @armors = array(
    'LEATHER_BOOTS',
    'CHAINMAIL_BOOTS',
    'IRON_BOOTS',
    'GOLDEN_BOOTS',
    'DIAMOND_BOOTS',
    'NETHERITE_BOOTS'
  )
  if(!is_cancelled() && is_null(get_inventory_item(@uuid, 36)) && !is_null(@event['item']) && array_contains(@armors, @event['item']['name']) && array_contains(array('right_click_block', 'right_click_air'), @event['action'])) {
    _update_item(@player, @uuid, array('armor': @event['item']), @players_data, @skills_spec, @text)
  }
  # use skill scroll
  if(!is_null(@event['item']) && @event['item']['name'] == 'ENCHANTED_BOOK' && !is_null(@event['item']['meta']) && !is_null(@event['item']['meta']) && @event['item']['meta']['model'] > 0) {
    #take_from_inventory(@uuid, 'PAPER', 1)
  # use enchant
  }
  if(!is_null(@event['item']) && @event['item']['name'] == 'EXPERIENCE_BOTTLE' && !is_null(@event['item']['meta']) && !is_null(@event['item']['meta']) && @event['item']['meta']['model'] > 0) {
    cancel()
  }
  # cancel using disabled blocks & block system
  if(@event['action'] == 'right_click_block') {
    @action = null
    switch(@event['block']) {
    case 'END_PORTAL_FRAME':
    #case 'ENDER_CHEST':
    case 'GRINDSTONE':
    case 'SWEET_BERRY_BUSH':
    case 'ANVIL':
    case 'CHIPPED_ANVIL':
    case 'DAMAGED_ANVIL':
      if(psneaking(@player)) {
        cancel()
      }
      break()
    case 'SMITHING_TABLE':
      cancel()
      if(!psneaking(@player) || (is_null(get_inventory_item(@uuid, pheld_slot(@player))) && is_null(get_inventory_item(@uuid, 40)))) {
        if(pworld(@player) == 'spawn') {
          @location = array('x': integer(@event['location']['x']), 'y': integer(@event['location']['y']), 'z': integer(@event['location']['z']), 'world': @event['location']['world'])
          @gui_id = 'enchant_table.'.@location['x'].'.'.@location['y'].'.'.@location['z']
          # 인첸트 되는 아이템 위치 설정
          @item_location = array_deep_clone(@location)
          @item_location['x'] += 1.25
          @item_location['z'] += 0.5
          @item_location['y'] -= 0.7
          @item_location['yaw'] = 90
          @item_armorstand = _preset_item_armorstand(@item_location)
          # 마법의 정수 위치 설정
          @essence_location = array_deep_clone(@location)
          @essence_location['x'] += 0.75
          @essence_location['z'] += 1.5
          @essence_location['y'] += 1
          @essence_location['yaw'] = -90
          @essence_armorstand = _preset_essence_armorstand(@essence_location)
          # 아머스탠드 정보 기준 사용중인 유저
          @user_by_armorstand = get_mob_name(@item_armorstand)
          # 실제 사용중인 유저
          @user_by_commandhelper = import(@gui_id, '')
          # 시각 효과 진행중인지 여부
          @is_effect_progressing = boolean(get_mob_name(@essence_armorstand))
          
          # 조건 시작
          @item = get_mob_equipment(@item_armorstand)['helmet']
          @can_take_out_item = false
          @can_enchant = false
          #tmsg('aaaa__', @user_by_armorstand @user_by_commandhelper)
          if(@user_by_armorstand != '' && @user_by_armorstand == @user_by_commandhelper) { # 주인이 가져갈 때
            #tmsg('aaaa__', 주인)
            if(@user_by_commandhelper == @player && !@is_effect_progressing && !is_null(@item)) {
              @can_take_out_item = true
            }
          } else { # 남이 가져갈 때 
            if(!@is_effect_progressing) {
              if(!is_null(@item)) {
                @can_take_out_item = true
              } else {
                @can_enchant = true
              }
            }
          }
          # 아이템 올려져 있고 아이템 꺼낼수 있을시 아이템 주기
          if(@can_take_out_item) {
            set_mob_equipment(@item_armorstand, array(
              'helmet': null
            ))
            set_mob_equipment(@essence_armorstand, array(
              'helmet': null
            ))
            @item['qty'] = pgive_item(@player, @item)
            @drop_location = array_deep_clone(@location)
            @drop_location['x'] += 0.5
            @drop_location['z'] += 0.5
            @drop_location['y'] += 1
            drop_item(@drop_location, @item, false)
            export(@gui_id, '')
            set_mob_name(@item_armorstand, '')
          }
          # 아무도 이용중이지 않고 올려진 아이템도 없을시 gui 열기
          if(@can_enchant) {
            # 사용중으로 설정
            export(@gui_id, @player)
            # gui 세팅
            @texture_layer = @text['space_fonts']['space.-8'].'§f\ue3fb'.@text['space_fonts']['space.-169'].hexcolor('#404040')
            @message = '마법 작업대'
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
            @inventory[22] = null
            set_mob_name(@item_armorstand, @player)
            # 이벤트 세팅
            @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @essences, @location, @uuid, @item_armorstand, @essence_armorstand, @text) {
              #인첸트 안하고 그냥 인벤 닫을시
              bind('inventory_close', array('id': 'close'.@id), array('player': @player, 'virtual': true), @event, @player, @uuid, @gui_id, @item_armorstand, @essence_armorstand) {
                @item = @event['inventory'][22]
                if(!is_null(@item)) {
                  @item['qty'] = pgive_item(@player, @item)
                  @ploc = ploc(@player)
                  @ploc['y'] += 1
                  drop_item(@ploc, @item, false)
                }
                export(@gui_id, '')
                set_mob_name(@item_armorstand, '')
                set_mob_name(@essence_armorstand, '')
                #broadcast(초기화 완료)
              }
              #인첸트 할시
              bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @uuid, @gui_id, @id, @location, @item_armorstand, @essence_armorstand, @essences) {
                @enchantable_items = array(
                  'LEATHER_BOOTS': array(
                    'luck': 1.5,
                    'entries_type': 'armor_entries'
                  ),
                  'CHAINMAIL_BOOTS': array(
                    'luck': 0.5,
                    'entries_type': 'armor_entries'
                  ),
                  'IRON_BOOTS': array(
                    'luck': 0.9,
                    'entries_type': 'armor_entries'
                  ),
                  'GOLDEN_BOOTS': array(
                    'luck': 2.5,
                    'entries_type': 'armor_entries'
                  ),
                  'DIAMOND_BOOTS': array(
                    'luck': 1.0,
                    'entries_type': 'armor_entries'
                  ),
                  'NETHERITE_BOOTS': array(
                    'luck': 1.5,
                    'entries_type': 'armor_entries'
                  ),
                  'WOODEN_SWORD': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'WOODEN_SHOVEL': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'WOODEN_PICKAXE': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'WOODEN_AXE': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'WOODEN_HOE': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'STONE_SWORD': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'STONE_SHOVEL': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'STONE_PICKAXE': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'STONE_AXE': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'STONE_HOE': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'IRON_SWORD': array(
                    'luck': 1.4,
                    'entries_type': 'weapon_entries'
                  ),
                  'IRON_SHOVEL': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'IRON_PICKAXE': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'IRON_AXE': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'IRON_HOE': array(
                    'luck': 0.9,
                    'entries_type': 'weapon_entries'
                  ),
                  'GOLDEN_SWORD': array(
                    'luck': 2.2,
                    'entries_type': 'weapon_entries'
                  ),
                  'GOLDEN_SHOVEL': array(
                    'luck': 2.2,
                    'entries_type': 'weapon_entries'
                  ),
                  'GOLDEN_PICKAXE': array(
                    'luck': 2.2,
                    'entries_type': 'weapon_entries'
                  ),
                  'GOLDEN_AXE': array(
                    'luck': 2.2,
                    'entries_type': 'weapon_entries'
                  ),
                  'GOLDEN_HOE': array(
                    'luck': 2.2,
                    'entries_type': 'weapon_entries'
                  ),
                  'DIAMOND_SWORD': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'DIAMOND_SHOVEL': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'DIAMOND_PICKAXE': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'DIAMOND_AXE': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'DIAMOND_HOE': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  ),
                  'NETHERITE_SWORD': array(
                    'luck': 1.5,
                    'entries_type': 'weapon_entries'
                  ),
                  'NETHERITE_SHOVEL': array(
                    'luck': 1.5,
                    'entries_type': 'weapon_entries'
                  ),
                  'NETHERITE_PICKAXE': array(
                    'luck': 1.5,
                    'entries_type': 'weapon_entries'
                  ),
                  'NETHERITE_AXE': array(
                    'luck': 1.5,
                    'entries_type': 'weapon_entries'
                  ),
                  'NETHERITE_HOE': array(
                    'luck': 1.5,
                    'entries_type': 'weapon_entries'
                  ),
                  'TRIDENT': array(
                    'luck': 1.0,
                    'entries_type': 'weapon_entries'
                  )
                )
                @rawslot = @event['rawslot']
                if(@rawslot >= 0 && @rawslot <= 26) {
                  @clicked_item = @event['inventory'][@rawslot]
                  if(!is_null(@clicked_item) && @clicked_item['name'] == 'STRUCTURE_VOID') {
                    cancel()
                  }
                  @cursor_item = @event['cursoritem']
                  if(!is_null(@cursor_item) && @cursor_item['name'] == 'EXPERIENCE_BOTTLE' && !is_null(@cursor_item['meta']) && !is_null(@cursor_item['meta']['display']) && @rawslot == 22 && @event['action'] == 'SWAP_WITH_CURSOR') {
                    @cursor_item['qty'] -= 1
                    @enchanting_item = @event['inventory'][@rawslot]
                    @enchantable_item = @enchantable_items[@enchanting_item['name']]
                    @enchanted_item = @enchanting_item
                    if(!is_null(@enchanting_item) && array_index_exists(@enchantable_items, @enchanting_item['name'])) {
                      @essence_name = strip_colors(@cursor_item['meta']['display'])
                      if(array_index_exists(@essences, @essence_name)) {
                        @entries = @essences[@essence_name][@enchantable_item['entries_type']]
                        @enchanted_item = _get_enchanted_item(@enchanting_item, @entries, @enchantable_item['luck'])
                      }
                      cancel()
                      unbind('close'.@id)
                      modify_event('cursoritem', @cursor_item)
                      close_pinv(@player)
                      # 시각 효과
                      set_mob_name(@essence_armorstand, true)
                      # 아이템 배치
                      set_timeout(1000, closure() {
                        set_mob_equipment(@item_armorstand, array( 'helmet': @enchanted_item ))
                        play_named_sound(@location, array('sound': 'minecraft:item.armor.equip_diamond', 'category': 'NEUTRAL', 'volume': 1, 'pitch': 0.5))
                        @pos = array(
                          'x': @location['x'] + 0.5,
                          'y': @location['y'] + 1.1,
                          'z': @location['z'] + 0.5
                        )
                        @delta = array(
                          'x': 0.02,
                          'y': 0.0,
                          'z': 0.02
                        )
                        mom_playerparticle(@uuid, 'CRIT_MAGIC', @pos['x'], @pos['y'], @pos['z'], 10, @delta['x'], @delta['y'], @delta['z'], 0.25)
                      })
                      #정수 배치
                      set_timeout(5000, closure() {
                        @cursor_item['qty'] = 1
                        set_mob_equipment(@essence_armorstand, array( 'helmet': @cursor_item ))
                        @interval = array('tick': 20, 'id': null)
                        @interval_id = set_interval(150 , closure() {
                          if(@interval['tick'] > 0) {
                            play_named_sound(@location, array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 1, 'pitch': 1))
                            @particle_location = array_deep_clone(@location)
                            @particle_location['x'] += (0.5 + rand() / 5 - 0.1)
                            @particle_location['y'] += (2.15 + rand() / 5 - 0.1)
                            @particle_location['z'] += (0.5 + rand() / 5 - 0.1)
                            spawn_particle(@particle_location, 'TOTEM')
                            #@delta = array(
                            #  'x': rand() / 5 - 0.1,
                            #  'y': -1.0,
                            #  'z': rand() / 5 - 0.1
                            #)
                            #mom_playerparticle(@uuid, 'TOTEM', @pos['x'], @pos['y'], @pos['z'], 0, @delta['x'], @delta['y'], @delta['z'], 1.0)
                            @interval['tick'] -= 1
                          } else {
                            clear_task()
                            play_named_sound(@location, array('sound': 'minecraft:block.enchantment_table.use', 'category': 'NEUTRAL', 'volume': 1, 'pitch': 1))
                            set_mob_equipment(@essence_armorstand, array( 'helmet': null ))
                            set_mob_name(@essence_armorstand, '')
                          }
                        })
                        @interval['id'] = @interval_id
                      })
                      set_timeout(60000, closure() {
                        export(@gui_id, '')
                      })
                    }
                  }
                }
              }
            }
            _show_gui(@player, @gui_id, 27, @texture_layer, @message, @inventory, @closure, @essences, @location, @uuid, @item_armorstand, @essence_armorstand, @text)
          }
        }
      }
      break()
    case 'ENCHANTING_TABLE':
      cancel()
      if(!psneaking(@player) || (is_null(get_inventory_item(@uuid, pheld_slot(@player))) && is_null(get_inventory_item(@uuid, 40)))) {
        @location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 1.01, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
        if(plevel(@player) >= 30) {
          if(pcooldown(@player, 'CAVE_AIR') == 0) {
            set_pcooldown(@player, 'CAVE_AIR', 30)
            @task = array('tick': 10, 'id': null)
            @id = set_interval(100 , closure() {
              if(ponline(@player)) {
                if(@task['tick'] > 0) {
                  @ploc = ploc(@player)
                  play_named_sound(@location, array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 1, 'pitch': 1))
                  @pos = array(
                    'x': @ploc['x'] + rand() / 2 - 0.25,
                    'y': @ploc['y'] + rand() * 1.5 + 1,
                    'z': @ploc['z'] + rand() / 2 - 0.25
                  )
                  @delta = array(
                    'x': (@location['x'] - @pos['x']) / 2,
                    'y': (@location['y'] - @pos['y']) / 2,
                    'z': (@location['z'] - @pos['z']) / 2
                  )
                  mom_playerparticle(@uuid, 'TOTEM', @pos['x'], @pos['y'], @pos['z'], 0, @delta['x'], @delta['y'], @delta['z'], 1.0)
                  @task['tick'] -= 1
                } else {
                  clear_task()
                  play_named_sound(@location, array('sound': 'minecraft:block.enchantment_table.use', 'category': 'NEUTRAL', 'volume': 1, 'pitch': 1))
                  set_plevel(@player, plevel(@player) - 30)
                  @essence_name = array_rand(array(/*'희미한 마법의 정수', */'미약한 마법의 정수', '농축된 마법의 정수'/*, '강력한 마법의 정수', '찬란한 마법의 정수'*/), 1, false)[0]
                  #broadcast(@essence_name)
                  drop_item(@location, @essences[@essence_name]['item'], false)
                }
              } else {
                clear_task()
              }
            })
            @task['id'] = @id
          }
        }
      }
      break()
    }
  }
  ## farming (if canceled it didn't work)
  if(@server == 'main') {
    if(@event['action'] == 'right_click_block') {
      # bone mealing
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
          if(@data['block'] == 'farmland') {
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
    }
    set_timeout(1, closure() {
      if(@event['action'] == 'right_click_block') {
        if(!is_cancelled()) {
          # sowing
          if(pmode(@player) == 'SURVIVAL') {
            @is_sowing_allowed = true
            if(@is_sowing_allowed) {
              _farmland_sow_event(@event, @player, @uuid, @players_data, @hp_blocks, @skills_spec, @text)
            }
          }
        }
      }
    })
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

bind('inventory_click', null, null, @event) {
  @player = @event['player']
  if(ponline(@player) && pmode(@player) == 'SURVIVAL' && @event['leftclick'] && !@event['shiftclick'] && @event['inventorytype'] == 'CRAFTING' && @event['rawslot'] == 7 && is_null(@event['cursoritem'])) {
    runas(@player, '/util')
  }
}


if(@server == 'main') {
  bind('player_interact_entity', null, array('clicked': 'PLAYER', 'hand': 'main_hand'), @event, @stores, @shop_log_data) {
    @player = @event['player']
    @uuid = puuid(@player)
    switch(@event['data']) {
    case '편돌이튜나':
      _showGui(@player, 'crop', @stores, @shop_log_data)
      break()
    }
  }

  bind('player_move', null, array('world': 'spawn'), @event) {
    @portal = array(
      'min_x': 482.5,
      'min_y': 64.0,
      'min_z': 361.5,
      'max_x': 487.5,
      'max_y': 68.0,
      'max_z': 365.5
    )
    if(@event['to']['x'] > @portal['min_x'] && @event['to']['x'] < @portal['max_x'] && @event['to']['y'] > @portal['min_y'] && @event['to']['y'] < @portal['max_y'] && @event['to']['z'] > @portal['min_z'] && @event['to']['z'] < @portal['max_z']) {
      if(!(@event['from']['x'] > @portal['min_x'] && @event['from']['x'] < @portal['max_x'] && @event['from']['y'] > @portal['min_y'] && @event['from']['y'] < @portal['max_y'] && @event['from']['z'] > @portal['min_z'] && @event['from']['z'] < @portal['max_z'])) {
        runas(@event['player'], '/randomteleport')
      }
    }
  }
}
