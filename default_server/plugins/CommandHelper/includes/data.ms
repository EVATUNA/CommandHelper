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
  
  # scoreboard
  @scoreboard = "ch_scoreboard.@uuid"
  if(!array_contains(get_scoreboards(), @scoreboard)) { create_scoreboard(@scoreboard) }
  set_pscoreboard(@player, @scoreboard)
  
  # sidebar
  _load_sidebar(@player, @uuid, @player_data, @scoreboard, @text)

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

proc _load_sidebar(@player, @uuid, @player_data, @scoreboard, @text) {
  @sidebar = 'sidebar'
  @is_sidebar_exist = false
  foreach(@objective in get_objectives(@scoreboard, 'DUMMY')) {
    if(@objective['name'] == 'sidebar') {
      @is_sidebar_exist = true
      break() //나중에 해당 스코어 보드에 여러 오브젝티브 사용시 브레이크 제거 해야함
    }
  }
  if(!@is_sidebar_exist) { create_objective(@sidebar, 'DUMMY', @scoreboard) }
  @psf = @text['space_fonts']['space.64']
  @nsf = @text['space_fonts']['space.-82']
  set_objective_display(@sidebar, array('slot': 'SIDEBAR', 'displayname': @nsf), @scoreboard)
  set_pscore(@sidebar, @psf.'a'.@nsf, 1, @scoreboard)
  set_pscore(@sidebar, @psf.'b'.@nsf, 1, @scoreboard)
  set_pscore(@sidebar, @psf.'c'.@nsf, 1, @scoreboard)
  set_pscore(@sidebar, @psf.'d'.@nsf, 1, @scoreboard)
  @channel_tags = array(
    'general_ko': '§1\ue3f9'.@nsf,
    'general_en': '§1\ue3fa'.@nsf,
    'town_ko': '§1\ue3fb'.@nsf,
    'town_en': '§1\ue3fc'.@nsf,
    'local_ko': '§1\ue3fd'.@nsf,
    'local_en': '§1\ue3fe'.@nsf,
    'admin_ko': '§1\ue3ff'.@nsf,
    'admin_en': '§1\ue400'.@nsf,
    'party_ko': '§1\ue401'.@nsf,
    'party_en': '§1\ue402'.@nsf,
    'dummy_ko': '§1\ue403'.@nsf,
    'dummy_en': '§1\ue404'.@nsf,
  )
  set_pscore(@sidebar, @channel_tags['general_ko'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['general_en'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['town_ko'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['town_en'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['local_ko'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['local_en'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['admin_ko'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['admin_en'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['party_ko'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['party_en'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['dummy_ko'], 0, @scoreboard)
  set_pscore(@sidebar, @channel_tags['dummy_en'], 0, @scoreboard)

  _update_channel_tag(@player, @uuid, @player_data, @text)
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
  if(array_index_exists(@players_data, @uuid)) {
    # 액티브 스킬 저장
    @player_data = @players_data[@uuid]
    @skill_manager = @player_data['skill_manager']

    @selected_methods = json_decode(@skill_manager[4])
    
    @selected_combat_method = @selected_methods['combat_method']
    if(@selected_combat_method != '') {
      @active_skill = @player_data['active_skill'][@selected_combat_method]
      _save_active_skill(@uuid, @selected_combat_method, @active_skill)
    }

    @selected_sowing_method = @selected_methods['sowing_method']
    if(@selected_sowing_method != '') {
      @active_skill = @player_data['active_skill'][@selected_sowing_method]
      _save_active_skill(@uuid, @selected_sowing_method, @active_skill)
    }

    @selected_harvesting_method = @selected_methods['harvesting_method']
    if(@selected_harvesting_method != '') {
      @active_skill = @player_data['active_skill'][@selected_harvesting_method]
      _save_active_skill(@uuid, @selected_harvesting_method, @active_skill)
    }
    //룬에도 액티브 스킬 있을 경우 룬 불러와야 함

    array_remove(@players_data, @uuid)
    #_update_tip_data(@uuid, @players_data)
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