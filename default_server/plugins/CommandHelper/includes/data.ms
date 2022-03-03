## Data Procedure
proc _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text, @reconnecting_data) {
  # 배열로 선언
  @players_data[@uuid] = array()
  @player_data = @players_data[@uuid]

  # sidebar
  _load_sidebar(@player, @uuid, @text)

  # cache
  @player_data['cache'] = array(
    'is_dash': false,
    'last_weapon_effect': 0,
    'last_armor_effect': 0,
    'tooltips': array(),
    'indicator_id': '',
    'indicator_remove_task': 0,
    'music_remove_task': 0,
    'last_sender': '',
    'last_whisper_sender': '',
    'whisper_target': '',
  )

  # cache edit
  if(is_array(@reconnecting_data)) {
    @player_data['cache']['last_sender'] = @reconnecting_data['last_sender']
    @player_data['cache']['last_whisper_sender'] = @reconnecting_data['last_whisper_sender']
    @player_data['cache']['whisper_target'] = @reconnecting_data['whisper_target']
  }

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
  _update_channel_tag(@uuid, @player_data, @text)

  # decoration
  @player_data['decoration'] = cup_get('DECORATION', @uuid)
  if(is_null(@player_data['decoration'])) {
    _new_decoration(@uuid, @player_data)
  }

  # skill
  _load_skills(@player_data, @player, @uuid, @skills_spec)
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
  
  # tunalevel
  _show_tunalevel(@uuid, @player_data, @text)

  # arcanelevel
  _show_arcanelevel(@player, @uuid, @text)
}

# 설정 데이터 (현재 기능 없음) 
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

# 채팅 데이터
proc _new_chat(@uuid, @player_data) {
  @player_data['chat'] = array(
    'default', // 사용중인 채팅 채널
    false, // enko여부
    json_encode(array('default', 'local', 'town', 'admin')), // 듣기 활성화 할 채널들
    false, // 채팅 옵저버모드
    '',    // 마지막 귓말한사람
    '',    // 마지막 채팅친사람
    false, // 메신저채팅 여부
    false  // 채팅 이름부분 정렬 여부
  )
  cup_set('CHAT', @uuid, @player_data['chat'])
}

# 치장 데이터
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

# 스코어보드 기본값 생성
proc _load_sidebar(@player, @uuid, @text) {
  @scoreboard = "ch_scoreboard.@uuid"
  if(!array_contains(get_scoreboards(), @scoreboard)) { create_scoreboard(@scoreboard) }
  set_pscoreboard(@player, @scoreboard)

  @is_objective_exists = false
  foreach(@objective in get_objectives(@scoreboard, 'DUMMY')) {
    if(@objective['name'] == 'objective') {
      @is_objective_exists = true
      break()
    }
  }

  @mnsf = @text['space_fonts']['space.-max']

  if(!@is_objective_exists) {
    create_objective('objective', 'DUMMY', @scoreboard)
  }
  set_objective_display('objective', array('slot': 'SIDEBAR', 'displayname': @text['space_fonts']['space.-4']), @scoreboard)

  @teams = get_teams(@scoreboard)
  for(@line = 0, @line < 15, @line ++) {
    # 오브젝트 플레이어
    set_pscore('objective', @line, 14 - @line, @scoreboard)
    # 팀
    if(!array_index_exists(@teams, @line)) {
      create_team(@line, @scoreboard)
    }
    _set_sidebar(@uuid, @line, '', @text)
    team_add_player(@line, @line, @scoreboard)
  }
}

# 리소스팩 보내기
proc _send_resourcepack(@player, @uuid, @players_data, @skills_spec, @effective_items, @text, @resourcepack, @musics_data) {
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
  bind('resource_pack_status', array('id': @resource_pack_event_id), array('player': @player), @event, @player, @uuid, @join_spec, @players_data, @skills_spec, @text, @effective_items, @musics_data) {
    switch(@event['status']) {
    case 'DECLINED':
      pkick(@player, _color('#ff4040').'§l서버 리소스팩을 사용하도록 설정해 주시기 바랍니다.\n'._color('#c0c0c0').'§l에바참치 서버를 선택한 후, 수정 버튼을 눌러\n서버 리소스팩을 사용으로 설정해 주세요.\n\n'._color('#ffff80').'§l버그 문의: ')
      unbind()
      break()
    case 'SUCCESSFULLY_LOADED':
      _apply_join_spec(@player, @uuid, @join_spec, @players_data, @skills_spec, @effective_items, @text)
      set_timeout(1000, closure() {
        _play_world_music(@player, @uuid, @players_data, @musics_data)
      })
      unbind()
      break()
    }
  }
}

# 리소스팩 적용 후 세팅
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
    _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text, null)
  })
}

# 플레이어 접속
proc _join_event(@player, @uuid, @reconnecting_datas, @players_data, @skills_spec, @effective_items, @text, @resourcepack, @musics_data) {
  if(!array_index_exists(@reconnecting_datas, @uuid)) {
    _send_resourcepack(@player, @uuid, @players_data, @skills_spec, @effective_items, @text, @resourcepack, @musics_data)
    //broadcast('리팩보냄')
  } else {
    #set_timeout(500, closure() {
      @reconnecting_data = @reconnecting_datas[@uuid]
      # 플레이어 데이터 로드
      _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text, @reconnecting_data)
      # 첫접속시 가이드 안내 메시지
      if(@reconnecting_data['server'] == 'guest') {
        runas('~console', "/recipe give @player *")
        runas('~console', "/recipe take @player tunalands:release_flag")
        runas('~console', "/recipe take @player tunalands:take_flag")
        
        runas('~console', "/advancement grant @player everything")
        @raw = array(
          array(
            'text': @text['space_fonts']['space.128'].'\ue008\n\n\n\n\n\n'
          ),
          array(
            'text': @text['space_fonts']['space.8'].'환영합니다! 에바참치는 기존 마인크래프트 야생의 장점을 살려 재해석한 서버입니다.\n\n',
            'color': '#80c8ff'
          ),
          array(
            'text': '서버에 적응하는 것을 도와드리기 위해 가이드를 준비하였으니 꼭 확인해보시기 바랍니다.\n'
          ),
          array(
            'text': @text['space_fonts']['space.112'].'( ESC > 에바참치 가이드 )',
            'color': 'gray'
          )
        )
        _tellraw(@player, @raw)
      }
      array_remove(@reconnecting_datas, @uuid)
      
      _play_world_music(@player, @uuid, @players_data, @musics_data)
    #})
  }
}

# 플레이어 퇴장
proc _quit_event(@uuid, @players_data, @server) {
  if(array_index_exists(@players_data, @uuid)) {
    # 카프카
    @reconnecting_data = array(
      'uuid': @uuid,
      'countdown': 10,
      'server': @server,
      'last_sender': @players_data[@uuid]['cache']['last_sender'],
      'last_whisper_sender': @players_data[@uuid]['cache']['last_whisper_sender'],
      'whisper_target': @players_data[@uuid]['cache']['whisper_target']
    )

    kafka_send('ch.inform_player_quit', json_encode(@reconnecting_data))
    # 컵
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
    clear_task(@players_data[@uuid]['cache']['music_remove_task'])
    array_remove(@players_data, @uuid)
    #_update_tip_data(@uuid, @players_data)
  }
}

# 서버 이동시 카운트 다운 (카운트 다운이 다 되면 서버 나간것으로 간주)
proc _countdown_reconnectable_players(@reconnecting_datas) {
  foreach(@uuid: @reconnecting_data in @reconnecting_datas) {
    if(@reconnecting_data['countdown'] > 0) {
      @reconnecting_data['countdown'] -= 1
    } else {
      array_remove(@reconnecting_datas, @uuid)
    }
  }
}
