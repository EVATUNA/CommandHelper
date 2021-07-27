### 스킬 데이터 저장
@skills_spec = array()
@skills_info = array()
@categories = list_files('categories')
foreach(@category in @categories) { 
  @skills_info[@category] = array()
  @category_path = "categories/@category"
  @skills = list_files(@category_path)
  foreach(@skill in @skills) {
    @skill_path = "@category_path/@skill"
    @files = list_files(@skill_path)
    foreach(@file in @files) {
      @file_path = "@skill_path/@file"
      switch(@file) {
      case 'spec.json':
        async_read_file(@file_path, closure(@content) {
          @skills_spec[@skill] = json_decode(@content)
        })
        break()
      case 'info.json':
        async_read_file(@file_path, closure(@content) {
          @skills_info[@skill] = json_decode(@content)
        })
        break()
      case 'load.ms':
      case 'attack.ms':
      case 'update_item.ms':
      case 'active.ms':
      case 'countdown.ms':
        include(@file_path)
        break()
      }
    }
  }
}

### 프로시저

## 스킬 데이터 (레벨, 경험치, 토탈포인트)
# 스킬 매니저 get
proc _get_skill_manager(@uuid) {
  @skill_manager = cup_get('SKILL_MANAGER', @uuid)
  if(!is_null(@skill_manager)) {
    # 기본 값
    @default_level = 0
    @default_experience = 0
    @default_total_point = 10 //0
    @default_rune_slot = 1
    @default_selected_methods = json_encode(
      array(
        'combat_method': '',
        'harvesting_method': '',
        'sowing_method': ''
      )
    )
    @default_selected_runes = json_encode(array())
    @default_scroll_gauge = 0
    # 스킬 메니저 션언
    @skill_manager = array(
      @default_level,
      @default_experience,
      @default_total_point,
      @default_rune_slot,
      @default_selected_methods,
      @default_selected_runes,
      @default_scroll_gauge
    )
    # cup에 저장
    _set_skill_manager(@uuid, @skill_manager)
  }
  return(@skill_manager)
}
# 스킬 매니저 set
proc _set_skill_manager(@uuid, @skill_manager) {
  cup_set('SKILL_MANAGER', @uuid, @skill_manager)
}

## 스킬 데이터 (현재 포인트, 맥스 포인트)
# 스킬 데이터 get
proc _get_skill_data(@uuid, @skill, @skill_spec) {
  @skill_data = cup_get('SKILL_DATA', @uuid.'_'.@skill)
  if(!is_null(@skill_data)) {
    # 기본 값
    @default_point = 0
    @default_max_point = @skill_spec['default_max_point']
    # 스킬 데이터 선언
    @skill_data = array(
      @default_point,
      @default_max_point
    )
    # cup에 저장
    _set_skill_data(@uuid, @skill, @skill_data)
  }
  return(@skill_data) 
}
# 스킬 데이터 set
proc _set_skill_data(@uuid, @skill, @skill_data) {
  cup_set('SKILL_DATA', @uuid.'_'.@skill, @skill_data)
}

## 액티브 스킬 (쿨타임, 지속시간, 갯수, 에너지, 활성화 여부)
# 액티브 스킬 load
proc _load_active_skill(@player_data, @uuid, @skill, @point, @skill_spec) {
  @active_skill = cup_get('ACTIVE_SKILL', @uuid.'_'.@skill)
  if(is_null(@active_skill) || !@active_skill[4]) {
    # 기본 값
    @default_cooldown = @skill_spec['effect_by_point'][@point]['active']['cooldown']
    @default_duration = 0
    @default_count = 0
    @default_energy = 0
    @default_is_activated = true
    # 액티브 스킬 선언
    @active_skill = array(
      @default_cooldown,
      @default_duration,
      @default_count,
      @default_energy,
      @default_is_activated
    )
    # cup에 저장
    _save_active_skill(@uuid, @skill, @active_skill)
  }
  # 플레이어 데이터에 저장
  @player_data['active_skill'][@skill] = @active_skill
}
# 액티브 스킬 reset
proc _reset_active_skill(@player_data, @uuid, @skill) {
  # 비활성화 값
  @reseted_cooldown = 0
  @reseted_duration = 0
  @reseted_count = 0
  @reseted_energy = 0
  @reseted_is_activated = false
  # 액티브 스킬 선언
  @reseted_active_skill = array(
    @reseted_cooldown,
    @reseted_duration,
    @reseted_count,
    @reseted_energy,
    @reseted_is_activated
  )
  # cup에 저장
  _save_active_skill(@uuid, @skill, @reseted_active_skill)
  # 플레이어 데이터에서 삭제
  if(array_index_exists(@player_data['active_skill'], @skill)) {
    array_remove(@player_data['active_skill'], @skill)
  }
}
# 액티브 스킬 save
proc _save_active_skill(@uuid, @skill, @active_skill) {
  cup_set('ACTIVE_SKILL', @uuid.'_'.@skill, @active_skill)
}

## 플레이어 관리 펑션
# 플레이어의 모든 레벨 경치 스텟 및 스킬 데이터, 효과 로드
proc _load_skills(@player_data, @player, @uuid, @skills_spec) {
  # 플레이어의 레벨, 경험치, 어떤 스킬을 선택중인지 구함
  @skill_manager = _get_skill_manager(@uuid)
  @player_data['skill_manager'] = @skill_manager
  # 플레이어가 선택한 스킬들 선언
  @selected_methods = json_decode(@skill_manager[4])
  @selected_combat_method = @selected_methods['combat_method']
  @selected_sowing_method = @selected_methods['sowing_method']
  @selected_harvesting_method = @selected_methods['harvesting_method']
  @selected_runes = json_decode(@skill_manager[5])
  # 투자한 총 포인트 선언
  @player_data['invested_point'] = 0
  # 액티브 스킬 배열 선언
  @player_data['skill_data'] = array()
  @player_data['active_skill'] = array()
  # 스킬 데이터 로드 및, 스킬 효과 적용 (모든 스킬 데이터 로드시 선택한 스킬,룬 이라면 로드.ms 작동해야 함)
  foreach(@skill: @skill_spec in @skills_spec) {
    # 카테고리 선언
    @category = @skill_spec['category']
    # 스킬 데이터 로드
    @skill_data = _get_skill_data(@uuid, @skill, @skill_spec)
    @player_data['skill_data'][@skill] = @skill_data
    # 투자 포인트 계산
    @point = @skill_data[0]
    if(@category != 'rune') {
      @player_data['invested_point'] += @point
    }
    # 스킬 효과 적용 (로드시)
    @proc_name = "_apply_loading_by_@skill"
    if(is_proc(@proc_name)) {
      call_proc(@proc_name, @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @selected_combat_method, @selected_sowing_method, @selected_harvesting_method, @selected_runes)
    }
  }
}




# 버튼이랑 메인 나누기
# 버튼 누를시 포인트 찍은거 인식

# @skill_manager = @player_data['skill_manager']
# @invested_point = @player_data['invested_point']
#  # 룬 슬롯 갯수
#  @rune_slot = @skill_manager[3]
#  # 선택한 방식 스킬
#  @selected_methods = @skill_manager[4]
#  @selected_combat_method = @selected_methods['combat_method']
#  @selected_sowing_method = @selected_methods['sowing_method']
#  @selected_harvesting_method = @selected_methods['harvesting_method']
#  # 선택한 룬들
#  @selected_runes = @skill_manager[5]
# _open_skill_???page() 쓰기전 위의 변수들 선언 되어야 함

proc _open_combat_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  @skill_manager = @player_data['skill_manager']
  @skills_data = @player_data['skill_data']
  # 레벨
  @level = @skill_manager[0]
  # 경험치
  @experience = @skill_manager[1]
  # 포인트
  @total_point = @skill_manager[2]
  @remaining_point = @total_point - @player_data['invested_point']
  # 선택한 전투 방식
  @selected_methods = json_decode(@skill_manager[4])
  # GUI 기본 데이터 선언
  @texture_layer = ''
  @message = '전투'
  @inventory = array()
  for(@index = 0, @index < 54, @index++) {
    @inventory[@index] = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': ' ',
        'model': 1
      )
    )
  }
  # 스킬 배치
  @skill_setup = array(
    'sweeping': array(
      'slot_type': 'combat_method',
      'icon': 10,
      'button': 19
    ),
    'knockback': array(
      'slot_type': 'combat_method',
      'icon': 12,
      'button': 21
    ),
    'cleaving': array(
      'slot_type': 'combat_method',
      'icon': 14,
      'button': 23
    ),
    'blocking': array(
      'slot_type': 'combat_method',
      'icon': 16,
      'button': 25
    ),
    'bow_mastery': array(
      'slot_type': 'subcombat',
      'icon': 28,
      'button': 37
    ),
    'crossbow_mastery': array(
      'slot_type': 'subcombat',
      'icon': 30,
      'button': 39
    ),
    'health_traing': array(
      'slot_type': 'subcombat',
      'icon': 32,
      'button': 41
    )
  )
  broadcast(@remaining_point '/' @total_point '( 사용한 포인트:'@player_data['invested_point']')')
  foreach(@skill: @slots in @skill_setup) {
    @skill_point = @skills_data[@skill][0]
    @skill_max_point = @skills_data[@skill][1]
    @skill_info = @skills_info[@skill]
    @skill_icon = @skill_info['icon']
    @skill_display = @skill_info['display']
    @skill_desriptions = @skill_info['desriptions']
    if(array_size(@skill_desriptions) > 0) {
      if(array_size(@skill_desriptions) - 1 < @skill_point) {
        @desription_index = array_size(@skill_desriptions) - 1
      } else {
        @desription_index = @skill_point
      }
      @skill_desription = @skill_desriptions[@desription_index]
    } else {
      @skill_desription = ''//array()
    }
    @inventory[@slots['icon']]['name'] = 'STONE' // 제거해야 함
    @inventory[@slots['icon']]['skill'] = @skill
    @inventory[@slots['icon']]['slot_type'] = @slots['slot_type']
    @inventory[@slots['icon']]['meta']['display'] = "§fLv.@skill_point @skill_display"
    @inventory[@slots['icon']]['meta']['lore'] = array(@skill_desription) //@skill_desriptio
    @inventory[@slots['icon']]['meta']['model'] = 10 //@skill_icon
    // 슬롯 타입이 전투 방식이면서 해당 스킬 레벨이 0 보다 클 시 해당 스킬 적용상태에 따른 로어 추가

    if(@remaining_point > 0 && @skills_data[@skill][0] < @skills_data[@skill][1]) {
      @inventory[@slots['button']]['name'] = 'DIRT' // 제거해야 함
      @inventory[@slots['button']]['skill'] = @skill
      @inventory[@slots['button']]['slot_type'] = 'button'
      @inventory[@slots['button']]['meta']['display'] = '좌클릭 시, 포인트를 사용합니다.'
      @inventory[@slots['button']]['meta']['lore'] = '설명'
    }
  }
  # GUI 이벤트 익스큐터 설정
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @players_data, @skills_info, @skills_spec, @text) {
    bind('inventory_click', array('id': 'click'.@id), array('player': @player, 'virtual': true), @event, @inventory, @player, @uuid, @id, @players_data, @skills_info, @skills_spec, @text) {
      cancel()
      # 데이터 선언
      @player_data = @players_data[@uuid]
      @skill_manager = @player_data['skill_manager']
      @skills_data = @player_data['skill_data']
      # 포인트
      @total_point = @skill_manager[2]
      @remaining_point = @total_point - @player_data['invested_point']
      # 선택한 전투 방식
      @selected_methods = json_decode(@skill_manager[4])
      # 슬롯
      @slot = @event['rawslot']
      if(@slot > 0 && array_index_exists(@inventory[@slot], 'slot_type')) {
        switch(@inventory[@slot]['slot_type']) {
        case 'combat_method':
          @skill = @inventory[@slot]['skill']
          if(@skills_data[@skill][0] > 0) {
            if(@selected_methods['combat_method'] == @skill) {
              @selected_methods['combat_method'] = ''
              #broadcast('선택 해제')
              _reset_active_skill(@player_data, @uuid, @skill)
            } else {
              @selected_methods['combat_method'] = @skill
              #broadcast('스킬 선택')
              @point = @skills_data[@skill][0]
              @skill_spec = @skills_spec[@skill]
              _load_active_skill(@player_data, @uuid, @skill, @point, @skill_spec)
            }
            @skill_manager[4] = json_encode(@selected_methods)
            #broadcast(@skill_manager)
          }
          #broadcast(A @skill @skills_data[@skill])
          break()
        case 'subcombat':
          break()
        case 'button':
          @skill = @inventory[@slot]['skill']
          @skills_data[@skill][0] += 1
          @player_data['invested_point'] += 1
          runas(@player, '/skill')
          break()
        }
      }
      if(@event['action'] == 'PICKUP_ALL') {
        switch(@event['rawslot']) {
        case 0:
          break()
        }
      }
    }
  }
  # GUI 보여주기
  _show_gui(@player, 'skillbook_combat', 54, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_info, @skills_spec, @text)
}



proc _open_skillbook(@player, @category, @subpage, @players_data, @skills_info, @text) {
  @uuid = puuid(@player)
  switch(@category) {
  case 'combat':
    @combat_methods_info = @skills_info['combat_method']
    @selected_combat_method = @players_data[@uuid]['skill_manager'][2]
    @content = array(
      array(
        'text': '- 전투 방식 / 전투 특성\n',
        'hoverEvent': array(
          'action': 'show_text',
          'value': '적용중인 전투 방식과 전투특성을 간략히 보여줍니다.\n\n§c각각의 아이콘을 클릭하여자세히 확인 할 수 있으며\n전투 방식과 전투 특성을 변경 할 수 있습니다.'
        )
      )
    )
    @raw = array(array(),array())
    if(@selected_combat_method != '') {
      foreach(@combat_method_info in @combat_methods_info) {
        if(@selected_combat_method == @combat_method_info['name']) {
          @desription = @combat_method_info['display'].' 전투 방식을 사용중입니다.\n\n§c좌클릭 시, 전투 방식 선택창을 열어\n모든 전투 방식의 숙련 레벨과\n숙련 경험치를 확인 할 수 있으며\n전투 방식을 변경 할 수 있습니다.'
          @raw[0][] = array(
            'text': @text['space_fonts']['space.18'],
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text',
              'value': @desription
            ),
            'clickEvent': array(
              'action': 'run_command',
              'value': '/skillbook open combat_method'
            )
          )
          @raw[1][] = array(
            'text': @text['space_fonts']['space.1'].@combat_method_info['icon'],
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text',
              'value': @desription
            ),
            'clickEvent': array(
              'action': 'run_command',
              'value': '/skillbook open combat_method'
            )
          )
          break()
        }
      }
    } else {
      @desription = '사용중인 전투 방식이 없습니다.\n\n§c좌클릭 시, 전투 방식 선택창을 열어\n모든 전투 방식의 숙련 레벨과\n숙련경험치를 확인 할 수 있으며\n전투 방식을 변경 할 수 있습니다.'
      @raw[0][] = array(
        'text': @text['space_fonts']['space.18'],
        'color': 'white',
        'hoverEvent': array(
          'action': 'show_text',
          'value': @desription
        ),
        'clickEvent': array(
          'action': 'run_command',
          'value': '/skillbook open combat_method'
        )
      )
      @raw[1][] = array(
        'text': @text['space_fonts']['space.18'],
        'color': 'white',
        'hoverEvent': array(
          'action': 'show_text',
          'value': @desription
        ),
        'clickEvent': array(
          'action': 'run_command',
          'value': '/skillbook open combat_method'
        )
      )
    }
    @raw[0][] = array(
      'text': ' '
    )
    @raw[1][] = array(
      'text': @text['space_fonts']['space.-18'].'\ue00e'.@text['space_fonts']['space.-1'].' ',
      'color': 'white'
    )
    @combat_inclinations_info = @skills_info['combat_inclination']
    @selected_combat_inclinations = json_decode(@players_data[@uuid]['skill_manager'][0])
    @unselected_slot_size = @players_data[@uuid]['skill_manager'][1]
    if(array_size(@selected_combat_inclinations) > 0) {
      foreach(@combat_inclination_info in @combat_inclinations_info) {
        if(array_contains(@selected_combat_inclinations, @combat_inclination_info['name'])) {
          @desription = @combat_inclination_info['display'].' 특성을 적용중입니다.\n\n§c좌클릭 시, 전투 특성 선택창을 열어\n습득한 모든 전투 특성을 확인 할 수 있으며\n특성 변경이 가능합니다.'
          @raw[0][] = array(
            'text': @text['space_fonts']['space.18'],
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text',
              'value': @desription
            ),
            'clickEvent': array(
              'action': 'run_command',
              'value': '/skillbook open combat_inclination'
            )
          )
          @raw[1][] = array(
            'text': @text['space_fonts']['space.1'].@combat_inclination_info['icon'],
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text',
              'value': @desription
            ),
            'clickEvent': array(
              'action': 'run_command',
              'value': '/skillbook open combat_inclination'
            )
          )
          @raw[1][] = array(
            'text': @text['space_fonts']['space.-18'].'\ue00e'.@text['space_fonts']['space.-1'],
            'color': 'white'
          )
        }
      }
    }
    @desription = '해당 슬롯에 적용된 특성이 없습니다.\n\n§c좌클릭 시, 전투 특성 선택창을 열어\n습득한 모든 전투 특성을 확인 할 수 있으며\n특성 변경이 가능합니다.'
    for(@i = 0, @i < @unselected_slot_size, @i++) {
      @raw[0][] = array(
        'text': @text['space_fonts']['space.18'],
        'color': 'white',
        'hoverEvent': array(
          'action': 'show_text',
          'value': @desription
        ),
        'clickEvent': array(
          'action': 'run_command',
          'value': '/skillbook open combat_inclination'
        )
      )
      @raw[1][] = array(
        'text': @text['space_fonts']['space.18'],
        'color': 'white',
        'hoverEvent': array(
          'action': 'show_text',
          'value': @desription
        ),
        'clickEvent': array(
          'action': 'run_command',
          'value': '/skillbook open combat_inclination'
        )
      )
      @raw[1][] = array(
        'text': @text['space_fonts']['space.-18'].'\ue00e'.@text['space_fonts']['space.-1'],
        'color': 'white'
      )
    }
    @raw[0][] = array('text': '\n')
    @raw[1][] = array('text': '\n')
    @content = array_merge(@content, array_merge(@raw[0], @raw[1]))
    @subcombats_info = @skills_info['subcombat']
    @subcombats = @players_data[@uuid]['skill_data']['subcombat']
    @content[] = array('text': '\n- 보조 전투 숙련')
    foreach(@subcombat_info in @subcombats_info) {
      @subcombat_data = @subcombats[@subcombat_info['name']]
      if(array_size(@subcombat_info['desription']) - 1 < @subcombat_data[0]) {
        @desription_index = array_size(@subcombat_info['desription']) - 1
      } else {
        @desription_index = @subcombat_data[0]
      }
      if(@subcombat_data[0] == 0) {
        @icon = '\ue00f'
        @name = '???'
        @desription = string(@name.'\n'.@subcombat_info['desription'][@desription_index]).'\n\n§c숙련 레벨이 올르면,\n해당 스킬이 적용됩니다.'
      } else {
        @icon = @subcombat_info['icon']
        @name = string('Lv.'.@subcombat_data[0] @subcombat_info['display'])
        @desription = string(@name.'\n'.@subcombat_info['desription'][@desription_index])
      }
      @raw0 = array(
        array(
          'text': '\n'.@text['space_fonts']['space.18'],
          'color': 'white',
          'hoverEvent': array(
            'action': 'show_text'
          )
        ),
        array(
          'text': ' Lv.'.@subcombat_data[0]'('.@subcombat_data[1].'/'.@subcombat_data[3].')\n',
          'color': 'black'
        )
      )
      @raw1 = array(
        array(
          'text': @text['space_fonts']['space.1'].@icon,
          'color': 'white',
          'hoverEvent': array(
            'action': 'show_text'
          )
        ),
        array(
          'text': ' ',
          'color': 'white'
        ),
        array(
          'text': string_multiply('', integer(@subcombat_data[1] / @subcombat_data[3] * 50)).'\n',
          'color': 'green'
        )
      )
      @raw0[0]['hoverEvent']['value'] = @desription
      @raw1[0]['hoverEvent']['value'] = @desription
      @content = array_merge(@content, array_merge(@raw0, @raw1))
    }
    @arrow = array(
      array(
        'text': @text['space_fonts']['space.77'].'\ue00d\n',
        'color': 'white'
      ),
      array(
        'text':@text['space_fonts']['space.77'],
        'color': 'white'
      ),
      array(
        'text': '\ue00d',
        'hoverEvent': array(
          'action': 'show_text',
          'value': '다음 페이지'
        ),
        'clickEvent': array(
          'action': 'run_command',
          'value': '/skillbook open farming_method'
        )
      )
    )
    @content = array_merge(@content, @arrow)
    open_book(@player, array(json_encode(@content)))
    break()
  case 'combat_method':
    @combat_methods_info = @skills_info['combat_method']
    @combat_methods = @players_data[@uuid]['skill_data']['combat_method']
    @selected_combat_method = @players_data[@uuid]['skill_manager'][2]
    @content = array(array('text': '- 전투 방식 목록\n\n'))
    foreach(@combat_method_info in @combat_methods_info) {
      @combat_method_data = @combat_methods[@combat_method_info['name']]
      if(array_size(@combat_method_info['desription']) - 1 < @combat_method_data[0]) {
        @desription_index = array_size(@combat_method_info['desription']) - 1
      } else {
        @desription_index = @combat_method_data[0]
      }
      if(@combat_method_data[0] == 0) {
        @icon = '\ue00f'
        @name = '???'
      } else {
        @icon = @combat_method_info['icon']
        @name = string('Lv.'.@combat_method_data[0] @combat_method_info['display'])
      }
      @desription = string(@name.'\n'.@combat_method_info['desription'][@desription_index].'\n\n')
      @raw0 = array(
        array(
          'text': @text['space_fonts']['space.18'],
          'color': 'white',
          'hoverEvent': array(
            'action': 'show_text'
          )
        ),
        array(
          'text': ' Lv.'.@combat_method_data[0]'('.@combat_method_data[1].'/'.@combat_method_data[3].')\n',
          'color': 'black'
        )
      )
      @raw1 = array(
        array(
          'text': @text['space_fonts']['space.1'].@icon,
          'color': 'white',
          'hoverEvent': array(
            'action': 'show_text'
          )
        ),
        array(
          'text': ' ',
          'color': 'white'
        ),
        array(
          'text': string_multiply('', integer(@combat_method_data[1] / @combat_method_data[3] * 50)).'\n\n',
          'color': 'green'
        )
      )
      if(@combat_method_data[0] > 0) {
        if(@selected_combat_method == @combat_method_info['name']) {
          @select_box = array(
            'text': @text['space_fonts']['space.-18'].'\ue00e'.@text['space_fonts']['space.-1'],
            'color': 'white'
          )
          array_insert(@raw1, @select_box, 1)
          @desription = @desription.'§c좌클릭 시, 해당 방식 사용을 해제합니다.'
          @clickevent = array(
            'action': 'run_command',
            'value': '/skillbook unselect combat_method '.@combat_method_info['name']
          )
        } else {
          @desription = @desription.'§c좌클릭 시, 해당 방식을 사용합니다.'
          @clickevent = array(
            'action': 'run_command',
            'value': '/skillbook select combat_method '.@combat_method_info['name']
          )
        }
        @raw0[0]['clickEvent'] = @clickevent
        @raw1[0]['clickEvent'] = @clickevent
      } else {
        @desription = @desription.'§c숙련 레벨을 올린 후,\n해당 방식을 사용할 수 있습니다.'
      }
      @raw0[0]['hoverEvent']['value'] = @desription
      @raw1[0]['hoverEvent']['value'] = @desription
      @content = array_merge(@content, array_merge(@raw0, @raw1))
    }
    open_book(@player, array(json_encode(@content)))
    break()
  case 'combat_inclination':
    @combat_inclinations_info = @skills_info['combat_inclination']
    @combat_inclinations = @players_data[@uuid]['skill_data']['combat_inclination']
    @selectable_combat_inclinations = array_keys(@combat_inclinations)
    @selected_combat_inclinations = json_decode(@players_data[@uuid]['skill_manager'][0])
    @unselected_slot_size = @players_data[@uuid]['skill_manager'][1] - array_size(@selected_combat_inclinations)
    @pages = array()
    @paging_array = _paging(@combat_inclinations_info, 36)
    foreach(@page_key: @page in @paging_array) {
      @content = array(array('text': '- 전투 특성 목록\n'))
      foreach(@line_key: @line in _paging(@page, 6)) {
        @raw = array(array(array('text': @text['space_fonts']['space.4'])), array(array('text': @text['space_fonts']['space.4'])))
        foreach(@key: @combat_inclination_info in @line) {
          if(array_contains(@selectable_combat_inclinations, @combat_inclination_info['name'])) {
            @combat_inclination_data = @combat_inclinations[@combat_inclination_info['name']]
            if(array_size(@combat_inclination_info['desription']) - 1 < @combat_inclination_data[0]) {
              @desription_index = array_size(@combat_inclination_info['desription']) - 1
            } else {
              @desription_index = @combat_inclination_data[0]
            }
            @desription = string('Lv.'.@combat_inclination_data[0]@combat_inclination_info['display'].'\n'.@combat_inclination_info['desription'][@desription_index].'\n\n')
            @raw0 = array(
              'text': @text['space_fonts']['space.18'],
              'color': 'white',
              'hoverEvent': array(
                'action': 'show_text'
              )
            )
            @raw1 = array(
              'text': @text['space_fonts']['space.1'].@combat_inclination_info['icon'],
              'color': 'white',
              'hoverEvent': array(
                'action': 'show_text'
              )
            )
            if(array_contains(@selected_combat_inclinations, @combat_inclination_info['name'])) {
              @desription = @desription.'§c좌클릭 시, 해당 특성 적용을 해제합니다.'
              @raw1['text'] = @raw1['text'].@text['space_fonts']['space.-18'].'\ue00e'.@text['space_fonts']['space.-1']
              @clickevent = array(
                'action': 'run_command',
                'value': '/skillbook unselect combat_inclination '.@subpage @combat_inclination_info['name']
              )
              @raw0['clickEvent'] = @clickevent
              @raw1['clickEvent'] = @clickevent
            } else {
              if(@unselected_slot_size == 0) {
                @desription = @desription.'§c더 이상 특성을 적용할 수 없습니다.\n§7적용되어 있는 특성을 해제한 후,\n해당 특성을 적용할 수 있습니다.'
              } else {
                @desription = @desription.'§c좌클릭 시, 해당 특성을 적용합니다.\n§7'.@unselected_slot_size.'개의 특성을 더 적용할 수 있습니다.'
                @clickevent = array(
                  'action': 'run_command',
                  'value': '/skillbook select combat_inclination '.@subpage @combat_inclination_info['name']
                )
                @raw0['clickEvent'] = @clickevent
                @raw1['clickEvent'] = @clickevent
              }
            }
            @raw0['hoverEvent']['value'] = @desription
            @raw1['hoverEvent']['value'] = @desription
            @raw[0][] = @raw0
            @raw[1][] = @raw1
          }
        }
        @raw[0][] = array('text': '\n')
        @raw[1][] = array('text': '\n')
        @content = array_merge(@content, array_merge(@raw[0], @raw[1]))
      }
      if(array_size(@paging_array) != 1) {
        if(@page_key == 0) {
          @arrow = array(
            array(
              'text': string_multiply('\n', (5 - @line_key) * 2)
            ),
            array(
              'text':@text['space_fonts']['space.77'].'\ue00d\n',
              'color': 'white'
            ),
            array(
              'text':@text['space_fonts']['space.77'],
              'color': 'white'
            ),
            array(
              'text': '\ue00d',
              'hoverEvent': array(
                'action': 'show_text',
                'value': '다음 페이지'
              ),
              'clickEvent': array(
                'action': 'run_command',
                'value': '/skillbook open combat_inclination'@page_key + 1
              )
            )
          )
        } else if(@page_key == array_size(@paging_array) - 1) {
          @arrow = array(
            array(
              'text': string_multiply('\n', (5 - @line_key) * 2)
            ),
            array(
              'text':@text['space_fonts']['space.28'].'\ue00c\n',
              'color': 'white'
            ),
            array(
              'text':@text['space_fonts']['space.28'],
              'color': 'white'
            ),
            array(
              'text': '\ue00c',
              'hoverEvent': array(
                'action': 'show_text',
                'value': '이전 페이지'
              ),
              'clickEvent': array(
                'action': 'run_command',
                'value': '/skillbook open combat_inclination'@page_key - 1
              )
            )
          )
        } else {
          @arrow = array(
            array(
              'text': string_multiply('\n', (5 - @line_key) * 2)
            ),
            array(
              'text':@text['space_fonts']['space.28'].'\ue00c'.@text['space_fonts']['space.37'].'\ue00d\n',
              'color': 'white'
            ),
            array(
              'text':@text['space_fonts']['space.28'],
              'color': 'white'
            ),
            array(
              'text': '\ue00c',
              'hoverEvent': array(
                'action': 'show_text',
                'value': '이전 페이지'
              ),
              'clickEvent': array(
                'action': 'run_command',
                'value': '/skillbook open combat_inclination'@page_key - 1
              )
            ),
            array(
              'text':@text['space_fonts']['space.37'],
              'color': 'white'
            ),
            array(
              'text': '\ue00d',
              'hoverEvent': array(
                'action': 'show_text',
                'value': '다음 페이지'
              ),
              'clickEvent': array(
                'action': 'run_command',
                'value': '/skillbook open combat_inclination'@page_key + 1
              )
            )
          )
        }
        @content = array_merge(@content, @arrow)
      }
      @pages[] = json_encode(@content)
    }
    open_book(@player, array(@pages[@subpage]))
    break()
  case 'farming_method':
    @harvesting_methods_info = @skills_info['harvesting_method']
    @harvesting_methods = @players_data[@uuid]['skill_data']['harvesting_method']
    @selected_harvesting_method = @players_data[@uuid]['skill_manager'][3]
    @content = array(array('text': '- 수확 방식 목록'))
    foreach(@harvesting_method_info in @harvesting_methods_info) {
      @harvesting_method_data = @harvesting_methods[@harvesting_method_info['name']]
      if(array_size(@harvesting_method_info['desription']) - 1 < @harvesting_method_data[0]) {
        @desription_index = array_size(@harvesting_method_info['desription']) - 1
      } else {
        @desription_index = @harvesting_method_data[0]
      }
      if(@harvesting_method_data[0] == 0) {
        @icon = '\ue00f'
        @name = '???'
      } else {
        @icon = @harvesting_method_info['icon']
        @name = string('Lv.'.@harvesting_method_data[0] @harvesting_method_info['display'])
      }
      @desription = string(@name.'\n'.@harvesting_method_info['desription'][@desription_index].'\n\n')
      @raw0 = array(
        array(
          'text': '\n'.@text['space_fonts']['space.18'],
          'color': 'white',
          'hoverEvent': array(
            'action': 'show_text'
          )
        ),
        array(
          'text': ' Lv.'.@harvesting_method_data[0]'('.@harvesting_method_data[1].'/'.@harvesting_method_data[3].')\n',
          'color': 'black'
        )
      )
      @raw1 = array(
        array(
          'text': @text['space_fonts']['space.1'].@icon,
          'color': 'white',
          'hoverEvent': array(
            'action': 'show_text'
          )
        ),
        array(
          'text': ' ',
          'color': 'white'
        ),
        array(
          'text': string_multiply('', integer(@harvesting_method_data[1] / @harvesting_method_data[3] * 50)).'\n',
          'color': 'green'
        )
      )
      #broadcast(@selected_harvesting_method  @harvesting_method_info['name'])
      if(@harvesting_method_data[0] > 0) {
        if(@selected_harvesting_method == @harvesting_method_info['name']) {
          @select_box = array(
            'text': @text['space_fonts']['space.-18'].'\ue00e'.@text['space_fonts']['space.-1'],
            'color': 'white'
          )
          array_insert(@raw1, @select_box, 1)
          @desription = @desription.'§c좌클릭 시, 해당 방식 사용을 해제합니다.'
          @clickevent = array(
            'action': 'run_command',
            'value': '/skillbook unselect harvesting_method '.@harvesting_method_info['name']
          )
        } else {
          @desription = @desription.'§c좌클릭 시, 해당 방식을 사용합니다.'
          @clickevent = array(
            'action': 'run_command',
            'value': '/skillbook select harvesting_method '.@harvesting_method_info['name']
          )
        }
        @raw0[0]['clickEvent'] = @clickevent
        @raw1[0]['clickEvent'] = @clickevent
      } else {
        @desription = @desription.'§c숙련 레벨을 올린 후,\n해당 방식을 사용할 수 있습니다.'
      }
      @raw0[0]['hoverEvent']['value'] = @desription
      @raw1[0]['hoverEvent']['value'] = @desription
      @content = array_merge(@content, array_merge(@raw0, @raw1))
    }
    @sowing_methods_info = @skills_info['sowing_method']
    @sowing_methods = @players_data[@uuid]['skill_data']['sowing_method']
    @selected_sowing_method = @players_data[@uuid]['skill_manager'][4]
    @content[] = array('text': '\n- 파종 방식 목록')
    foreach(@sowing_method_info in @sowing_methods_info) {
      @sowing_method_data = @sowing_methods[@sowing_method_info['name']]
      if(array_size(@sowing_method_info['desription']) - 1 < @sowing_method_data[0]) {
        @desription_index = array_size(@sowing_method_info['desription']) - 1
      } else {
        @desription_index = @sowing_method_data[0]
      }
      if(@sowing_method_data[0] == 0) {
        @icon = '\ue00f'
        @name = '???'
      } else {
        @icon = @sowing_method_info['icon']
        @name = string('Lv.'.@sowing_method_data[0] @sowing_method_info['display'])
      }
      @desription = string(@name.'\n'.@sowing_method_info['desription'][@desription_index].'\n\n')
      @raw0 = array(
        array(
          'text': '\n'.@text['space_fonts']['space.18'],
          'color': 'white',
          'hoverEvent': array(
            'action': 'show_text'
          )
        ),
        array(
          'text': ' Lv.'.@sowing_method_data[0]'('.@sowing_method_data[1].'/'.@sowing_method_data[3].')\n',
          'color': 'black'
        )
      )
      @raw1 = array(
        array(
          'text': @text['space_fonts']['space.1'].@icon,
          'color': 'white',
          'hoverEvent': array(
            'action': 'show_text'
          )
        ),
        array(
          'text': ' ',
          'color': 'white'
        ),
        array(
          'text': string_multiply('', integer(@sowing_method_data[1] / @sowing_method_data[3] * 50)).'\n',
          'color': 'green'
        )
      )
      if(@sowing_method_data[0] > 0) {
        if(@selected_sowing_method == @sowing_method_info['name']) {
          @select_box = array(
            'text': @text['space_fonts']['space.-18'].'\ue00e'.@text['space_fonts']['space.-1'],
            'color': 'white'
          )
          array_insert(@raw1, @select_box, 1)
          @desription = @desription.'§c좌클릭 시, 해당 방식 사용을 해제합니다.'
          @clickevent = array(
            'action': 'run_command',
            'value': '/skillbook unselect sowing_method '.@sowing_method_info['name']
          )
        } else {
          @desription = @desription.'§c좌클릭 시, 해당 방식을 사용합니다.'
          @clickevent = array(
            'action': 'run_command',
            'value': '/skillbook select sowing_method '.@sowing_method_info['name']
          )
        }
        @raw0[0]['clickEvent'] = @clickevent
        @raw1[0]['clickEvent'] = @clickevent
      } else {
        @desription = @desription.'§c숙련 레벨을 올린 후,\n해당 방식을 사용할 수 있습니다.'
      }
      @raw0[0]['hoverEvent']['value'] = @desription
      @raw1[0]['hoverEvent']['value'] = @desription
      @content = array_merge(@content, array_merge(@raw0, @raw1))
    }
    @arrow = array(
      array(
        'text':@text['space_fonts']['space.28'].'\ue00c'.@text['space_fonts']['space.37'].'\ue00d\n',
        'color': 'white'
      ),
      array(
        'text':@text['space_fonts']['space.28'],
        'color': 'white'
      ),
      array(
        'text': '\ue00c',
        'hoverEvent': array(
          'action': 'show_text',
          'value': '이전 페이지'
        ),
        'clickEvent': array(
          'action': 'run_command',
          'value': '/skillbook open combat'
        )
      ),
      array(
        'text':@text['space_fonts']['space.37'],
        'color': 'white'
      ),
      array(
        'text': '\ue00d',
        'hoverEvent': array(
          'action': 'show_text',
          'value': '다음 페이지'
        ),
        'clickEvent': array(
          'action': 'run_command',
          'value': '/skillbook open farming 0'
        )
      )
    )
    @content = array_merge(@content, @arrow)
    open_book(@player, array(json_encode(@content)))
    break()
  case 'farming':
    switch(@subpage) {
    case 0:
      @farming_skills_info = array_get(@skills_info['farming'], cslice(0, 3))
      @farming_skills = @players_data[@uuid]['skill_data']['farming']
      @content = array(
        array(
          'text': '- 농사 숙련\n',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '적용중인 전투 방식과 전투특성을 간략히 보여줍니다.\n\n§c각각의 아이콘을 클릭하여자세히 확인 할 수 있으며\n전투 방식과 전투 특성을 변경 할 수 있습니다.'
          )
        )
      )
      foreach(@farming_skill_info in @farming_skills_info) {
        @farming_skill_data = @farming_skills[@farming_skill_info['name']]
        if(array_size(@farming_skill_info['desription']) - 1 < @farming_skill_data[0]) {
          @desription_index = array_size(@farming_skill_info['desription']) - 1
        } else {
          @desription_index = @farming_skill_data[0]
        }
        if(@farming_skill_data[0] == 0) {
          @icon = '\ue00f'
          @name = '???'
          @desription = string(@name.'\n'.@farming_skill_info['desription'][@desription_index]).'\n\n§c숙련 레벨이 올르면,\n해당 스킬이 적용됩니다.'
        } else {
          @icon = @farming_skill_info['icon']
          @name = string('Lv.'.@farming_skill_data[0] @farming_skill_info['display'])
          @desription = string(@name.'\n'.@farming_skill_info['desription'][@desription_index])
        }
        @raw0 = array(
          array(
            'text': '\n'.@text['space_fonts']['space.18'],
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text'
            )
          ),
          array(
            'text': ' Lv.'.@farming_skill_data[0]'('.@farming_skill_data[1].'/'.@farming_skill_data[3].')\n',
            'color': 'black'
          )
        )
        @raw1 = array(
          array(
            'text': @text['space_fonts']['space.1'].@icon,
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text'
            )
          ),
          array(
            'text': ' ',
            'color': 'white'
          ),
          array(
            'text': string_multiply('', integer(@farming_skill_data[1] / @farming_skill_data[3] * 50)).'\n',
            'color': 'green'
          )
        )
        @raw0[0]['hoverEvent']['value'] = @desription
        @raw1[0]['hoverEvent']['value'] = @desription
        @content = array_merge(@content, array_merge(@raw0, @raw1))
      }
      @arrow = array(
        array(
          'text':@text['space_fonts']['space.28'].'\ue00c'.@text['space_fonts']['space.37'].'\ue00d\n',
          'color': 'white'
        ),
        array(
          'text':@text['space_fonts']['space.28'],
          'color': 'white'
        ),
        array(
          'text': '\ue00c',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '이전 페이지'
          ),
          'clickEvent': array(
            'action': 'run_command',
            'value': '/skillbook open farming_method'
          )
        ),
        array(
          'text':@text['space_fonts']['space.37'],
          'color': 'white'
        ),
        array(
          'text': '\ue00d',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '다음 페이지'
          ),
          'clickEvent': array(
            'action': 'run_command',
            'value': '/skillbook open farming 1'
          )
        )
      )
      @content = array_merge(@content, @arrow)
      open_book(@player, array(json_encode(@content)))
      break()
    case 1:
      @farming_skills_info = array_get(@skills_info['farming'], cslice(4, 7))
      @farming_skills = @players_data[@uuid]['skill_data']['farming']
      @content = array(
        array(
          'text': '- 농사 숙련\n',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '적용중인 전투 방식과 전투특성을 간략히 보여줍니다.\n\n§c각각의 아이콘을 클릭하여자세히 확인 할 수 있으며\n전투 방식과 전투 특성을 변경 할 수 있습니다.'
          )
        )
      )
      foreach(@farming_skill_info in @farming_skills_info) {
        @farming_skill_data = @farming_skills[@farming_skill_info['name']]
        if(array_size(@farming_skill_info['desription']) - 1 < @farming_skill_data[0]) {
          @desription_index = array_size(@farming_skill_info['desription']) - 1
        } else {
          @desription_index = @farming_skill_data[0]
        }
        if(@farming_skill_data[0] == 0) {
          @icon = '\ue00f'
          @name = '???'
          @desription = string(@name.'\n'.@farming_skill_info['desription'][@desription_index]).'\n\n§c숙련 레벨이 올르면,\n해당 스킬이 적용됩니다.'
        } else {
          @icon = @farming_skill_info['icon']
          @name = string('Lv.'.@farming_skill_data[0] @farming_skill_info['display'])
          @desription = string(@name.'\n'.@farming_skill_info['desription'][@desription_index])
        }
        @raw0 = array(
          array(
            'text': '\n'.@text['space_fonts']['space.18'],
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text'
            )
          ),
          array(
            'text': ' Lv.'.@farming_skill_data[0]'('.@farming_skill_data[1].'/'.@farming_skill_data[3].')\n',
            'color': 'black'
          )
        )
        @raw1 = array(
          array(
            'text': @text['space_fonts']['space.1'].@icon,
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text'
            )
          ),
          array(
            'text': ' ',
            'color': 'white'
          ),
          array(
            'text': string_multiply('', integer(@farming_skill_data[1] / @farming_skill_data[3] * 50)).'\n',
            'color': 'green'
          )
        )
        @raw0[0]['hoverEvent']['value'] = @desription
        @raw1[0]['hoverEvent']['value'] = @desription
        @content = array_merge(@content, array_merge(@raw0, @raw1))
      }
      @arrow = array(
        array(
          'text':@text['space_fonts']['space.28'].'\ue00c'.@text['space_fonts']['space.37'].'\ue00d\n',
          'color': 'white'
        ),
        array(
          'text':@text['space_fonts']['space.28'],
          'color': 'white'
        ),
        array(
          'text': '\ue00c',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '이전 페이지'
          ),
          'clickEvent': array(
            'action': 'run_command',
            'value': '/skillbook open farming 0'
          )
        ),
        array(
          'text':@text['space_fonts']['space.37'],
          'color': 'white'
        ),
        array(
          'text': '\ue00d',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '다음 페이지'
          ),
          'clickEvent': array(
            'action': 'run_command',
            'value': '/skillbook open mining 0'
          )
        )
      )
      @content = array_merge(@content, @arrow)
      open_book(@player, array(json_encode(@content)))
      break()
    }
    break()
  case 'mining':
    switch(@subpage) {
    case 0:
      @mining_skills_info = array_get(@skills_info['mining'], cslice(0, 3))
      @mining_skills = @players_data[@uuid]['skill_data']['mining']
      @content = array(
        array(
          'text': '- 채광 숙련\n',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '적용중인 전투 방식과 전투특성을 간략히 보여줍니다.\n\n§c각각의 아이콘을 클릭하여자세히 확인 할 수 있으며\n전투 방식과 전투 특성을 변경 할 수 있습니다.'
          )
        )
      )
      foreach(@mining_skill_info in @mining_skills_info) {
        @mining_skill_data = @mining_skills[@mining_skill_info['name']]
        if(array_size(@mining_skill_info['desription']) - 1 < @mining_skill_data[0]) {
          @desription_index = array_size(@mining_skill_info['desription']) - 1
        } else {
          @desription_index = @mining_skill_data[0]
        }
        if(@mining_skill_data[0] == 0) {
          @icon = '\ue00f'
          @name = '???'
          @desription = string(@name.'\n'.@mining_skill_info['desription'][@desription_index]).'\n\n§c숙련 레벨이 올르면,\n해당 스킬이 적용됩니다.'
        } else {
          @icon = @mining_skill_info['icon']
          @name = string('Lv.'.@mining_skill_data[0] @mining_skill_info['display'])
          @desription = string(@name.'\n'.@mining_skill_info['desription'][@desription_index])
        }
        @raw0 = array(
          array(
            'text': '\n'.@text['space_fonts']['space.18'],
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text'
            )
          ),
          array(
            'text': ' Lv.'.@mining_skill_data[0]'('.@mining_skill_data[1].'/'.@mining_skill_data[3].')\n',
            'color': 'black'
          )
        )
        @raw1 = array(
          array(
            'text': @text['space_fonts']['space.1'].@icon,
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text'
            )
          ),
          array(
            'text': ' ',
            'color': 'white'
          ),
          array(
            'text': string_multiply('', integer(@mining_skill_data[1] / @mining_skill_data[3] * 50)).'\n',
            'color': 'green'
          )
        )
        @raw0[0]['hoverEvent']['value'] = @desription
        @raw1[0]['hoverEvent']['value'] = @desription
        @content = array_merge(@content, array_merge(@raw0, @raw1))
      }
      @arrow = array(
        array(
          'text':@text['space_fonts']['space.28'].'\ue00c'.@text['space_fonts']['space.37'].'\ue00d\n',
          'color': 'white'
        ),
        array(
          'text':@text['space_fonts']['space.28'],
          'color': 'white'
        ),
        array(
          'text': '\ue00c',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '이전 페이지'
          ),
          'clickEvent': array(
            'action': 'run_command',
            'value': '/skillbook open farming 1'
          )
        ),
        array(
          'text':@text['space_fonts']['space.37'],
          'color': 'white'
        ),
        array(
          'text': '\ue00d',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '다음 페이지'
          ),
          'clickEvent': array(
            'action': 'run_command',
            'value': '/skillbook open mining 1'
          )
        )
      )
      @content = array_merge(@content, @arrow)
      open_book(@player, array(json_encode(@content)))
      break()
    case 1:
      @mining_skills_info = array_get(@skills_info['mining'], cslice(4, 6))
      @mining_skills = @players_data[@uuid]['skill_data']['mining']
      @content = array(
        array(
          'text': '- 채광 숙련\n',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '적용중인 전투 방식과 전투특성을 간략히 보여줍니다.\n\n§c각각의 아이콘을 클릭하여자세히 확인 할 수 있으며\n전투 방식과 전투 특성을 변경 할 수 있습니다.'
          )
        )
      )
      foreach(@mining_skill_info in @mining_skills_info) {
        @mining_skill_data = @mining_skills[@mining_skill_info['name']]
        if(array_size(@mining_skill_info['desription']) - 1 < @mining_skill_data[0]) {
          @desription_index = array_size(@mining_skill_info['desription']) - 1
        } else {
          @desription_index = @mining_skill_data[0]
        }
        if(@mining_skill_data[0] == 0) {
          @icon = '\ue00f'
          @name = '???'
          @desription = string(@name.'\n'.@mining_skill_info['desription'][@desription_index]).'\n\n§c숙련 레벨이 올르면,\n해당 스킬이 적용됩니다.'
        } else {
          @icon = @mining_skill_info['icon']
          @name = string('Lv.'.@mining_skill_data[0] @mining_skill_info['display'])
          @desription = string(@name.'\n'.@mining_skill_info['desription'][@desription_index])
        }
        @raw0 = array(
          array(
            'text': '\n'.@text['space_fonts']['space.18'],
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text'
            )
          ),
          array(
            'text': ' Lv.'.@mining_skill_data[0]'('.@mining_skill_data[1].'/'.@mining_skill_data[3].')\n',
            'color': 'black'
          )
        )
        @raw1 = array(
          array(
            'text': @text['space_fonts']['space.1'].@icon,
            'color': 'white',
            'hoverEvent': array(
              'action': 'show_text'
            )
          ),
          array(
            'text': ' ',
            'color': 'white'
          ),
          array(
            'text': string_multiply('', integer(@mining_skill_data[1] / @mining_skill_data[3] * 50)).'\n',
            'color': 'green'
          )
        )
        @raw0[0]['hoverEvent']['value'] = @desription
        @raw1[0]['hoverEvent']['value'] = @desription
        @content = array_merge(@content, array_merge(@raw0, @raw1))
      }
      @arrow = array(
        array(
          'text': '\n\n\n'.@text['space_fonts']['space.28'].'\ue00c'.'\n',
          'color': 'white'
        ),
        array(
          'text': @text['space_fonts']['space.28'],
          'color': 'white'
        ),
        array(
          'text': '\ue00c',
          'hoverEvent': array(
            'action': 'show_text',
            'value': '이전 페이지'
          ),
          'clickEvent': array(
            'action': 'run_command',
            'value': '/skillbook open mining 0'
          )
        )
      )
      @content = array_merge(@content, @arrow)
      open_book(@player, array(json_encode(@content)))
      break()
    }
    break()
  }
}

proc _mineral_mine_event(@event, @player, @uuid, @players_data, @hp_blocks, @minerals_spec, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  # 부순 블럭 선언
  @mineral = @event['block']
  # 부순 블럭이 광물일시
  if(array_contains(array_keys(@minerals_spec), @mineral)) {
    # 광물 스펙 선언
    @mineral_spec = @minerals_spec[@mineral]
    ## 곡괭이 관련 데이터 선언
    # 기본 데이터 선언
    @pickaxe_hardness = 0
    @mining_power = 0
    # 곡괭이 강도 데이터
    @pickaxes_hardness = array(          # 캘수있는 광물
      'WOODEN_PICKAXE': 1,   #나무         (석탄)
      'GOLDEN_PICKAXE': 2,   #돌,금        (석탄, 구리)
      'STONE_PICKAXE': 3,    #구리         (석탄, 구리, 청금석, 철)
      'IRON_PICKAXE': 4,     #철           (석탄, 구리, 청금석, 철, 금, 레드스톤, 다이아)
      'DIAMOND_PICKAXE': 5,  #다이아       (석탄, 구리, 청금석, 철, 금, 레드스톤, 다이아, 고대파편)
      'NETHERITE_PICKAXE': 6 #네더라이트   (석탄, 구리, 청금석, 철, 금, 레드스톤, 다이아, 고대파편)
    )
    if(!is_null(@player_data['item']['main_hand']) && array_contains(array_keys(@pickaxes_hardness), @player_data['item']['main_hand']['name'])) { // 곡괭이로 채굴할시
      # 곡괭이 선언
      @pickaxe = @player_data['item']['main_hand']
      # 곡괭이 강도 설정
      @pickaxe_hardness = @pickaxes_hardness[@pickaxe['name']]
      if(!is_null(@pickaxe['meta'])) {
        if(@pickaxe_hardness == 1 && @pickaxe['meta']['model'] >= 8) {
          @pickaxe_hardness = 2 // 돌 곡괭이 강도 조정
        }
        if(array_index_exists(@pickaxe['meta'], 'modifiers')) {
          foreach(@modifier in @pickaxe['meta']['modifiers']) {
            if(@modifier['attribute'] == 'HORSE_JUMP_STRENGTH') {
              # 채굴 강도 선언
              @mining_power = @modifier['amount']
              break()
            }
          }
        }
      }
    }
    # 위치 선언 (아이템 드랍 위치 기준)
    @location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
    # id 선언 (x.y.z.world)
    @id = array_implode(array(integer(@location['x']), integer(@location['y']), integer(@location['z']), @location['world']), '.')
    # 피통 선언
    @max_hp = @minerals_spec[@mineral]['hp']
    if(@pickaxe_hardness >= @minerals_spec[@mineral]['hardness']) { // 곡괭이로 캘 수 있는 광물일시
      ## 스킬 불러오기
      # 강인한 어깨 배수
      @mining_power_point = @player_data['skill_data']['tough_shoulder'][0]
      @mining_power_multiply = @skills_spec['tough_shoulder']['effect_by_point'][@mining_power_point]['multiply']
      @mining_power *= @mining_power_multiply
      # 채광 숙련 배수
      @mining_mastery_multiply = 1
      if(array_index_exists(@mineral_spec, 'mastery')) {
        @mining_mastery_name = @mineral_spec['mastery']
        @mining_mastery_point = @player_data['skill_data'][@mining_mastery_name][0]
        @mining_mastery_multiply = @skills_spec[@mining_mastery_name]['effect_by_point'][@mining_mastery_point]['multiply']
      }
      # 선광 배수
      @ore_selecting_multiply = 1
      switch(@location['world']) {
      case 'over':
        @ore_selecting_name = 'over_ore_selecting'
        break()
      case 'nether':
        @ore_selecting_name = 'nether_ore_selecting'
        break()
      default:
        @ore_selecting_name = null
        break()
      }
      if(!is_null(@ore_selecting_name)) {
        @ore_selecting_point = @player_data['skill_data'][@ore_selecting_name][0]
        @ore_selecting_multiply = @skills_spec[@ore_selecting_name]['effect_by_point'][@ore_selecting_point]['multiply']
      }
      # 최대 드랍 갯수 배수에 선광 스킬 배수, 인첸트 반영
      @max_drop_multiply = @ore_selecting_multiply
      if(@player_data['item']['enchantments']['main_hand'] == '행운') {
        @max_drop_multiply += 1.5
      }
      # id가 존재하지 않거나 광물이 다른 광물로 바뀔경우 기본데이터로 설정
      if(!array_index_exists(@hp_blocks, @id)) {
        @hp_blocks[@id] = array(
          'name': @mineral,
          'hp': @minerals_spec[@mineral]['hp'],
          'reset_countdown': 3,
          'logs': array(
            'max_drop_multiplies': array(),
            'rank_quality_multiplies': array()
          )
        )
      } else if(@hp_blocks[@id]['name'] != @mineral) {
        @hp_blocks[@id] = array(
          'name': @mineral,
          'hp': @minerals_spec[@mineral]['hp'],
          'reset_countdown': 3,
          'logs': array(
            'max_drop_multiplies': array(),
            'rank_quality_multiplies': array()
          )
        )
      }
      # 체력 깍기 (0이하로 내려거면 0으로 설정) 및 @hp_block 기타 데이터 갱신
      @hp_blocks[@id]['hp'] -= @mining_power
      if(@hp_blocks[@id]['hp'] < 0) {
        @hp_blocks[@id]['hp'] = 0
      }
      @hp_blocks[@id]['reset_countdown'] = 3
      # hp 선언
      @hp = @hp_blocks[@id]['hp']
      # 선광 숙련, 채굴 숙련 기록
      @hp_blocks[@id]['logs']['max_drop_multiplies'][] = @max_drop_multiply
      @hp_blocks[@id]['logs']['rank_quality_multiplies'][] = @mining_mastery_multiply
      # 채굴 도중 일시
      if(@hp > 0) {
        cancel()
        # 수동 내구도 깍기 (캔슬 걸려 있어서 내구도 깍아줘야 함)
        @item = @player_data['item']['main_hand']
        @slot = pheld_slot(@player)
        if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'damage')) {
          @damage = 0
        } else {
          @damage = @item['meta']['damage']
        }
        if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'enchants') || !array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
          @unbreaking_level = 0
        } else {
          @unbreaking_level = @item['meta']['enchants']['unbreaking']['elevel']
        }
        @breaking_chance = 1 / (@unbreaking_level + 1)
        if(rand() < @breaking_chance) {
          if(is_null(@item['meta'])) {
            @item['meta'] = array('damage': @damage + 1)
          } else {
            @item['meta']['damage'] = @damage + 1
          }
          if(material_info(@item['name'], 'maxDurability') == @item['meta']['damage']) {
            play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
            @item = null
            set_inventory_item(puuid(@player), @slot, null)
          } else {
            set_inventory_item(puuid(@player), @slot, @item)
          }
          _update_item(@player, @uuid, array('main_hand': @item), @players_data, @skills_spec, @text)
        }
        # 인디케이터 데이터 설정
        @indicator_data  = array(
          'block': @mineral,
          'max_hp': @max_hp,
          'hp': @hp,
          'countdown': 7
        )
      } else { // 채굴 완료시
        # 채굴 데이터 삭제
        array_remove(@hp_blocks, @id)
        # 채굴 완료 소리
        play_named_sound(@location, array(
          'sound': 'minecraft:entity.player.levelup',
          'category': 'PLAYERS',
          'volume': 0.4,
          'pitch': 1.5
        ), @player)
        # 선광 숙련, 채광 숙련 평균 구하기 (높은 레벨 유저가 막타 치거나 행운곡 막타 방지)
        @mining_mastery_multiply = average(@hp_blocks[@id]['logs']['rank_quality_multiplies']) 
        @max_drop_multiply = average(@hp_blocks[@id]['logs']['max_drop_multiplies'])
        # 루트 테이블 시스템
        @entries = @mineral_spec['loot_table']
        @total_weight = 0
        foreach(@key: @entry in @entries) {
          # 채광 숙련 반영 (채광 숙련 스킬 연관 없는 광물일 경우 배수는 1임)
          @entries[@key]['weight'] += @entry['quality'] * @mining_mastery_multiply
          @total_weight += @entry['weight']
        }
        # 드랍 갯수 설정
        @qty = integer(round(@mineral_spec['default_qty'] * @max_drop_multiply * rand()))
        if(@qty < @mineral_spec['default_qty']) { @qty = @mineral_spec['default_qty']}
        # 드랍 갯수 만큼 아이템 떨구기
        for(@i = 0, @i < @qty, @i++) {
          @result_weight = @total_weight * round(rand(), 5)
          @min_weight = 0
          foreach(@entry in @entries) {
            @max_weight = @min_weight + @entry['weight']
            if(@max_weight > @result_weight) {
              drop_item(@location, @entry['item'], false)
              break()
            } else {
              @min_weight = @max_weight
            }
          }
        }
        # 경험치 드랍
        if(@player_data['item']['enchantments']['main_hand'] == '경험') {
          @xp = integer(round((@mineral_spec['default_xp'] + rand() * @mineral_spec['extra_xp']) * 2))
        } else {
          @xp = integer(round(@mineral_spec['default_xp'] + rand() * @mineral_spec['extra_xp']))
        }
        if(@xp > 0) {
          spawn_entity('EXPERIENCE_ORB', 1, @location, closure(@euuid) {
            set_entity_spec(@euuid, array('amount': @xp))
          })
        }
        # 아이템, 경험치 수동으로 떨구기 때문에 모디피 이벤트로 이벤트 결과 수정
        modify_event('drops', array())
        modify_event('xp', 0)
        # 인디케이터 데이터 설정
        @indicator_data = array(
          'block': @mineral,
          'max_hp': @max_hp,
          'hp': @hp,
          'countdown': 1
        )
      }
    } else { # 곡괭이 강도가 부족할시
      # hp 변화 없어 보이도록 @hp 선언
      if(array_index_exists(@hp_blocks, @id)) {
        @hp = @hp_blocks[@id]['hp']
      } else {
        @hp = @minerals_spec[@mineral]['hp']
      }
      # 인디케이터 데이터 설정
      @indicator_data = array(
        'block': @mineral,
        'max_hp': @max_hp,
        'hp': @hp,
        'countdown': 7
      )
      cancel()
    }
    #인디케이터 보여주기
    @player_data['cache']['indicator'] = @indicator_data
    _set_indicator(@player, @uuid, @player_data, @text)
    #캔슬은 안됬는데 정상적으로 캔게 아닐떼 템 안떨구도록 해주는 코드
    modify_event('drops', array())
  }
}
  
proc _crop_mine_event(@event, @player, @uuid, @players_data, @crops_spec, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  # 부순 블럭 선언
  @crop = @event['block']
  # 부순 블럭이 작물일 시
  if(array_contains(array_keys(@crops_spec), @crop)) {
    # 작물 스펙 선언
    @crop_spec = @crops_spec[@crop]
    ## 스킬 불러오기
    # 수확 숙련 배수
    @farming_mastery_multiply = 1
    if(array_index_exists(@crop_spec, 'mastery')) {
      @farming_mastery_name = @crop_spec['mastery']
      @farming_mastery_point = @player_data['skill_data'][@farming_mastery_name][0]
      @farming_mastery_multiply = @skills_spec[@farming_mastery_name]['effect_by_point'][@farming_mastery_point]['multiply']
    }
    # 풍년 배수
    @plenty_point = @player_data['skill_data']['plenty'][0]
    @plenty_multiply = @skills_spec['plenty']['effect_by_point'][@plenty_point]['multiply']
    # 최대 드랍 갯수 배수에 선광 스킬 배수, 인첸트 반영
    @max_drop_multiply = @plenty_multiply
    if(@player_data['item']['enchantments']['main_hand'] == '행운') {
      @max_drop_multiply += 1.5
    }
    # 수박 호박 수확할 시
    if(array_contains(array('PUMPKIN', 'MELON'), @crop)) {
      @center_location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
      @near_locations = array(
        'east': array(
          'facing': 'west',
          'location': array('x': @center_location['x'] + 1, 'y': @center_location['y'], 'z': @center_location['z'], 'world': @center_location['world'])
        ),
        'west': array(
          'facing': 'east',
          'location': array('x': @center_location['x'] - 1, 'y': @center_location['y'], 'z': @center_location['z'], 'world': @center_location['world'])
        ),
        'south': array(
          'facing': 'north',
          'location': array('x': @center_location['x'], 'y': @center_location['y'], 'z': @center_location['z'] + 1, 'world': @center_location['world'])
        ),
        'north': array(
          'facing': 'south',
          'location': array('x': @center_location['x'], 'y': @center_location['y'], 'z': @center_location['z'] - 1, 'world': @center_location['world'])
        )
      )
      # 줄기가 연결되어 있는지
      @is_placed = true
      foreach(@near_location in @near_locations) {
        if(get_block(@near_location['location']) == @crop_spec['stem'] && get_blockdata(@near_location['location'])['facing'] == @near_location['facing']) {
          @is_placed = false
          break()
        }
      }
      if(!@is_placed) {
        set_timeout(1, closure() {
          if(!is_cancelled()) { // 성공적으로 수확 시
            # 줄기 부수기
            break_block(@near_location['location'])
            # 루트 테이블 시스템
            @entries = @crop_spec['loot_table']
            @total_weight = 0
            foreach(@key: @entry in @entries) {
              @entries[@key]['weight'] += @entry['quality'] * @farming_mastery_multiply
              @total_weight += @entry['weight']
            }
            # 드랍 갯수 설정
            @qty = integer(round(@crop_spec['default_qty'] * @max_drop_multiply * rand()))
            if(@qty < @crop_spec['default_qty']) { @qty = @crop_spec['default_qty']}
            # 드랍 갯수 만큼 아이템 떨구기
            for(@i = 0, @i < @qty, @i++) {
              @result_weight = @total_weight * round(rand(), 5)
              @min_weight = 0
              foreach(@entry in @entries) {
                @max_weight = @min_weight + @entry['weight']
                if(@max_weight > @result_weight) {
                  drop_item(@center_location, @entry['item'], false)
                  break()
                } else {
                  @min_weight = @max_weight
                }
              }
            }
            # 경험치 드랍
            if(@player_data['item']['enchantments']['main_hand'] == '경험') {
              @xp = integer(round((@crop_spec['default_xp'] + rand() * @crop_spec['extra_xp']) * 2))
            } else {
              @xp = integer(round(@crop_spec['default_xp'] + rand() * @crop_spec['extra_xp']))
            }
            if(@xp > 0) {
              spawn_entity('EXPERIENCE_ORB', 1, @center_location, closure(@euuid) {
                set_entity_spec(@euuid, array('amount': @xp))
              })
            }
          }
        })
        # 아이템, 경험치 수동으로 떨구기 때문에 모디피 이벤트로 이벤트 결과 수정
        modify_event('drops', array())
        modify_event('xp', 0)
      }
    } else { //호박 수박 이외의 작물 수확 시
      @locations = array()
      @center_location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
      @harvesting_method = @player_data['skill_manager'][4]['harvesting_method']
      @age = get_blockdata(@center_location)['age']
      set_timeout(1, closure() {
        if(!is_cancelled()) { // 성공적으로 수확 시
          # 괭이 검사
          @item = @player_data['item']['main_hand']
          @slot = pheld_slot(@player)
          if(!is_null(@item) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @item['name'])) {
            # 괭이 수확 내구도 시스템
            @max_durability = material_info(@item['name'], 'maxDurability')
            if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'damage')) {
              @damage = 0
              @item['meta'] = array()
            } else {
              @damage = @item['meta']['damage']
            }
            if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'enchants') || !array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
              @unbreaking_level = 0
            } else {
              @unbreaking_level = @item['meta']['enchants']['unbreaking']['elevel']
            }
            @breaking_chance = 1 / (@unbreaking_level + 1)
            # 수확 방식 적용
            if(@harvesting_method != '' && @player_data['active_skill']['harvesting_method'][@harvesting_method][1] > 0) {
              switch(@harvesting_method) {
              case 'wide_hands':
                if(@age == @crop_spec['max_age']) {
                  if(rand() < @breaking_chance) {
                    @damage += 1
                  }
                  @locations[] = @center_location
                  for(@x = -1, @x < 2, @x++) {
                    for(@z = -1, @z < 2, @z++) {
                      if(@x != 0 || @z != 0) {
                        @surrounding_location = array('x': @center_location['x'] + @x, 'y': @center_location['y'], 'z': @center_location['z'] + @z, 'world': @center_location['world'])
                        if(get_block(@surrounding_location) == @crop && get_blockdata(@surrounding_location)['age'] == @crop_spec['max_age']) {
                          if(@max_durability > @damage) {
                            if(rand() < @breaking_chance) {
                              @damage += 1
                            }
                            #주변 블럭들 부술 블럭 목록에 넣기 및 부수기
                            @locations[] = @surrounding_location
                            break_block(@surrounding_location)
                          }
                        }
                      }
                    }
                  }
                }
                break()
              case 'golden_finger':
                if(@age == @crop_spec['max_age']) {
                  if(rand() < @breaking_chance) {
                    @damage += 1
                  }
                  @locations[] = @center_location
                  array_remove(@event['drops'], 0)
                  foreach(@seed in @event['drops']) {
                    drop_item(@center_location, @seed, false)
                  }
                  if(!is_cancelled()) { // 성공적으로 수확 시 1단계 작물 심기
                    set_timeout(1, closure() {
                      set_block(@center_location, @crop)
                    })
                  }
                } else {
                  #다 안자란 작물 캘려 하면 안캐지도록 캔슬
                  cancel()
                }
                break()
              default:
                if(@age == @crop_spec['max_age']) {
                  if(rand() < @breaking_chance) {
                    @damage += 1
                  }
                  @locations[] = @center_location
                }
                break()
              }
            } else {
              if(@age == @crop_spec['max_age']) {
                if(rand() < @breaking_chance) {
                  @damage += 1
                }
                @locations[] = @center_location
              }
            }
            _update_item(@player, @uuid, array('main_hand': @item), @players_data, @skills_spec, @text)
            # 루트 테이블 시스템
            @entries = @crop_spec['loot_table']
            @total_weight = 0
            foreach(@key: @entry in @entries) {
              @entries[@key]['weight'] += @entry['quality'] * @farming_mastery_multiply
              @total_weight += @entry['weight']
            }
            # 부순 모든 작물에 드랍 시스템 작동
            foreach(@location in @locations) {
              # 드랍 갯수 설정
              @qty = integer(round(@crop_spec['default_qty'] * @max_drop_multiply * rand()))
              if(@qty < @crop_spec['default_qty']) { @qty = @crop_spec['default_qty']}
              # 드랍 갯수 만큼 아이템 떨구기
              for(@i = 0, @i < @qty, @i++) {
                @result_weight = @total_weight * round(rand(), 5)
                @min_weight = 0
                foreach(@entry in @entries) {
                  @max_weight = @min_weight + @entry['weight']
                  if(@max_weight > @result_weight) {
                    drop_item(@location, @entry['item'], false)
                    break()
                  } else {
                    @min_weight = @max_weight
                  }
                }
              }
              # 경험치 드랍
              if(@player_data['item']['enchantments']['main_hand'] == '경험') {
                @xp = integer(round((@crop_spec['default_xp'] + rand() * @crop_spec['extra_xp']) * 2))
              } else {
                @xp = integer(round(@crop_spec['default_xp'] + rand() * @crop_spec['extra_xp']))
              }
              if(@xp > 0) {
                spawn_entity('EXPERIENCE_ORB', 1, @location, closure(@euuid) {
                  set_entity_spec(@euuid, array('amount': @xp))
                })
              }
            }
            # 내구도 깍기 및 다 부셔지면 아이템 없애기
            if(@max_durability > @damage) {
              @item['meta']['damage'] = @damage
              set_inventory_item(puuid(@player), @slot, @item)
            } else {
              play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
              @item = null
              set_inventory_item(puuid(@player), @slot, @item)
            }
          }
        }
      })
    }
  }
}

proc _farmland_sow_event(@event, @player, @uuid, @players_data, @hp_blocks, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  @block = @event['block']
  if(@event['action'] == 'right_click_block' && array_contains(array('GRASS_BLOCK', 'DIRT'), @event['block']) && !is_null(@event['item']) && array_index_exists(@event, 'location')) {
    @location = array('x': @event['location']['x'], 'y': @event['location']['y'], 'z': @event['location']['z'], 'world': @event['location']['world'])
    @hoes_cooldown = array(
      'WOODEN_HOE': 40,
      'STONE_HOE': 28,
      'IRON_HOE': 20,
      'DIAMOND_HOE': 12,
      'NETHERITE_HOE': 8,
      'GOLDEN_HOE': 4
    )
    if(array_contains(array_keys(@hoes_cooldown), @event['item']['name']) && array_contains(array('AIR', 'CAVE_AIR', 'VOID_AIR'), get_block(array('x': @location['x'], 'y': @location['y'] + 1, 'z': @location['z'], 'world': @location['world'])))) {
      if(@event['hand'] == 'main_hand') {
        @slot = pheld_slot(@player)
      } else {
        @slot = 40
      }
      @item = @player_data['item'][@event['hand']]
      if(pcooldown(@player, @item['name']) == 0) {
        if(@player_data['item']['enchantments'][@event['hand']] == '효율') {
          @cooldown_multiply = 0.75
        } else {
          @cooldown_multiply = 1
        }
        foreach(@hoe:@hoe_cooldown in @hoes_cooldown) {
          if(@hoe_cooldown > @hoes_cooldown[@item['name']]) {
            set_pcooldown(@player, @hoe, @hoe_cooldown)
          } else {
            set_pcooldown(@player, @hoe, integer(@hoes_cooldown[@item['name']] * @cooldown_multiply))
          }
        }
        @sowing_power = 1
        if(!is_null(@item['meta']) && !is_null(@item['meta']['modifiers']) && array_index_exists(@item['meta'], 'modifiers')) {
          foreach(@modifier in @item['meta']['modifiers']) {
            if(@modifier['attribute'] == 'GENERIC_FOLLOW_RANGE') {
              @sowing_power = @modifier['amount']
              break()
            }
          }
        }
        @max_hp = 20
        @id = array_implode(array(integer(@location['x']), integer(@location['y']), integer(@location['z']), @location['world']), '.')
        if(!array_index_exists(@hp_blocks, @id)) {
          @hp_blocks[@id] = array(
            'name': @block,
            'hp': @max_hp,
            'reset_countdown': 3
          )
        } else if(@hp_blocks[@id]['name'] != @block) {
          @hp_blocks[@id] = array(
            'name': @block,
            'hp': @max_hp,
            'reset_countdown': 3
          )
        }
        @hp_blocks[@id]['hp'] -= @sowing_power
        if(@hp_blocks[@id]['hp'] > 0) {
          @hp_blocks[@id]['reset_countdown'] = 3
          @hp = @hp_blocks[@id]['hp']
          @indicator_data = array(
            'block': 'FARMLAND',
            'max_hp': @max_hp,
            'hp': @hp,
            'countdown': 3
          )
          @player_data['cache']['indicator'] = @indicator_data
          _set_indicator(@player, @uuid, @player_data, @text)
          set_block(@location, @block)
          if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'damage')) {
            @damage = 0
          } else {
            @damage = @item['meta']['damage']
          }
          if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'enchants') || !array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
            @unbreaking_level = 0
          } else {
            @unbreaking_level = @item['meta']['enchants']['unbreaking']['elevel']
          }
          @breaking_chance = 1 / (@unbreaking_level + 1)
          if(rand() < @breaking_chance) {
            if(is_null(@item['meta'])) {
              @item['meta'] = array('damage': @damage + 1)
            } else {
              @item['meta']['damage'] = @damage + 1
            }
            if(material_info(@item['name'], 'maxDurability') == @item['meta']['damage']) {
              play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
              set_inventory_item(puuid(@player), @slot, null)
            } else {
              set_inventory_item(puuid(@player), @slot, @item)
            }
            if(@slot == 40) {
              @items = array('off_hand': @item)
            } else {
              @items = array('main_hand': @item)
            }
            _update_item(@player, @uuid, @items, @players_data, @skills_spec, @text)
          }
        } else {
          @hp = 0
          @indicator_data = array(
            'block': 'FARMLAND',
            'max_hp': @max_hp,
            'hp': @hp,
            'countdown': 1
          )
          @player_data['cache']['indicator'] = @indicator_data
          _set_indicator(@player, @uuid, @player_data, @text)
        }
      }
    }
  }
}

proc _player_attack_event(@event, @player, @puuid, @euuid, @players_data, @skills_spec, @allowed_entity, @text, @server) {
  # 기본 변수 선언
  @player_data = @players_data[@puuid]
  @skill_manager = @player_data['skill_manager']
  @selected_combat_method = @selected_methods['combat_method']
  @selected_runes = @skill_manager[5]
  @skills_data = @player_data['skill_data']
  # 전투 관련 데이터들 불러오기
  ## 공격 쿨타임
  @attack_cooldown = pattack_cooldown(@player)
  ## 공격 피해
  @attribute_attack_damage = entity_attribute_value(@puuid, 'GENERIC_ATTACK_DAMAGE')
  ## 공격 속도
  @attribute_attack_speed = entity_attribute_value(@puuid, 'GENERIC_ATTACK_SPEED')
  # 공속에 따른 무적 시간 설정
  if(!is_null(@items['main_hand']) && array_contains(@weapons, @items['main_hand']['name'])) {
    @immunity_tick = integer(20 / @attribute_attack_speed)
    if(@immunity_tick < 20) {
      set_timeout(0, closure( set_entity_immunity_ticks(@euuid, @immunity_tick) ))
    }
  }
  # 스킬 효과 적용
  ## 전투 방식
  if(@selected_combat_method != '') {
    @proc_name = "_apply_attacking_by_@selected_combat_method"
    if(is_proc(@proc_name)) {
      @category = 'combat_method'
      @point = @skill_manager
      @skill_spec = @skills_spec[@selected_combat_method]
      @skill_data = @player_data['skill_data'][@skill]
      @point = @skill_data[0]
      call_proc(@proc_name, @event, @player_data, @player, @uuid, @category, @selected_combat_method, @skill_spec, @point, @attack_cooldown, @attribute_attack_damage, @attribute_attack_speed)
    }
  }
  ## 룬
  foreach(@selected_rune in @selected_runes) {
    @proc_name = "_apply_attacking_by_@selected_combat_method"
    if(is_proc(@proc_name)) {
      @category = 'rune'
      @point = @skill_manager
      @skill_spec = @skills_spec[@selected_rune]
      @skill_data = @player_data['skill_data'][@skill]
      @point = @skill_data[0]
      call_proc(@proc_name, @event, @player_data, @player, @uuid, @category, @selected_combat_method, @skill_spec, @point, @attack_cooldown, @attribute_attack_damage, @attribute_attack_speed)
    }
  }
  # 인첸트
  @time = time()
  ## 인첸트 미반영시 기본 네더 필드 효과 뎀지 배수 선언
  @nether_field_effect_multiply = 0.5
  ## 무기 인첸트
  @weapon_enchant = @items['enchantments']['main_hand']
  if(@weapon_enchant) {
    @weapon_chance_multiply = (@time - @player_data['cache']['last_weapon_effect']) / 5000
    if(@weapon_chance_multiply > 1) {
      @weapon_chance_multiply = 1
    }
    @weapon_chance_multiply *= @attack_cooldown
    switch(@weapon_enchant) {
    case '효율':
      @event['amount'] *= 1.2
      break()
    case '전격':
      if(rand() < 0.1 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        @entity_location = entity_loc(@euuid)
        if((get_highest_block_at(@entity_location)['y'] <= @entity_location['y'] + 2 && (has_thunder(@entity_location['world']) || has_storm(@entity_location['world']))) || get_block(@entity_location) == 'WATER') {
          @range = 10
        } else {
          @range = 5
        }
        @entity_location['x'] += rand() / 2 - 0.25
        @entity_location['y'] += 1 + rand() * @allowed_entity[@entity_type] * 0.5 - @allowed_entity[@entity_type] * 0.25
        @entity_location['z'] += rand() / 2 - 0.25
        mom_playerparticle(@puuid, 'FIREWORKS_SPARK', @entity_location['x'], @entity_location['y'], @entity_location['z'], 4, 0.1, 0.1, 0.1, 0.05)
        @near_entities = entities_in_radius(@entity_location, @range)
        #
        #
        #array_remove_values(@near_entities, @puuid)
        array_remove_values(@near_entities, @euuid)
        foreach(@near_entity in @near_entities) {
          @near_entity_type = entity_type(@near_entity)
          if(array_contains(array_keys(@allowed_entity), @near_entity_type)) {
            @near_entity_location = entity_loc(@near_entity)
            @near_entity_location['x'] += rand() / 2 - 0.25
            @near_entity_location['y'] += 1 + rand() * @allowed_entity[@near_entity_type] * 0.5 - @allowed_entity[@near_entity_type] * 0.25
            @near_entity_location['z'] += rand() / 2 - 0.25
            mom_playerparticle(@puuid, 'FIREWORKS_SPARK', @near_entity_location['x'], @near_entity_location['y'], @near_entity_location['z'], 4, 0.1, 0.1, 0.1, 0.05)
            @distance = distance(@entity_location,  @near_entity_location)
            for(@i = 0, @i < distance(@entity_location,  @near_entity_location), @i += 0.25 + rand() * 0.25) {
              @pos = location_shift(@entity_location,  @near_entity_location, @i)
              mom_playerparticle(@puuid, 'FIREWORKS_SPARK', @pos['x'], @pos['y'], @pos['z'], 1, 0.0, 0.0, 0.0, 0.0)
            }
            damage_entity(@near_entity, 2)
          }
        }
      }
      break()
    case '천둥':
      if(rand() < 0.25 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        @entity_location = entity_loc(@euuid)
        @range = 5
        @has_storm = false
        if(get_block(@entity_location) == 'WATER') {
          @range = 10
        }
        if(get_highest_block_at(@entity_location)['y'] <= @entity_location['y'] + 2) {
          if(has_thunder(@entity_location['world'])) {
            @range = 10
          } else if(has_storm(@entity_location['world'])) {
            @range = 10
            @has_storm = true
          }
        }
        if(@has_storm) {
          lightning(@entity_location)
        }
        @entity_location['x'] += rand() / 2 - 0.25
        @entity_location['y'] += 1 + rand() * @allowed_entity[@entity_type] * 0.5 - @allowed_entity[@entity_type] * 0.25
        @entity_location['z'] += rand() / 2 - 0.25
        mom_playerparticle(@puuid, 'FIREWORKS_SPARK', @entity_location['x'], @entity_location['y'], @entity_location['z'], 4, 0.1, 0.1, 0.1, 0.05)
        @near_entities = entities_in_radius(@entity_location, @range)
        #array_remove_values(@near_entities, @puuid)
        array_remove_values(@near_entities, @euuid)
        foreach(@near_entity in @near_entities) {
          @near_entity_type = entity_type(@near_entity)
          if(array_contains(array_keys(@allowed_entity), @near_entity_type)) {
            @near_entity_location = entity_loc(@near_entity)
            @near_entity_location['x'] += rand() / 2 - 0.25
            @near_entity_location['y'] += 1 + rand() * @allowed_entity[@near_entity_type] * 0.5 - @allowed_entity[@near_entity_type] * 0.25
            @near_entity_location['z'] += rand() / 2 - 0.25
            mom_playerparticle(@puuid, 'FIREWORKS_SPARK', @near_entity_location['x'], @near_entity_location['y'], @near_entity_location['z'], 4, 0.1, 0.1, 0.1, 0.05)
            @distance = distance(@entity_location,  @near_entity_location)
            for(@i = 0, @i < distance(@entity_location,  @near_entity_location), @i += 0.25 + rand() * 0.25) {
              @pos = location_shift(@entity_location,  @near_entity_location, @i)
              mom_playerparticle(@puuid, 'FIREWORKS_SPARK', @pos['x'], @pos['y'], @pos['z'], 1, 0.0, 0.0, 0.0, 0.0)
            }
            damage_entity(@near_entity, 2)
          }
        }
      }
      break()
    case '화염':
      if(rand() < 0.1 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        set_entity_onfire(@euuid, entity_onfire(@euuid) + 5)
      }
      break()
    case '유황불':
      if(rand() < 0.25 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        if(entity_onfire(@euuid) > 0) {
          set_mob_effect(@euuid, 'WEAKNESS', 0, 3, false, true)
        }
        set_entity_onfire(@euuid, entity_onfire(@euuid) + 5)
      }
      break()
    case '냉기':
      @nether_field_effect_multiply = 0.625
      if(rand() < 0.1 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        set_mob_effect(@euuid, 'SLOWNESS', 1, 10, false, true)
      }
      break()
    case '빙결':
      @nether_field_effect_multiply = 1
      if(rand() < 0.25 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        set_mob_effect(@euuid, 'SLOWNESS', 1, 10, false, true)
      }
      if(rand() < 0.025 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        set_mob_effect(@euuid, 'SLOWNESS', 5, 4, false, true)
      }
      break()
    case '신성':
      @undead_entities = array(
        'DROWNED',
        'HUSK',
        'PHANTOM',
        'SKELETON',
        'SKELETON_HORSE',
        'STRAY',
        'WITHER',
        'WITHER_SKELETON',
        'ZOGLIN',
        'ZOMBIE',
        'ZOMBIE_HORSE',
        'ZOMBIE_VILLAGER',
        'ZOMBIFIED_PIGLIN'
      )
      if(array_contains(@undead_entities, entity_type(@euuid)) && rand() < 0.1 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        set_mob_effect(@euuid, 'INSTANT_HEALTH', 1, 0.1, false, true)
      }
      break()
    case '퇴마':
      @undead_entities = array(
        'DROWNED',
        'HUSK',
        'PHANTOM',
        'SKELETON',
        'SKELETON_HORSE',
        'STRAY',
        'WITHER',
        'WITHER_SKELETON',
        'ZOGLIN',
        'ZOMBIE',
        'ZOMBIE_HORSE',
        'ZOMBIE_VILLAGER',
        'ZOMBIFIED_PIGLIN'
      )
      if(array_contains(@undead_entities, entity_type(@euuid)) && rand() < 0.25 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        set_mob_effect(@euuid, 'INSTANT_HEALTH', 2, 0.1, false, true)
      }
      break()
    case '독성':
      if(rand() < 0.1 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        set_mob_effect(@euuid, 'POISON', 0, 5, false, true)
      }
      break()
    case '맹독':
      if(rand() < 0.1 * @weapon_chance_multiply) {
        @player_data['cache']['last_weapon_effect'] = @time
        set_mob_effect(@euuid, 'POISON', 4, 5, false, true)
      }
      break()
    }
  }
  ## 방어구 인첸트
  @armor_enchant = @items['enchantments']['armor']
  if(@armor_enchant && entity_type(@euuid) != 'PLAYER') {
    @armor_chance_multiply = (@time - @player_data['cache']['last_armor_effect']) / 5000
    if(@armor_chance_multiply > 1) {
      @armor_chance_multiply = 1
    }
    @armor_chance_multiply *= @attack_cooldown
    switch(@items['enchantments']['armor']) {
    case '복원':
      if(rand() < 0.1 * @armor_chance_multiply) {
        @player_data['cache']['last_armor_effect'] = @time
        if(!is_null(@items['main_hand']) && !is_null(@items['main_hand']['meta']) && @items['main_hand']['meta']['damage'] > 0) {
          if(@items['armor']['meta']['damage'] > 0) {
            if(rand() < 0.5) {
              @items['main_hand']['meta']['damage'] -= 1
              set_inventory_item(@puuid, pheld_slot(@player), @items['main_hand'])
              _update_item(@player, @puuid, array('main_hand': @items['main_hand']), @players_data, @skills_spec, @text)
            } else {
              @items['armor']['meta']['damage'] -= 1
              _update_item(@player, @puuid, array('armor': @items['armor']), @players_data, @skills_spec, @text)
              set_inventory_item(@puuid, 36, @items['armor'])
            }
          } else {
            @items['main_hand']['meta']['damage'] -= 1
            _update_item(@player, @puuid, array('main_hand': @items['main_hand']), @players_data, @skills_spec, @text)
            set_inventory_item(@puuid, pheld_slot(@player), @items['main_hand'])
          }
        } else {
          if(@items['armor']['meta']['damage'] > 0) {
            @items['armor']['meta']['damage'] -= 1
            _update_item(@player, @puuid, array('armor': @items['armor']), @players_data, @skills_spec, @text)
            set_inventory_item(@puuid, 36, @items['armor'])
          }
        }
      }
      break()
    case '친수성':
      if(rand() < 0.1 * @armor_chance_multiply) {
        @player_data['cache']['last_armor_effect'] = @time
        set_mob_effect(@puuid, 'WATER_BREATHING', 0, 5, false, true)
      }
      break()
    case '포화':
      if(rand() < 0.1 * @armor_chance_multiply) {
        @player_data['cache']['last_armor_effect'] = @time
        set_mob_effect(@puuid, 'SATURATION', 0, 0.05, false, true)
      }
      break()
    case '재생':
      if(rand() < 0.1 * @armor_chance_multiply) {
        @player_data['cache']['last_armor_effect'] = @time
        set_mob_effect(@puuid, 'REGENERATION', 2, 1, false, true)
      }
      break()
    case '저항':
      if(rand() < 0.1 * @armor_chance_multiply) {
        @player_data['cache']['last_armor_effect'] = @time
        set_mob_effect(@puuid, 'RESISTANCE', 2, 5, false, true)
      }
      break()
    case '힘':
      if(rand() < 0.1 * @armor_chance_multiply) {
        @player_data['cache']['last_armor_effect'] = @time
        set_mob_effect(@puuid, 'STRENGTH', 1, 5, false, true)
      }
      break()
    }
  }
  # 지옥 필드 효과 반영
  if(@server != 'nether') { //지옥이 아닐경수 효과 없도록 배수 1로 설정
    @nether_field_effect_multiply = 1
  }
  @event['amount'] *= @nether_field_effect_multiply // 반영
  # 모디피 이벤트 (실제 반영)
  modify_event('amount', @event['amount'])
}