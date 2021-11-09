## Data Procedure
proc _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text) {
  # 배열로 선언
  @players_data[@uuid] = array()
  @player_data = @players_data[@uuid]

  # cache
  @player_data['cache'] = array(
    'is_dash': false,
    'last_weapon_effect': 0,
    'last_armor_effect': 0,
    'tooltips': array()
  )

  # setting
  @player_data['setting'] = cup_get('SETTING', @uuid)
  if(is_null(@player_data['setting'])) {
    _new_setting(@uuid, @player_data)
  }

  # chat
  @player_data['chat'] = cup_get('CHAT', @uuid)
  if(is_null(@player_data['chat'])) {
    _new_chat(@uuid, @player_data)
  }

  # decoration
  @player_data['decoration'] = cup_get('DECORATION', @uuid)
  if(is_null(@player_data['decoration'])) {
    _new_decoration(@uuid, @player_data)
  }

  # skill
  _load_skills(@player_data, @player, @uuid, @skills_spec)
  
  # bossbar
  @bossbars = get_bars()
  ## 참치 레벨
  ### 보스바 id 재생성
  @tunalevel_id = "tunalevel.@uuid"
  if(array_contains(@bossbars, @tunalevel_id)) {
    remove_bar(@tunalevel_id)
  }
  ### 레벨
  @tuna_level = @player_data['skill_manager'][0]
  @tunalevel_text = _replace_tunalevel_text(@tuna_level)
  ### 경험치
  @tuna_experience = @player_data['skill_manager'][1]
  @max_tuna_experience = _get_max_tuna_experience(@tuna_level)
  @tuna_experience_persent = @tuna_experience / @max_tuna_experience
  if(@tuna_experience_persent < 0) { @tuna_experience_persent = 0 }
  if(@tuna_experience_persent > 1) { @tuna_experience_persent = 1 }
  ### 보스바 데이터 설정
  @tunalevel_bossbar_data = array(
    'title': @tunalevel_text,
    'percent': @tuna_experience_persent,
    'color': 'BLUE'
  )
  ### 보스바 생성 및 보여주기
  create_bar(@tunalevel_id, @tunalevel_bossbar_data)
  bar_add_player(@tunalevel_id, @player)
  // skill manager 바뀌는 카프카 cupset 인식하여 레벨 경험치 화면에 보여지게 해야함
  
  ## 더미 보스바
  ### 보스바 id 재생성
  @dummy_id = "dummy.@uuid"
  if(array_contains(@bossbars, @dummy_id)) {
    remove_bar(@dummy_id)
  }
  ### 보스바 데이터 설정
  @dummy_bossbar_data = array(
    'title': '',
    'percent': 0
  )
  ### 보스바 생성 및 보여주기
  create_bar(@dummy_id, @dummy_bossbar_data)
  bar_add_player(@dummy_id, @player)

  ## 인디케이터(and 툴팁) 보스바
  ### 보스바 id 재생성
  @indicator_id = 'tooltip.'.@uuid
  if(array_contains(@bossbars, @indicator_id)) {
    remove_bar(@indicator_id)
  }
  ### 보스바 데이터 설정
  @indicator_bossbar_data = array(
    'title': '',
    'percent': 0
  )
  ### 보스바 생성 및 보여주기
  create_bar(@indicator_id, @indicator_bossbar_data)
  bar_add_player(@indicator_id, @player)

  # item
  @player_data['item'] = array(
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
  @items = array()
  @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
  if(!is_null(@main_hand_item) && array_contains(@effective_items['weapon'], @main_hand_item['name'])) {
    @items['main_hand'] = @main_hand_item
  } else {
    @items['main_hand'] = null
  }
  @off_hand_item = get_inventory_item(@uuid, 40)
  if(!is_null(@off_hand_item) && array_contains(@effective_items['weapon'], @off_hand_item['name'])) {
    @items['off_hand'] = @off_hand_item
  } else {
    @items['off_hand'] = null
  }
  @armor_item = get_inventory_item(@uuid, 36)
  if(!is_null(@armor_item) && array_contains(@effective_items['armor'], @armor_item['name'])) {
    @items['armor'] = @armor_item
  } else {
    @items['armor'] = null
  }
  _update_item(@player, @uuid, @items, @player_data, @skills_spec, @text)
}

proc _new_setting(@uuid, @player_data) {
  @player_data['setting'] = array(
    427,  // 해상도
    true, // 오른손 사용중인지
    json_encode(array(  // 소리 들을지 설정
      'mention': true,
      'chat': true,
      'gui': true
    )),
    json_encode(array()) // 더미 세팅
  )
  cup_set('SETTING', @uuid, @player_data['setting'])
}

proc _new_chat(@uuid, @player_data) {
  @player_data['chat'] = array(
    'default', // 사용중인 채팅 채널
    false, // enko여부
    json_encode(array('default', 'local', 'town')), // 듣기 활성화 할 채널들
    false, // 채팅 옵저버모드
    '',    // 마지막 귓말한사람
    '',    // 마지막 채팅친사람
    false, // 메신저채팅 여부
    false  // 채팅 이름부분 정렬 여부
  )
  cup_set('CHAT', @uuid, @player_data['chat'])
}

proc _new_decoration(@uuid, @player_data) {
  @player_data['decoration'] = array(
    array('\uf01e', '\uf01f', '\uf020', '\uf021')[rand(0, 4)], // 임시 뱃지
    '', // 머리장식
    '', // 네임태그
    '', // 더미
    json_encode(array()), // 뱃지 목록
    json_encode(array()), // 머리장식 목록
    json_encode(array()), // 네임태그 목록
    json_encode(array())  // 더미
  )
  cup_set('DECORATION', @uuid, @player_data['decoration'])
}

proc _send_resourcepack(@player, @uuid, @players_data, @skills_spec, @effective_items, @text, @resourcepack) {
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
      pkick(@player, _color('#ff4040').'§l서버 리소스팩을 사용하도록 설정해 주시기 바랍니다.\n'._color('#c0c0c0').'§l에바참치 서버를 선택한 후, 수정 버튼을 눌러\n서버 리소스팩을 사용으로 설정해 주세요.\n\n'._color('#ffff80').'§l버그 문의: ')
      unbind()
      break()
    case 'SUCCESSFULLY_LOADED':
      _apply_join_spec(@player, @uuid, @join_spec, @players_data, @skills_spec, @effective_items, @text)
      unbind()
      break()
    }
  }
}

proc _apply_join_spec(@player, @uuid, @join_spec, @players_data, @skills_spec, @effective_items, @text) {
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
    _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text)
  })
}

proc _join_event(@player, @uuid, @reconnectable_players, @players_data, @skills_spec, @effective_items, @text, @resourcepack) {
  runas('~console', '/recipe give '.@player.' *')
  if(!array_index_exists(@reconnectable_players, @uuid)) {
    _send_resourcepack(@player, @uuid, @players_data, @skills_spec, @effective_items, @text, @resourcepack)
  } else {
    #set_timeout(500, closure() {
      _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text)
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
    _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text)
  })
}

bind('player_join', null, null, @event, @reconnectable_players, @players_data, @skills_spec, @effective_items, @text, @resourcepack) {
  @player = @event['player']
  @uuid = puuid(@player)
  modify_event('join_message', null)
  set_timeout(100, closure() {
    #_join_event(@player, @uuid, @reconnectable_players, @players_data, @skills_spec, @effective_items, @text, @resourcepack)
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
  _countdown_reconnectable_players(@reconnectable_players)
  foreach(@uuid: @player_data in @players_data) {
    @player = player(@uuid)
    if(ponline(@player)) {
      # action bar msg
      _send_action_msg(@player, @player_data, @skills_spec, @text)
      # boss bar msg
      if(array_size(@player_data['cache']['tooltips']) > 0) {
        if(@player_data['cache']['tooltips'][0]['countdown'] > 0) {
          @player_data['cache']['tooltips'][0]['countdown'] -= 1
        } else {
          array_remove(@player_data['cache']['tooltips'], 0)
        }
        _set_tooltips(@player, @uuid, @player_data)
      }

      # 액티브 스킬 카운드다운
      foreach(@skill: @active_skill in @player_data['active_skill']) { // 활성화된 액티브 스킬 포리치
        @proc_name = "_apply_countdown_by_@skill"
        @skill_spec = @skills_spec[@skill]
        @point = @player_data['skill_data'][@skill][0]
        if(is_proc(@proc_name)) {
          #broadcast(@proc_name @player @skill @point @active_skill)
          call_proc(@proc_name, @player_data, @player, @uuid, @skill, @skill_spec, @point)
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
    @uuid = @event['value']
    @reconnectable_players[@uuid] = 5
    break()
  case 'ch.update_resourcepack_url':
    @url = @event['value']
    @resourcepack['url'] = @url
    store_value('resourcepack', @url)
    break()
  case 'ch.send_defaultchat':
    @data = json_decode(@event['value'])
    _default_chat(@data, @players_data)
    break()
  case 'ch.send_townchat':
    @data = json_decode(@event['value'])
    _town_chat(@data, @players_data)
    break()
  case 'ch.send_localchat':
    @data = json_decode(@event['value'])
    _local_chat(@data, @players_data)
    break()
  case 'ch.send_adminchat':
    @data = json_decode(@event['value'])
    _admin_chat(@data, @players_data)
    break()
  case 'ch.send_whisper':
    @data = json_decode(@event['value'])
    _whisper(@data)
    break()
  case 'ch.send_broadcast':
    @data = json_decode(@event['value'])
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
        @player_data = @players_data[@uuid]
        @skill_manager = @player_data['skill_manager']
        @sowing_method = @harvesting_method = json_decode(@skill_manager[4])['sowing_method']
        if(@sowing_method != '' && @player_data['active_skill'][@sowing_method][1] > 0) {
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
        @skill_data = @players_data[@uuid]['skill_data'][@skill]
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

proc _open_level_converter(@player, @uuid, @inventory, @block_location, @magic_items, @text) {  
  @ingredient = @inventory[1]
  @level = plevel(@player)
  @backgroundtext = @text['space_fonts']['space.-8'].'\uec1e'.@text['space_fonts']['space.-169']
  @book_text = @text['space_fonts']['space.-1'].'\uec1f'
  @magic_items['미약한 마법의 정수']['text'] = @text['space_fonts']['space.18']
  @magic_items['농축된 마법의 정수']['text'] = @text['space_fonts']['space.18']
  @magic_items['강력한 마법의 정수']['text'] = @text['space_fonts']['space.18']
  @magic_items['변환의 끈']['text'] = @text['space_fonts']['space.18']
  @magic_items['놀라운 변환의 끈']['text'] = @text['space_fonts']['space.18']
  @magic_items['강력한 변환의 끈']['text'] = @text['space_fonts']['space.18']
  @magic_items['스킬 포인트 초기화 스크롤']['text'] = @text['space_fonts']['space.18']
  if(!is_null(@ingredient)) {
    if(@level >= 30) {
      switch(@ingredient['name']) {
      case 'GLASS_BOTTLE':
        @magic_items['미약한 마법의 정수']['text'] = @text['space_fonts']['space.-1'].'\ue9ef'
        break()
      case 'STRING':
        @magic_items['변환의 끈']['text'] = @text['space_fonts']['space.-1'].'\uea1f'
        break()
      }
    }
    if(@level >= 60) {
      switch(@ingredient['name']) {
      case 'GLASS_BOTTLE':
        @magic_items['농축된 마법의 정수']['text'] = @text['space_fonts']['space.-1'].'\ue9ef'
        break()
      case 'STRING':
        @magic_items['놀라운 변환의 끈']['text'] = @text['space_fonts']['space.-1'].'\uea1f'
        break()
      }
    }
    if(@level >= 90) {
      switch(@ingredient['name']) {
      case 'GLASS_BOTTLE':
        @magic_items['강력한 마법의 정수']['text'] = @text['space_fonts']['space.-1'].'\ue9ef'
        break()
      case 'STRING':
        @magic_items['강력한 변환의 끈']['text'] = @text['space_fonts']['space.-1'].'\uea1f'
        break()
      }
    }
    if(@level >= 120) {
      switch(@ingredient['name']) {
      case 'PAPER':
        @magic_items['스킬 포인트 초기화 스크롤']['text'] = @text['space_fonts']['space.-1'].'\uea7f'
        break()
      }
    }
  }
  @line_0 = @text['space_fonts']['space.-1'].'\ue9c2'.@text['space_fonts']['space.-1'].'\ue9c1'.@text['space_fonts']['space.-1'].'\ue9c3'.@text['space_fonts']['space.-1'].'\ue9c1'.@text['space_fonts']['space.-1'].'\ue9c4'.@text['space_fonts']['space.-1'].'\ue9c1'.@text['space_fonts']['space.-108']
  @line_1 = @magic_items['미약한 마법의 정수']['text'].@text['space_fonts']['space.18'].@magic_items['농축된 마법의 정수']['text'].@text['space_fonts']['space.18'].@magic_items['강력한 마법의 정수']['text'].@text['space_fonts']['space.18'].@text['space_fonts']['space.-108']
  @line_2 = @magic_items['변환의 끈']['text'].@text['space_fonts']['space.18'].@magic_items['놀라운 변환의 끈']['text'].@text['space_fonts']['space.18'].@magic_items['강력한 변환의 끈']['text'].@text['space_fonts']['space.18'].@text['space_fonts']['space.-108']
  @line_3 = @text['space_fonts']['space.-1'].'\uea55'.@text['space_fonts']['space.-18']
  @line_4 = @magic_items['스킬 포인트 초기화 스크롤']['text'].@text['space_fonts']['space.-18']
  @texture_layer = @backgroundtext.@book_text.@line_0.@line_1.@line_2.@line_3.@line_4
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @block_location, @magic_items, @text) {
    bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @uuid, @id, @texture_layer, @block_location, @magic_items, @text) {
      @rawslot = @event['rawslot']
      @action = @event['action']
      @cursor_item = @event['cursoritem']
      if(@rawslot >= 0 && @rawslot <= 44) {
        if(@rawslot == 1) {
          @change_gui = false
          switch(@action) {
          case 'PLACE_ALL':
            if(is_null(@event['inventory'][1])) {
              @change_gui = true
            } else {
              @change_gui = false
            }
            break();
          case 'PLACE_ONE':
            @change_gui = true
            if(@cursor_item['qty'] > 1) {
              @cursor_item['qty'] -= 1
              @item = array_deep_clone(@cursor_item)
              @cursor_item['qty'] = 1
              modify_event('cursoritem', @cursor_item)
              @item['qty'] = pgive_item(@player, @item)
              @ploc = ploc(@player)
              @ploc['y'] += 1
              drop_item(@ploc, @item, false)
            }
            break();
          case 'PLACE_SOME':
            @change_gui = false
            break();
          case 'PICKUP_ALL':
            @change_gui = true
            @item = @event['inventory'][1]
            modify_event('slotitem', null)
            @item['qty'] = pgive_item(@player, @item)
            @ploc = ploc(@player)
            @ploc['y'] += 1
            drop_item(@ploc, @item, false)
            break();
          case 'PICKUP_HALF':
            @change_gui = true
            @slot_item = @event['inventory'][1]
            @half = floor(@slot_item['qty'] / 2)
            @slot_item['qty'] -= @half
            @item = array_deep_clone(@slot_item)
            @slot_item['qty'] = @half
            modify_event('slotitem', null)
            set_timeout(0, closure() {
              set_inventory_item(@id, 1, @slot_item)
            })
            @item['qty'] = pgive_item(@player, @item)
            @ploc = ploc(@player)
            @ploc['y'] += 1
            drop_item(@ploc, @item, false)
            break();
          case 'SWAP_WITH_CURSOR':
            @change_gui = true
            @item = @event['inventory'][1]
            modify_event('slotitem', null)
            @item['qty'] = pgive_item(@player, @item)
            @ploc = ploc(@player)
            @ploc['y'] += 1
            drop_item(@ploc, @item, false)
            break();
          case 'DROP_ONE_SLOT':
          case 'DROP_ALL_SLOT':
          case 'HOTBAR_SWAP':
          case 'HOTBAR_MOVE_AND_READD':
            if(is_null(@cursor_item)) {
              @change_gui = true
            } else {
              @change_gui = false
            }
            break();
          case 'MOVE_TO_OTHER_INVENTORY':
            if(is_null(@cursor_item)) {
              @change_gui = true
            } else {
              @change_gui = true
              @item = @cursor_item
              modify_event('cursoritem', null)
              set_timeout(0, closure() {
                @item['qty'] = pgive_item(@player, @item)
                @ploc = ploc(@player)
                @ploc['y'] += 1
                drop_item(@ploc, @item, false)
              })
            }
            break();
          default:
            @change_gui = false
            broadcast(@change_gui @event['action'] @cursor_item)
            break();
          }
          if(@change_gui) {
            unbind('close'.@id)
            set_timeout(1, closure() {
              @inventory = get_inventory(@id)
              _open_level_converter(@player, @uuid, @inventory, @block_location, @magic_items, @text)
            })
          }
        } else {
          cancel()
          @ingredient = @event['inventory'][1]
          @converting_level = 0
          if(!is_null(@ingredient) && @action == 'PICKUP_ALL' && is_null(@cursor_item)) {
            switch(@rawslot) {
            case 3:
              @magic_item = @magic_items['미약한 마법의 정수']
              @converting_level = 30
              break()
            case 5:
              @magic_item = @magic_items['농축된 마법의 정수']
              @converting_level = 60
              break()
            case 7:
              @magic_item = @magic_items['강력한 마법의 정수']
              @converting_level = 90
              break()
            case 12:
              @magic_item = @magic_items['변환의 끈']
              @converting_level = 30
              break()
            case 14:
              @magic_item = @magic_items['놀라운 변환의 끈']
              @converting_level = 60
              break()
            case 16:
              @magic_item = @magic_items['강력한 변환의 끈']
              @converting_level = 90
              break()
            case 30:
              @magic_item = @magic_items['스킬 포인트 초기화 스크롤']
              @converting_level = 120
              break()
            }
            if(@converting_level > 0 && @magic_item['text'] != @text['space_fonts']['space.18']) {
              unbind('close'.@id)
              @item = @ingredient
              @item['qty'] -= 1
              set_timeout(0, closure() {
                @item['qty'] = pgive_item(@player, @item)
                @ploc = ploc(@player)
                @ploc['y'] += 1
                drop_item(@ploc, @item, false)
              })
              close_pinv(@player)
              @location = array('x': @block_location['x'] + 0.5, 'y': @block_location['y'] + 1.01, 'z': @block_location['z'] + 0.5, 'world': @block_location['world'])
              set_pcooldown(@player, 'CAVE_AIR', @converting_level)
              @task = array('tick': integer(@converting_level / 3), 'id': null)
              @id = set_interval(100 , closure() {
                if(ponline(@player) && ploc(@player)['world'] == @block_location['world']) {
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
                    set_plevel(@player, plevel(@player) - @converting_level)
                    drop_item(@location, @magic_item, false)
                  }
                } else {
                  @item = @ingredient
                  @item['qty'] = 1
                  drop_item(@location, @item, false)
                  clear_task()
                }
              })
              @task['id'] = @id
            }
          }
        }
      } else if(@action == 'MOVE_TO_OTHER_INVENTORY') {
        if(!is_null(@cursor_item)) {
          @item = @cursor_item
          modify_event('cursoritem', null)
          set_timeout(0, closure() {
            @item['qty'] = pgive_item(@player, @item)
            @ploc = ploc(@player)
            @ploc['y'] += 1
            drop_item(@ploc, @item, false)
          })
        }
        unbind('close'.@id)
        set_timeout(0, closure() {
          @inventory = get_inventory(@id)
          _open_level_converter(@player, @uuid, @inventory, @block_location, @magic_items, @text)
        })
      }
    }
    #아이템 안뽑고 그냥 닫을시
    set_timeout(1, closure() {
      bind('inventory_close', array('id': 'close'.@id), array('player': @player, 'virtual': true), @event, @player, @uuid, @magic_items) {
        @item = @event['inventory'][1]
        if(!is_null(@item)) {
          @item['qty'] = pgive_item(@player, @item)
          @ploc = ploc(@player)
          @ploc['y'] += 1
          drop_item(@ploc, @item, false)
        }
      }
    })
  }
  _show_gui(@player, 'level_converter', 45, @texture_layer, '', @inventory, @closure, @block_location, @magic_items, @text)
}

proc _get_repair_result(@inventory, @ingredient_name) {
  @repairing_item = @inventory[1]
  @total_failure_probability = 0
  @ingredient_amount = 0
  for(@index = 4, @index < 9, @index++) {
    @ingredient = @inventory[@index]
    if(@ingredient['name'] == @ingredient_name) {
      @ingredient_amount += 1
      if(is_array(@ingredient['meta'])) {
        switch(@ingredient['meta']['model']) {
        case 1:
          @total_failure_probability += 30
          break()
        case 2:
          @total_failure_probability += 12
          break()
        case 3:
          @total_failure_probability += 3
          break()
        default:
          @total_failure_probability += 60
          break()
        }
      } else {
        @total_failure_probability += 60
      }
    }
  }
  for(@index = 13, @index < 18, @index++) {
    @ingredient = @inventory[@index]
    if(@ingredient['name'] == @ingredient_name) {
      @ingredient_amount += 1
      if(is_array(@ingredient['meta'])) {
        switch(@ingredient['meta']['model']) {
        case 1:
          @total_failure_probability += 30
          break()
        case 2:
          @total_failure_probability += 12
          break()
        case 3:
          @total_failure_probability += 3
          break()
        default:
          @total_failure_probability += 60
          break()
        }
      } else {
        @total_failure_probability += 60
      }
    }
  }
  #
  @max_durability = 0
  @failure_probability = null
  @success_probability = null
  if(@ingredient_amount != 0) {
    @max_durability = material_info(@repairing_item['name'], 'maxDurability')
    @durability = @max_durability - @repairing_item['meta']['damage']
    @failure_probability = @total_failure_probability / @ingredient_amount
    switch(@ingredient_amount) {
    case 1:
      @repairing_percentage = 5
      @breaking_percentage = 5
      break()55
    case 2:
      @repairing_percentage = 11
      @breaking_percentage = 10
      break()
    case 3:
      @repairing_percentage = 18
      @breaking_percentage = 15
      break()
    case 4:
      @repairing_percentage = 26
      @breaking_percentage = 20
      break()
    case 5:
      @repairing_percentage = 35
      @breaking_percentage = 25
      break()
    case 6:
      @repairing_percentage = 45
      @breaking_percentage = 30
      break()
    case 7:
      @repairing_percentage = 56
      @breaking_percentage = 35
      break()
    case 8:
      @repairing_percentage = 68
      @breaking_percentage = 40
      break()
    case 9:
      @repairing_percentage = 81
      @breaking_percentage = 45
      break()
    case 10:
      @repairing_percentage = 95
      @breaking_percentage = 50
      break()
    }
    @repairing_durability = integer(round(@repairing_percentage * 0.01 * @max_durability))
    @breaking_durability = integer(round(@breaking_percentage * 0.01 * @max_durability))
    # 실패시 아이템 세팅
    @failure_durability = @durability - @breaking_durability
    @failure_item = array_deep_clone(@repairing_item)
    @failure_item['meta']['damage'] = @max_durability - @failure_durability
    @failure_item['meta']['display'] = '§e수리 실패시,'
    if(@failure_durability < 1) {
      @oversized_failure_durability = @failure_durability * -1 + 1
      @penalty = @oversized_failure_durability / @max_durability * 10
      @failure_probability += @penalty
      @string_penalty = round(@penalty, 2).'%'
      @failure_item['meta']['lore'] = array(
        '§c아이템 파괴됨',
        ' §7'.@ingredient_amount.'개의 수리 재료를 사용하였으므로',
        ' §7수리 실패시, '.@breaking_durability.'('.@breaking_percentage.'%)'.'의 내구도가 감소합니다.',
        '§c수리 확률 -'.@string_penalty,
        ' §7수리 실패시, 아이템이 파괴될 정도로',
        ' §7많은 양의 수리 재료를 사용하여',
        ' §7수리 확률 패널티가 부과됩니다.'
      )
    } else {
      @failure_item['meta']['lore'] = array(
        '§c내구도 -'.@breaking_durability.'('.@breaking_percentage.'%)',
        ' §7'.@ingredient_amount.'개의 수리 재료를 사용하였으므로',
        ' §7수리 실패시, '.@breaking_durability.'('.@breaking_percentage.'%)의 내구도가 감소합니다.'
      )
    }
    @success_durability = @durability + @repairing_durability
    @success_item = array_deep_clone(@repairing_item)
    @success_item['meta']['damage'] = @max_durability - @success_durability
    @success_item['meta']['display'] = '§e수리 성공시,'
    if(@success_durability >= @max_durability) {
      @oversized_success_durability = @success_durability - @max_durability + 1
      @bonus = @oversized_success_durability / @max_durability * 10
      @failure_probability -= @bonus
      @string_bonus = round(@bonus, 2).'%'
      @success_item['meta']['lore'] = array(
        '§a아이템 완벽히 수리됨',
        ' §7'.@ingredient_amount.'개의 수리 재료를 사용하였으므로',
        ' §7수리 성공시, '.@repairing_durability.'('.@repairing_percentage.'%)의 내구도가 증가합니다.',
        '§a수리 확률 +'.@string_bonus,
        ' §7수리 성공시, 아이템이 완벽히 수리될 정도로',
        ' §7많은 양의 수리 재료를 사용하여',
        ' §7수리 확률 보너스가 추가됩니다.'
      )
    } else {
      @success_item['meta']['lore'] = array(
        '§a내구도 +'.@repairing_durability.'('.@repairing_percentage.'%)',
        ' §7'.@ingredient_amount.'개의 수리 재료를 사용하였으므로',
        ' §7수리 성공시, '.@repairing_durability.'('.@repairing_percentage.'%)의 내구도가 증가합니다.'
      )
    }
    @return = array(
      'failure_probability': @failure_probability,
      'repairing_durability': @repairing_durability,
      'breaking_durability': @breaking_durability,
      'success_item': @success_item,
      'failure_item': @failure_item
    )
  } else {
    @return = array(
      'failure_probability': null,
      'repairing_durability': null,
      'breaking_durability': null,
      'success_item': null,
      'failure_item': null
    )
  }
  return(@return)
}

proc _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text) {
  if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
    # presets
    @repairable_items = array(
      # 가죽
      'LEATHER_BOOTS': array('model': 13,'ingredient': 'LEATHER'),
      # 구리
      'CHAINMAIL_BOOTS': array('model': 11, 'ingredient': 'GOLD_NUGGET'),
      'STONE_SWORD': array('model': 11, 'ingredient': 'GOLD_NUGGET'),
      'STONE_SHOVEL': array('model': 11, 'ingredient': 'GOLD_NUGGET'),
      'STONE_PICKAXE': array('model': 11, 'ingredient': 'GOLD_NUGGET'),
      'STONE_AXE': array('model': 11, 'ingredient': 'GOLD_NUGGET'),
      'STONE_HOE': array('model': 11, 'ingredient': 'GOLD_NUGGET'),
      # 철
      'IRON_BOOTS': array('model': 11, 'ingredient': 'IRON_INGOT'),
      'IRON_SWORD': array('model': 11, 'ingredient': 'IRON_INGOT'),
      'IRON_SHOVEL': array('model': 11, 'ingredient': 'IRON_INGOT'),
      'IRON_PICKAXE': array('model': 11, 'ingredient': 'IRON_INGOT'),
      'IRON_AXE': array('model': 11, 'ingredient': 'IRON_INGOT'),
      'IRON_HOE': array('model': 11, 'ingredient': 'IRON_INGOT'),
      # 금
      'GOLDEN_BOOTS': array('model': 11, 'ingredient': 'GOLD_INGOT'),
      'GOLDEN_SWORD': array('model': 11, 'ingredient': 'GOLD_INGOT'),
      'GOLDEN_SHOVEL': array('model': 11, 'ingredient': 'GOLD_INGOT'),
      'GOLDEN_PICKAXE': array('model': 11, 'ingredient': 'GOLD_INGOT'),
      'GOLDEN_AXE': array('model': 11, 'ingredient': 'GOLD_INGOT'),
      'GOLDEN_HOE': array('model': 11, 'ingredient': 'GOLD_INGOT'),
      # 다이아몬드
      'DIAMOND_BOOTS': array('model': 12, 'ingredient': 'DIAMOND'),
      'DIAMOND_SWORD': array('model': 12, 'ingredient': 'DIAMOND'),
      'DIAMOND_SHOVEL': array('model': 12, 'ingredient': 'DIAMOND'),
      'DIAMOND_PICKAXE': array('model': 12, 'ingredient': 'DIAMOND'),
      'DIAMOND_AXE': array('model': 12, 'ingredient': 'DIAMOND'),
      'DIAMOND_HOE': array('model': 12, 'ingredient': 'DIAMOND'),
      'TRIDENT': array('model': 12, 'ingredient': 'DIAMOND'),
      # 네더라이트
      'NETHERITE_BOOTS': array('model': 11, 'ingredient': 'NETHERITE_INGOT'),
      'NETHERITE_SWORD': array('model': 11, 'ingredient': 'NETHERITE_INGOT'),
      'NETHERITE_SHOVEL': array('model': 11, 'ingredient': 'NETHERITE_INGOT'),
      'NETHERITE_PICKAXE': array('model': 11, 'ingredient': 'NETHERITE_INGOT'),
      'NETHERITE_AXE': array('model': 11, 'ingredient': 'NETHERITE_INGOT'),
      'NETHERITE_HOE': array('model': 11, 'ingredient': 'NETHERITE_INGOT')
    )
    @repairing_item_slot = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§7수리할 아이템을 넣어주세요',
        'model': 10
      )
    )
    @ingredient_slot = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§7재료 아이템을 넣어주세요',
        'model': 1
      )
    )
    @actvated_repair_button = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§b수리',
        'lore': array(
          '§7좌클릭 시, 아이템을 수리합니다',
          '',
          '§c수리 확률과 수리 결과를',
          '§c잘 확인한 후 수리하세요!'
        ),
        'model': 14
      )
    )
    @unactvated_repair_button = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§8수리',
        'lore': array(
          '§7수리할 아이템과 수리 재료를 넣을 시,',
          '§7수리 버튼이 활성화됩니다.',
        ),
        'model': 1
      )
    )
    @actvated_refresh_button = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§b수리 결과 새로고침',
        'lore': array(
          '§7좌클릭 시, 수리 성공/실패 확률과',
          '§7수리 성공 여부에 따른 수리 후의',
          '§7아이템 상태를 확인할 수 있습니다.',
          '',
          '§7수리 재료의 변화가 감지되었습니다.',
          '§c좌클릭하여 수리 결과를 새로고침 해주세요!',
        ),
        'model': 8
      )
    )
    @unactvated_refresh_button = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§8수리 결과 새로고침',
        'lore': array(
          '§7좌클릭 시, 수리 성공/실패 확률과',
          '§7수리 성공 여부에 따른 수리 후의',
          '§7아이템 상태를 확인할 수 있습니다.'
        ),
        'model': 1
      )
    )
    # item return
    if(!@is_refresh) {
      for(@index = 4, @index < 9, @index++) {
        @return_item = @inventory[@index]
        if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
          @return_item['qty'] = pgive_item(@player, @return_item)
          @ploc = ploc(@player)
          @ploc['y'] += 1
          drop_item(@ploc, @return_item, false)
        }
        @inventory[@index] = array(
          'name': 'STRUCTURE_VOID',
          'meta': array(
            'display': ' ',
            'model': 1
          )
        )
      }
      for(@index = 13, @index < 18, @index++) {
        @return_item = @inventory[@index]
        if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
          @return_item['qty'] = pgive_item(@player, @return_item)
          @ploc = ploc(@player)
          @ploc['y'] += 1
          drop_item(@ploc, @return_item, false)
        }
        @inventory[@index] = array(
          'name': 'STRUCTURE_VOID',
          'meta': array(
            'display': ' ',
            'model': 1
          )
        )
      }
      # result item reset
      @inventory[32] =array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': ' ',
          'model': 1
        )
      )
      @inventory[34] = array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': ' ',
          'model': 1
        )
      )
    }
    # setting
    @ingredient_name = null
    @backgroundtext = @text['space_fonts']['space.-8'].'\ue3fc'.@text['space_fonts']['space.-169']
    @open_slot = @text['space_fonts']['space.18']
    @close_slot_1 = @text['space_fonts']['space.-1'].'\ue540'
    @close_slot_2 = @text['space_fonts']['space.-1'].'\ue5a0'
    @line_1_qty = 0
    @line_2_qty = 0
    if(is_null(@inventory[1])) { // 빈칸일시
      @inventory[1] = @repairing_item_slot
    } else if(array_index_exists(@repairable_items, @inventory[1]['name']) && @inventory[1]['meta']['damage'] > 0) { // 아이템이 놓였을 시
      # 아이템에 따른 필요 재료 설정
      @ingredient_slot['meta']['model'] = @repairable_items[@inventory[1]['name']]['model']
      @ingredient_name = @repairable_items[@inventory[1]['name']]['ingredient']
      @line_1_qty = 5
      @line_2_qty = 5
      # 재료칸 세팅
      if(!@is_refresh) {
        for(@index = 4, @index < 9, @index++) {
          @inventory[@index] = @ingredient_slot
        }
        for(@index = 13, @index < 18, @index++) {
          @inventory[@index] = @ingredient_slot
        }
      }
      /* 내구도에 따른 최대 재료 갯수 설정하는 코드
        @max_durability = material_info(@inventory[1]['name'], 'maxDurability')
        @damage = @inventory[1]['meta']['damage']
        @repairable_qty = ceil(@damage / @max_durability * 10)
        @quota = integer(@repairable_qty / 5)
        @rest = @repairable_qty % 5
        switch(@quota) {
        case 0:
          @line_1_qty = @rest
          @line_2_qty = 0
          if(!@is_refresh) {
            for(@index = 4, @index < 4 + @rest, @index++) {
              @inventory[@index] = @ingredient_slot
            }
          }
          break()
        case 1:
          @line_1_qty = 5
          @line_2_qty = @rest
          if(!@is_refresh) {
            for(@index = 4, @index < 9, @index++) {
              @inventory[@index] = @ingredient_slot
            }
            for(@index = 13, @index < 13 + @rest, @index++) {
              @inventory[@index] = @ingredient_slot
            }
          }
          break()
        case 2:
          @line_1_qty = 5
          @line_2_qty = 5
          if(!@is_refresh) {
            for(@index = 4, @index < 9, @index++) {
              @inventory[@index] = @ingredient_slot
            }
            for(@index = 13, @index < 18, @index++) {
              @inventory[@index] = @ingredient_slot
            }
          }
          break()
        }
      */
    }
    @line_1 = string_multiply(@open_slot, @line_1_qty).string_multiply(@close_slot_1, 5 - @line_1_qty)
    @line_2 = string_multiply(@open_slot, @line_2_qty).string_multiply(@close_slot_2, 5 - @line_2_qty)
    @title_text = _color('#404040').'수리할 아이템'.@text['space_fonts']['space.22']._color('#404040').'수리 재료'.color('white')
    if(!is_null(@rounded_failure_probability)) {
      if(@is_refresh) {
        @percent_text = @text['space_fonts']['space.-16'].''._replace_repair_percent(@rounded_failure_probability).''.@text['space_fonts']['space.20'].''._replace_repair_percent(@rounded_success_probability)
      } else {
        @percent_text = ''
      }
    } else {
      @percent_text = ''
    }
    @inventory[18]['meta']['model'] = 7
    if(@inventory[37]['meta']['model'] == 1) {
      @inventory[37] = @unactvated_repair_button
    }
    if(@inventory[44]['meta']['model'] == 1) {
      @inventory[44] = @unactvated_refresh_button
    }
    @texture_layer = @backgroundtext.@text['space_fonts']['space.72'].@line_1.@text['space_fonts']['space.-90'].@line_2.@text['space_fonts']['space.-162'].@title_text.@percent_text
    @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @ingredient_name, @repairable_items, @repairing_item_slot, @ingredient_slot, @actvated_repair_button, @unactvated_repair_button, @actvated_refresh_button, @unactvated_refresh_button, @rounded_failure_probability, @rounded_success_probability, @block_location, @text) {
      bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @uuid, @id, @texture_layer, @ingredient_name, @repairable_items, @repairing_item_slot, @ingredient_slot, @actvated_repair_button, @unactvated_repair_button, @actvated_refresh_button, @unactvated_refresh_button, @rounded_failure_probability, @rounded_success_probability, @block_location, @text) {
        @rawslot = @event['rawslot']
        @action = @event['action']
        @cursor_item = @event['cursoritem']
        if(@rawslot >= 0 && @rawslot <= 44) {
          @slot_item = @event['inventory'][@rawslot]
          @return_items = array()
          switch(@rawslot) {
          case 1: // repairing item
            switch(@action) {
            case 'SWAP_WITH_CURSOR':
              if(!is_null(@cursor_item) && array_index_exists(@repairable_items, @cursor_item['name'])) { // 도구를 들고 있을시
                if(array_index_exists(@repairable_items, @slot_item['name'])) { // 슬롯에 도구가 있었을시
                  @change_gui = true
                  @return_items[] = array_deep_clone(@slot_item)
                  modify_event('slotitem', null)
                } else { // 슬롯이 빈칸일 시
                  @change_gui = true
                  modify_event('slotitem', null)
                }
              } else { // 도구를 들고 있지 않을 시
                @change_gui = false
                cancel()
              }
              break()
            case 'PICKUP_ALL':
            case 'PICKUP_HALF':
              if(array_index_exists(@repairable_items, @slot_item['name'])) { // 도구를 꺼냈을 시
                @change_gui = true
                @return_items[] = array_deep_clone(@slot_item)
                modify_event('slotitem', null)
              } else { // 빈칸 클릭시
                @change_gui = false
                cancel()
              }
              break()
            case 'DROP_ONE_SLOT':
            case 'DROP_ALL_SLOT':
              if(is_null(@cursor_item)) {
                if(array_index_exists(@repairable_items, @slot_item['name'])) {
                  @change_gui = true
                } else {
                  @change_gui = false
                  cancel()
                }
              } else {
                @change_gui = false
              }
              break()
            case 'HOTBAR_SWAP':
            case 'HOTBAR_MOVE_AND_READD':
              if(is_null(@cursor_item)) {
                @swapslot = @event['hotbarbutton']
                if(@event['hotbarbutton'] == -1 ) { @swapslot = 40 }
                @swap_item = get_inventory_item(@uuid, @swapslot)
                if(array_index_exists(@repairable_items, @slot_item['name'])) {
                  if(!is_null(@swap_item)) {
                    if(array_index_exists(@repairable_items, @swap_item['name'])) {
                      @change_gui = true  // gui 도구 | 스왑 도구
                    } else {
                      @change_gui = false // gui 도구 | 스왑 기타
                      cancel()
                    }
                  } else {
                    @change_gui = true    // gui 도구 | 스왑 빈칸
                    cancel()
                    set_inventory_item(@id, @rawslot, @repairing_item_slot)
                    set_inventory_item(@uuid, @swapslot, @slot_item)
                  }
                } else {
                  if(!is_null(@swap_item)) {
                    if(array_index_exists(@repairable_items, @swap_item['name'])) {
                      @change_gui = true  // gui 빈칸 | 스왑 도구
                      modify_event('slotitem', null)
                    } else {
                      @change_gui = false // gui 빈칸 | 스왑 기타
                      cancel()
                    }
                  } else {
                    @change_gui = false   // gui 빈칸 | 스왑 빈칸
                    cancel()
                  }
                }
              } else {
                @change_gui = false
              }
              break()
            case 'MOVE_TO_OTHER_INVENTORY':
              if(array_index_exists(@repairable_items, @slot_item['name'])) {
                if(is_null(@cursor_item)) {
                  @change_gui = true
                } else {
                  @change_gui = true
                  @return_items[] = @cursor_item
                  modify_event('cursoritem', null)
                }
              } else {
                @change_gui = false
                cancel()
              }
              break();
            default:
              @change_gui = false
              cancel()
              break() 
            }
            if(@change_gui) {
              foreach(@return_item in @return_items) {
                if(!is_null(@return_item)) {
                  @return_item['qty'] = pgive_item(@player, @return_item)
                  @ploc = ploc(@player)
                  @ploc['y'] += 1
                  drop_item(@ploc, @return_item, false)
                }
              }
              if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                unbind('close'.@id)
              }
              set_timeout(1, closure() {
                @inventory = get_inventory(@id)
                @is_refresh = false
                _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text)
              })
            }
            break()
          case 4..8:
          case 13..17: // ingredient
            if(!(@slot_item['name'] == 'STRUCTURE_VOID' && @slot_item['meta']['model'] == 1)) { // 재료를 놓을 수 있는 칸일 시
              switch(@action) {
              case 'SWAP_WITH_CURSOR':
                @cursor_item_copy = array_deep_clone(@cursor_item)
                if(!is_null(@cursor_item) && @cursor_item['name'] == @ingredient_name) { // 재료를 들고 있을시
                  if(@slot_item['name'] == @ingredient_name) { // 슬롯에 재료가 있었을시
                    if(@cursor_item['qty'] == 1) { // 아이템 하나만 들고 있을시 (커서랑 슬롯이랑 스왑시키는 용도)
                      @change_ingredient = true
                    } else {
                      @change_ingredient = false
                      cancel()
                    }
                  } else { // 슬롯이 빈칸일 시
                    @change_ingredient = true
                    @cursor_item['qty'] = 1
                    @cursor_item_copy['qty'] = 63
                    modify_event('slotitem', @cursor_item_copy)
                    set_timeout(1, closure() {
                      set_inventory_item(@id, @rawslot, @cursor_item)
                    })
                  }
                } else { // 재료를 들고 있지 않을 시
                  @change_ingredient = false
                  cancel()
                }
                break()
              case 'PICKUP_ALL':
              case 'PICKUP_HALF':
                if(@slot_item['name'] == @ingredient_name) {
                  @change_ingredient = true
                  set_timeout(1, closure() {
                    set_inventory_item(@id, @rawslot, @ingredient_slot)
                  })
                } else {
                  @change_ingredient = false
                  cancel()
                }
                break()
              case 'DROP_ONE_SLOT':
              case 'DROP_ALL_SLOT':
                if(is_null(@cursor_item)) {
                  if(@slot_item['name'] == @ingredient_name) {
                    @change_ingredient = true
                    set_timeout(1, closure() {
                      set_inventory_item(@id, @rawslot, @ingredient_slot)
                    })
                  } else {
                    @change_ingredient = false
                    cancel()
                  }
                } else {
                  @change_ingredient = false
                }
                break()
              case 'HOTBAR_SWAP':
              case 'HOTBAR_MOVE_AND_READD':
                if(is_null(@cursor_item)) {
                  @swapslot = @event['hotbarbutton']
                  if(@event['hotbarbutton'] == -1 ) { @swapslot = 40 }
                  @swap_item = get_inventory_item(@uuid, @swapslot)
                  if(@slot_item['name'] == @ingredient_name) {
                    if(!is_null(@swap_item)) {
                      if(@swap_item['name'] == @ingredient_name) {
                        if(@swap_item['qty'] == 1) {
                          @change_ingredient = true   // gui 재료 | 스왑 재료 1개
                        } else {
                          @change_ingredient = false  // gui 재료 | 스왑 재료 n개
                          cancel()
                        }
                      } else {
                        @change_ingredient = false    // gui 재료 | 스왑 기타
                        cancel()
                      }
                    } else {
                      @change_ingredient = true       // gui 재료 | 스왑 빈칸
                      cancel()
                      set_inventory_item(@id, @rawslot, @ingredient_slot)
                      set_inventory_item(@uuid, @swapslot, @slot_item)
                    }
                  } else {
                    if(!is_null(@swap_item)) {
                      if(@swap_item['name'] == @ingredient_name) {
                        if(@swap_item['qty'] == 1) {
                          @change_ingredient = true   // gui 빈칸 | 스왑 재료 1개
                          cancel()
                          set_inventory_item(@id, @rawslot, @swap_item)
                          set_inventory_item(@uuid, @swapslot, null)
                        } else {
                          @change_ingredient = true  // gui 빈칸 | 스왑 재료 n개
                          cancel()
                          @swap_item['qty'] -= 1
                          @swap_item_copy = array_deep_clone(@swap_item)
                          @swap_item_copy['qty'] = 1
                          set_inventory_item(@id, @rawslot, @swap_item_copy)
                          set_inventory_item(@uuid, @swapslot, @swap_item)
                        }
                      } else {
                        @change_ingredient = false    // gui 빈칸 | 스왑 기타
                        cancel()
                      }
                    } else {
                      @change_ingredient = false      // gui 빈칸 | 스왑 빈칸
                      cancel()
                    }
                  }
                } else {
                  @change_ingredient = false
                }
                break()
              case 'MOVE_TO_OTHER_INVENTORY':
                if(@slot_item['name'] == @ingredient_name) {
                  @change_ingredient = true
                  set_timeout(1, closure() {
                    set_inventory_item(@id, @rawslot, @ingredient_slot)
                  })
                } else {
                  @change_ingredient = false
                  cancel()
                }
                break();
              default:
                @change_ingredient = false
                cancel()
                break() 
              }
              if(@change_ingredient) {
                set_timeout(1, closure() {
                  @inventory = get_inventory(@id)
                  @is_repairable = false
                  for(@index = 4, @index < 9, @index++) {
                    if(is_null(@inventory[@index])) {
                      set_inventory_item(@id, @index, @ingredient_slot)
                    } else if(@inventory[@index]['name'] == @ingredient_name) {
                      @is_repairable = true
                    }
                  }
                  for(@index = 13, @index < 18, @index++) {
                    if(is_null(@inventory[@index])) {
                      set_inventory_item(@id, @index, @ingredient_slot)
                    } else if(@inventory[@index]['name'] == @ingredient_name) {
                      @is_repairable = true
                    }
                  }
                  if(@is_repairable) {
                    set_inventory_item(@id, 37, @actvated_repair_button)
                  } else {
                    set_inventory_item(@id, 37, @unactvated_repair_button)
                  }
                  set_inventory_item(@id, 44, @actvated_refresh_button)
                })
              }
            } else {
              cancel()
            }
            break()
          case 37: // repair button
            cancel()
            if(@action == 'PICKUP_ALL' && @slot_item['meta']['model'] == 14) {
              @inventory = get_inventory(@id)
              @repairing_item = @inventory[1]
              # copy
              @repairing_item_copy = array_deep_clone(@repairing_item)
              @ingredients = array()
              for(@index = 4, @index < 9, @index++) {
                @ingredient = @inventory[@index]
                if(@ingredient['name'] == @ingredient_name) {
                  @ingredients[] = @ingredient
                }
              }
              for(@index = 13, @index < 18, @index++) {
                @ingredient = @inventory[@index]
                if(@ingredient['name'] == @ingredient_name) {
                  @ingredients[] = @ingredient
                }
              }
              # result
              @return = _get_repair_result(@inventory, @ingredient_name)
              if(rand() > @return['failure_probability'] * 0.01) {
                @is_success = true
              } else {
                @is_success = false
              }
              if(@is_success) { // 성공
                @repairing_item['meta']['damage'] -= @return['repairing_durability']
                if(@repairing_item['meta']['damage'] < 0) { @repairing_item['meta']['damage'] = 0 }
                @result = @repairing_item
              } else { // 실패
                @repairing_item['meta']['damage'] += @return['breaking_durability']
                if(@repairing_item['meta']['damage'] >= material_info(@repairing_item['name'], 'maxDurability')) { 
                  @result = null
                } else {
                  @result = @repairing_item
                }
              }
              if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                unbind('close'.@id)
                for(@i = 5, @i > 0, @i --) {
                  if(@i > 1) {
                    queue_push(closure() {
                      @particle_location = array('x': @block_location['x'] + 0.5, 'y': @block_location['y'] + 1, 'z': @block_location['z'] + 0.5, 'world': @block_location['world'])
                      if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                        play_named_sound(@particle_location, array('sound': 'block.anvil.land', 'category': 'BLOCKS', 'volume': 2, 'pitch': 1.7))
                        mom_playerparticle(@uuid, 'LAVA', @particle_location['x'], @particle_location['y'], @particle_location['z'], 5, 0.0, 0.0, 0.0, 0.0)
                      } else {
                        queue_clear('anvil.'.@player)
                        @return_item = @repairing_item_copy
                        if(!is_null(@return_item)) {
                          drop_item(@particle_location, @return_item, false)
                        }
                        foreach(@return_item in @ingredients) {
                          drop_item(@particle_location, @return_item, false)
                        }
                      }
                    }, 'anvil.'.@player)
                    queue_delay(1000, 'anvil.'.@player)
                  } else {
                    queue_push(closure() {
                      @particle_location = array('x': @block_location['x'] + 0.5, 'y': @block_location['y'] + 1, 'z': @block_location['z'] + 0.5, 'world': @block_location['world'])
                      if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                        play_named_sound(@particle_location, array('sound': 'block.anvil.land', 'category': 'BLOCKS', 'volume': 2, 'pitch': 1.7))
                        mom_playerparticle(@uuid, 'LAVA', @particle_location['x'], @particle_location['y'], @particle_location['z'], 5, 0.0, 0.0, 0.0, 0.0)
                        if(@is_success) {
                          play_named_sound(@particle_location, array('sound': 'entity.experience_orb.pickup', 'category': 'BLOCKS', 'volume': 2, 'pitch': 1))
                          mom_playerparticle(@uuid, 'FIREWORKS_SPARK', @particle_location['x'], @particle_location['y'], @particle_location['z'], 5, 0.1, 0.1, 0.1, 0.1)
                        } else {
                          play_named_sound(@particle_location, array('sound': 'entity.item.break', 'category': 'BLOCKS', 'volume': 2, 'pitch': 1))
                          mom_playerparticle(@uuid, 'CLOUD', @particle_location['x'], @particle_location['y'], @particle_location['z'], 5, 0.1, 0.1, 0.1, 0.1)
                        }
                        @return_item = @result
                        if(!is_null(@return_item)) {
                          drop_item(@particle_location, @return_item, false)
                        }
                      } else {
                        queue_clear('anvil.'.@player)
                        @return_item = @repairing_item_copy
                        if(!is_null(@return_item)) {
                          drop_item(@particle_location, @return_item, false)
                        }
                        foreach(@return_item in @ingredients) {
                          drop_item(@particle_location, @return_item, false)
                        }
                      }
                    }, 'anvil.'.@player)
                  }
                }
              }
            }
            close_pinv(@player)
            break()
          case 44: // refresh
            cancel()
            if(@action == 'PICKUP_ALL' && @slot_item['meta']['model'] == 8) {
              @inventory = get_inventory(@id)
              @return = _get_repair_result(@inventory, @ingredient_name)
              if(!is_null(@return['failure_probability'])) {
                @rounded_failure_probability = integer(round(@return['failure_probability']))
                @rounded_success_probability = integer(100 - @rounded_failure_probability)
                @inventory[32] = @return['failure_item']
                @inventory[34] = @return['success_item']
              } else {
                @rounded_failure_probability = null
                @rounded_success_probability = null
                @inventory[32] =array(
                  'name': 'STRUCTURE_VOID',
                  'meta': array(
                    'display': ' ',
                    'model': 1
                  )
                )
                @inventory[34] = array(
                  'name': 'STRUCTURE_VOID',
                  'meta': array(
                    'display': ' ',
                    'model': 1
                  )
                )
              }
              @inventory[44] = @unactvated_refresh_button
              if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                unbind('close'.@id)
              }
              set_timeout(1, closure() {
                @is_refresh = true
                _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text)
              })
            }
            break()
          default:
            cancel()
            break()
          }
        } else if(45 <= @rawslot && @rawslot <= 80) {
          @slot = @event['slot']
          @inventory = get_inventory(@id)
          @pinventory = pinv(@player)
          @old_slot_item = @pinventory[@slot]
          switch(@action) {
          case 'MOVE_TO_OTHER_INVENTORY':
            if(array_index_exists(@repairable_items, @old_slot_item['name'])) {
              if(@inventory[1]['name'] == 'STRUCTURE_VOID') {
                @inventory[1] = @old_slot_item
                set_pinv(@player, @slot, null)
                if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                  unbind('close'.@id)
                }
                set_timeout(1, closure() {
                  @is_refresh = false
                  _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text)
                })
              } else {
                cancel()
              }
            } else {
              cancel()
            }
            break()
          case 'COLLECT_TO_CURSOR':
            if(@cursor_item['name'] == @ingredient_name) {
              set_timeout(1, closure() {
                @inventory = get_inventory(@id)
                @is_repairable = false
                for(@index = 4, @index < 9, @index++) {
                  if(is_null(@inventory[@index])) {
                    set_inventory_item(@id, @index, @ingredient_slot)
                  } else if(@inventory[@index]['name'] == @ingredient_name) {
                    @is_repairable = true
                  }
                }
                for(@index = 13, @index < 18, @index++) {
                  if(is_null(@inventory[@index])) {
                    set_inventory_item(@id, @index, @ingredient_slot)
                  } else if(@inventory[@index]['name'] == @ingredient_name) {
                    @is_repairable = true
                  }
                }
                if(@is_repairable) {
                  set_inventory_item(@id, 37, @actvated_repair_button)
                } else {
                  set_inventory_item(@id, 37, @unactvated_repair_button)
                }
                set_inventory_item(@id, 44, @actvated_refresh_button)
              })
            }
            break()
          }
        }
      }
      #아이템 안뽑고 그냥 닫을시
      set_timeout(1, closure() {
        bind('inventory_drag', array('id': 'drag'.@id), array('player': @player, 'virtual': true), @event, @player, @uuid) {
          @indexs = array_keys(@event['newitems'])
          foreach(@index in @indexs) {
            if(@index <  45) {
              cancel()
            }
          }
        }
        bind('inventory_close', array('id': 'close'.@id), array('player': @player, 'virtual': true), @event, @player, @uuid) {
          @inventory = @event['inventory']
          @return_item = @inventory[1]
          if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
            @return_item['qty'] = pgive_item(@player, @return_item)
            @ploc = ploc(@player)
            @ploc['y'] += 1
            drop_item(@ploc, @return_item, false)
          }
          for(@index = 4, @index < 9, @index++) {
            @return_item = @inventory[@index]
            if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
              @return_item['qty'] = pgive_item(@player, @return_item)
              @ploc = ploc(@player)
              @ploc['y'] += 1
              drop_item(@ploc, @return_item, false)
            }
          }
          for(@index = 13, @index < 18, @index++) {
            @return_item = @inventory[@index]
            if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
              @return_item['qty'] = pgive_item(@player, @return_item)
              @ploc = ploc(@player)
              @ploc['y'] += 1
              drop_item(@ploc, @return_item, false)
            }
          }
        }
      })
    }
    _show_gui(@player, 'anvil', 45, @texture_layer, '', @inventory, @closure, @ingredient_name, @repairable_items, @repairing_item_slot, @ingredient_slot, @actvated_repair_button, @unactvated_repair_button, @actvated_refresh_button, @unactvated_refresh_button, @rounded_failure_probability, @rounded_success_probability, @block_location, @text)
  } else {
    close_pinv(@player)
  }
}

bind('player_interact', null, null, @event, @players_data, @hp_blocks, @skills_spec, @essences, @server, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  @player_data = @players_data[@uuid]
  if(@event['button'] == 'right') {
    # equip armor
    @armors = array(
      'LEATHER_BOOTS',
      'CHAINMAIL_BOOTS',
      'IRON_BOOTS',
      'GOLDEN_BOOTS',
      'DIAMOND_BOOTS',
      'NETHERITE_BOOTS'
    )
    if(!is_cancelled() && is_null(get_inventory_item(@uuid, 36)) && !is_null(@event['item']) && array_contains(@armors, @event['item']['name'])) {
      _update_item(@player, @uuid, array('armor': @event['item']), @player_data, @skills_spec, @text)
    }
    # use item
    @is_item_available = false
    if(@event['hand'] == 'main_hand' && !is_null(@event['item'])) {
      @is_item_available = true
    }
    # block interacting
    if(@event['action'] == 'right_click_block') {
      # 블럭 사용
      switch(@event['block']) {
      # BANNED BLOCKS
      case 'END_PORTAL_FRAME':
      //case 'ENDER_CHEST':
      case 'GRINDSTONE':
      case 'SWEET_BERRY_BUSH':
      case 'BREWING_STAND':
      //case 'FLETCHING_TABLE': // 기능 없음
        if(!psneaking(@player) || (is_null(get_inventory_item(@uuid, pheld_slot(@player))) && is_null(get_inventory_item(@uuid, 40)))) {
          cancel() // 사용 금지
        }
        break()
      # COSTOMED BLOCKS
      case 'ANVIL':
      case 'CHIPPED_ANVIL':
      case 'DAMAGED_ANVIL':
        if(!psneaking(@player)) {
          if(@is_item_available) {
            @is_item_available = false
          }
        }
        if(!psneaking(@player) || (is_null(get_inventory_item(@uuid, pheld_slot(@player))) && is_null(get_inventory_item(@uuid, 40)))) {
          cancel()
          @inventory = array()
          for(@index = 0, @index < 45, @index++) {
            @inventory[@index] = array(
              'name': 'STRUCTURE_VOID',
              'meta': array(
                'display': ' ',
                'model': 1
              )
            )
          }
          @inventory[1] = null
          # proc
          @rounded_failure_probability = null
          @rounded_success_probability = null
          @is_refresh = false
          @block_location = @event['location']
          _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text)
        }
        break()
      case 'SMITHING_TABLE':
        if(!psneaking(@player)) {
          if(@is_item_available) {
            @is_item_available = false
          }
        }
        if(!psneaking(@player) || (is_null(get_inventory_item(@uuid, pheld_slot(@player))) && is_null(get_inventory_item(@uuid, 40)))) {
          cancel()
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
              @texture_layer = @text['space_fonts']['space.-8'].'§f\ue3fb'.@text['space_fonts']['space.-169']._color('#404040')
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
        if(!psneaking(@player)) {
          if(@is_item_available) {
            @is_item_available = false
          }
        }
        if(!psneaking(@player) || (is_null(get_inventory_item(@uuid, pheld_slot(@player))) && is_null(get_inventory_item(@uuid, 40)))) {
          cancel()
          if(pcooldown(@player, 'CAVE_AIR') == 0) {
            @magic_items = array(
              '미약한 마법의 정수': array_deep_clone(@essences['미약한 마법의 정수']['item']),
              '농축된 마법의 정수': array_deep_clone(@essences['농축된 마법의 정수']['item']),
              '강력한 마법의 정수': array_deep_clone(@essences['강력한 마법의 정수']['item']),
              '변환의 끈': array(
                'name': 'ENCHANTED_BOOK',
                'meta': array(
                  'display': '§b변환의 끈',
                  'lore': array(
                    '§7이 마법의 끈으로 비법서를 묶을 시,',
                    '§7비법서의 스킬 종류가 변환됩니다.',
                    '',
                    '§7같은 카테고리의 스킬로만 변환됩니다.',
                    '§7변환 후 스크롤의 레벨이 미약하게 감소합니다.'
                  ),
                  'model': 2
                )
              ),
              '놀라운 변환의 끈': array(
                'name': 'ENCHANTED_BOOK',
                'meta': array(
                  'display': '§b놀라운 변환의 끈',
                  'lore': array(
                    '§7이 마법의 끈으로 비법서를 묶을 시,',
                    '§7비법서의 스킬 종류가 변환됩니다.',
                    '',
                    '§7다른 카테고리의 스킬로 변환될 수 있습니다.',
                    '§7변환 후 스크롤의 레벨이 약간 감소합니다.'
                  ),
                  'model': 3
                )
              ),
              '강력한 변환의 끈': array(
                'name': 'ENCHANTED_BOOK',
                'meta': array(
                  'display': '§b강력한 변환의 끈',
                  'lore': array(
                    '§7이 마법의 끈으로 비법서를 묶을 시,',
                    '§7비법서의 레벨이 변환됩니다.',
                    '',
                    '§7다른 변환의 끈과 달리,',
                    '§7스킬의 종류가 변환되지 않는 대신 ',
                    '§7변환 후, 스크롤의 레벨이 감소되거나',
                    '§7증가될 수 있습니다.'
                  ),
                  'model': 4
                )
              ),
              '스킬 포인트 초기화 스크롤': array(
                'name': 'ENCHANTED_BOOK',
                'meta': array(
                  'display': '§b스킬 포인트 초기화 스크롤',
                  'lore': array(
                    '§7해당 스크롤 사용 시,',
                    '§7스킬에 사용한 포인트가 모두 반환되어',
                    '§7다시 스킬 포인트를 분배 할 수 있습니다.'
                  ),
                  'model': 1
                )
              )
            )
            @inventory = array()
            for(@index = 0, @index < 45, @index++) {
              @inventory[@index] = array(
                'name': 'STRUCTURE_VOID',
                'meta': array(
                  'display': ' ',
                  'model': 1
                )
              )
            }
            # 재료
            @inventory[1] = null
            # 설명
            @info = array(
              'name': 'STRUCTURE_VOID',
              'meta': array(
                'display': '§f재료 아이템을 넣은 후, 만들 아이템을 선택하세요.',
                'lore': array(
                  '§7재료 아이템과 추출된 경험 레벨을 이용하여,',
                  '§7새로운 특수한 아이템을 만들 수 있습니다.',
                  '',
                  '§7추출되는 만큼 경험 레벨이 감소합니다.'
                ),
                'model': 1
              )
            )
            @inventory[9] = @info
            @inventory[10] = @info
            @inventory[11] = @info
            @inventory[18] = @info
            @inventory[19] = @info
            @inventory[20] = @info
            @inventory[27] = @info
            @inventory[28] = @info
            @inventory[29] = @info
            # 30
            @inventory[3] = array_deep_clone(@magic_items['미약한 마법의 정수'])
            @inventory[3]['meta']['lore'][] = ''
            @inventory[3]['meta']['lore'][] = '§e- 재료'
            @inventory[3]['meta']['lore'][] = '§f 유리병'
            @inventory[3]['meta']['lore'][] = '§f 30 경험 레벨'
            @inventory[12] = array_deep_clone(@magic_items['변환의 끈'])
            @inventory[12]['meta']['lore'][] = ''
            @inventory[12]['meta']['lore'][] = '§e- 재료'
            @inventory[12]['meta']['lore'][] = '§f 실'
            @inventory[12]['meta']['lore'][] = '§f 30 경험 레벨'
            # 60
            @inventory[5] = array_deep_clone(@magic_items['농축된 마법의 정수'])
            @inventory[5]['meta']['lore'][] = ''
            @inventory[5]['meta']['lore'][] = '§e- 재료'
            @inventory[5]['meta']['lore'][] = '§f 유리병'
            @inventory[5]['meta']['lore'][] = '§f 60 경험 레벨'
            @inventory[14] = array_deep_clone(@magic_items['놀라운 변환의 끈'])
            @inventory[14]['meta']['lore'][] = ''
            @inventory[14]['meta']['lore'][] = '§e- 재료'
            @inventory[14]['meta']['lore'][] = '§f 실'
            @inventory[14]['meta']['lore'][] = '§f 60 경험 레벨'
            # 90
            @inventory[7] = array_deep_clone(@magic_items['강력한 마법의 정수'])
            @inventory[7]['meta']['lore'][] = ''
            @inventory[7]['meta']['lore'][] = '§e- 재료'
            @inventory[7]['meta']['lore'][] = '§f 유리병'
            @inventory[7]['meta']['lore'][] = '§f 90 경험 레벨'
            @inventory[16] = array_deep_clone(@magic_items['강력한 변환의 끈'])
            @inventory[16]['meta']['lore'][] = ''
            @inventory[16]['meta']['lore'][] = '§e- 재료'
            @inventory[16]['meta']['lore'][] = '§f 실'
            @inventory[16]['meta']['lore'][] = '§f 90 경험 레벨'
            # 120
            @inventory[30] = array_deep_clone(@magic_items['스킬 포인트 초기화 스크롤'])
            @inventory[30]['meta']['lore'][] = ''
            @inventory[30]['meta']['lore'][] = '§e- 재료'
            @inventory[30]['meta']['lore'][] = '§f 종이'
            @inventory[30]['meta']['lore'][] = '§f 120 경험 레벨'
            # location
            @block_location = @event['location']
            # proc
            _open_level_converter(@player, @uuid, @inventory, @block_location, @magic_items, @text)
          }
        }
        break()
      # NORMAL INTERACTIVE BLOCKS
      #case 'BARREL':
      #case 'BEACON':
      #case 'BED':
      #case 'BELL':
      #case 'BLAST_FURNACE':
      #case 'CAKE':
      #case 'CARTOGRAPHY_TABLE':
      #case 'CHEST':
      #case 'COMPARATOR':
      #case 'COMPOSTER': // 조건적 반응 (꽉 차있어서 뺫가루 얻어낼 수 있을시)
      #case 'CRAFTING_TABLE':
      #case 'DAYLIGHT_DETECTOR':
      #case 'DISPENSER':
      #case 'DROPPER':
      #case 'FURNACE':
      #case 'HOPPER':
      #case 'LECTERN':
      #case 'LEVER':
      #case 'LOOM':
      #case 'NOTE_BLOCK':
      #case 'REDSTONE_ORE':
      #case 'REPEATER':
      #case 'RESPAWN_ANCHOR':
      #case 'SHULKER_BOX':
      #case 'SMOKER':
      #case 'STONECUTTER':
      #case 'TRAPPED_CHEST':
      default:
        if(material_info(@event['block'], 'isInteractable')) {
          if(!psneaking(@player)) {
            if(@is_item_available) {
              @is_item_available = false
            }
          }
        }
        break()
      }
      # 농사
      if(@server == 'main') {
        # bone mealing
        if(!is_null(@event['item']) && @event['item']['name'] == 'BONE_MEAL' && array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'SWEET_BERRY_BUSH'), @event['block'])) {
          @data = get_blockdata(@event['location'])
          if(@data['age'] == 0) {
            @data['age'] = 1
            @pos = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.2, 'z': @event['location']['z'] + 0.5)
            @delta = array('x': 0.25, 'y': 0.125, 'z': 0.25)
            #mom_playerparticle(@uuid, 'VILLAGER_HAPPY', @pos['x'], @pos['y'], @pos['z'], 15, @delta['x'], @delta['y'], @delta['z'], 0.0)
            set_timeout(0, closure( set_blockdata(@event['location'], @data) ))
          } else {
            cancel()
          }
        }
        set_timeout(1, closure() {
          if(!is_cancelled()) {
            # cultivating
            if(pmode(@player) == 'SURVIVAL') {
              @is_sowing_allowed = true
              if(@is_sowing_allowed) {
                _farmland_cultivate_event(@event, @player, @uuid, @players_data, @hp_blocks, @skills_spec, @text)
              }
            }
          }
        })
      }
    }
    if(@is_item_available) {
      switch(@event['item']['name']) {
      #case 'BUCKET':
      case 'TURTLE_HELMET': // 물뿌리개
        @block = @event['block']
        @waterable = false
        switch(@block) {
        case 'FARMLAND':
          @waterable = true
          @location = array('x': @event['location']['x'], 'y': @event['location']['y'], 'z': @event['location']['z'], 'world': @event['location']['world'])
          break()
        case 'WHEAT':
        case 'BEETROOTS':
        case 'CARROTS':
        case 'POTATOES':
        case 'PUMPKIN_STEM':
        case 'MELON_STEM':
        case 'SWEET_BERRY_BUSH':
          @waterable = true
          @location = array('x': @event['location']['x'], 'y': @event['location']['y'] - 1, 'z': @event['location']['z'], 'world': @event['location']['world'])
          break()
        }
        if(!is_null(@event['item']['meta']) && @waterable && pcooldown(@player, 'TURTLE_HELMET') == 0) {
          switch(@event['item']['meta']['model']) {
          case 1: // 구리 물뿌리개
            @range = 1
            @min_power = 4
            @max_power = 6
            break()
          case 2: // 금 물뿌리개
            @range = 5
            @min_power = 0
            @max_power = 2
            break()
          case 3: // 다이아몬드 물뿌리개
            @range = 3
            @min_power = 1
            @max_power = 4
            break()
          case 4: // 네더라이트 물뿌리개
            @range = 5
            @min_power = 1
            @max_power = 4
            break()
          default:
            break()
          }
          # 쿨타임, 기타 효과, 사운드
          set_pcooldown(@player, 'TURTLE_HELMET', 14) // 쿨타임 설정
          pswing_hand(@player, 'main_hand')
          set_peffect(@player, 'MINING_FATIGUE', 4, 1, false, false)
          play_named_sound(@location, array('sound': 'block.water.ambient', 'category': 'players', 'volum': 0.5, 'pitch': 2))
          # 파티클
          @closure = closure() {
            # 플레이어 위치
            @ploc = ploc(@player)
            # 물뿌리개 위치 (물 발사 지점 세팅)
            @ploc['yaw'] += 45
            @ploc['pitch'] = 0
            @player_vector = get_vector(@ploc, 0.5)
            for(@i = 0, @i < 5, @i++) {
              @hand_location = array(
                'x': @ploc['x'] + @player_vector['x'] + (rand() - 0.5) / 10,
                'y': @ploc['y'] + 2.2 + (rand() - 0.5) / 10,
                'z': @ploc['z'] + @player_vector['z'] + (rand() - 0.5) / 10
              )
              # 타겟 위치 // x z 에 랜덤한 @range 더하기;
              @target_location = array(
                'x': @location['x'] + 0.5 + (rand() - 0.5) * @range ** 0.7,
                'y': @location['y'] + 1.1,
                'z': @location['z'] + 0.5 + (rand() - 0.5) * @range ** 0.7
              )
              # 수평, 수직 거리 구하기
              @xz_pos1 = array(
                'x': @hand_location['x'],
                'y': 0,
                'z': @hand_location['z'],
                'world': @location['world']
              )
              @xz_pos2 = array(
                'x': @target_location['x'],
                'y': 0,
                'z': @target_location['z'],
                'world': @location['world']
              )
              @xz_distance = distance(@xz_pos1, @xz_pos2) ** 0.25
              @y_distance = (@hand_location['y'] - @target_location['y']) ** 0.25
              # 벡터 구하기
              @vector = array(
                'x': (@target_location['x'] - @hand_location['x']) * @xz_distance * 0.1 / (@y_distance * 0.9),
                'y': 0.0,
                'z': (@target_location['z'] - @hand_location['z']) * @xz_distance * 0.1 / (@y_distance * 0.9)
              )
              mom_playerparticle(@uuid, 'WATER_SPLASH', @hand_location['x'], @hand_location['y'], @hand_location['z'], 0, @vector['x'], @vector['y'], @vector['z'], 0.8)
            }
          }
          @time = time()
          for(@i = 0, @i < 20, @i++) {
            queue_push(@closure, 'wartering.'.@time)
          }
          # 물주기
          for(@x = 0, @x < @range, @x++) {
            for(@z = 0, @z < @range, @z++) {
              @x_offset = @x - integer(@range / 2)
              @z_offset = @z - integer(@range / 2)
              @watering_location = array('x': @location['x'] + @x_offset, 'y': @location['y'], 'z': @location['z'] + @z_offset, 'world': @location['world'])
              if(get_block(@watering_location) == 'FARMLAND') {
                @blockdata = get_blockdata(@watering_location)
                @blockdata['moisture'] += rand(@min_power, @max_power + 1)
                if(@blockdata['moisture'] > 6) { @blockdata['moisture'] = 6 }
                set_blockdata(@watering_location,@blockdata)
              }
            }
          }
        }
        break()
      case 'ENCHANTED_BOOK':
        # 스크롤, 비법서, 마법의 끈 사용시
        if(!is_null(@event['item']['meta'])) {
          switch(@event['item']['meta']['model']) {
          case 1: // 스킬 포인트 초기화 비법서
            @player_data = @players_data[@uuid]
            broadcast(A)
            _reset_skills(@player_data, @player, @uuid, @skills_spec)
            break()
          }
        }
        break();
      case 'EXPERIENCE_BOTTLE':
        if(!is_null(@event['item']['meta']) && @event['item']['meta']['model'] > 0) {
          cancel()
        }
        break();
      case 'NAME_TAG':
        if(psneaking(@player)) {
          # 이름 수정
          /*
          @texture_layer = ''
          @message = '이름 설정'
          @inventory = array(
          )
          @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @text) {
            #set_inventory(@id, @inventory)
            broadcast(get_inventory(@id))
            bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @player, @id) {
              #cancel()
              broadcast(@event)
            }
          }
          _show_gui(@player, 'name_tag', 'ANVIL', @texture_layer, @message, @inventory, @closure, @text)
          */
        }
        break();
      }
    }
  }
}

# 작물 성장
# age가 0일땐 성장하는것 캔슬
# 
# 경작지 젖은 정도 변화
# 젖은 정도가 증가할시, 비또는 천둥이 치면서 하늘이 뚤려 있으며 온도가 높거나 사막 바이옴이 아니여서 비가 내릴 경우에는 젖은 정도를 증가시큼 그렇지 않은 경우엔 캔슬
#
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

# 스폰 상호 작용
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
