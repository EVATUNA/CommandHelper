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
      case 'hitted.ms':
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
  if(is_null(@skill_manager)) {
    # 기본 값
    @default_level = 0
    @default_experience = 0
    @default_extra_point = 0
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
      @default_extra_point,
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
  if(is_null(@skill_data)) {
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
      switch(@category) {
      case 'combat_method':
        @selected_method = @selected_combat_method
        break()
      case 'sowing_method':
        @selected_method = @selected_sowing_method
        break()
      case 'harvesting_method':
        @selected_method = @selected_harvesting_method
        break()
      case 'rune':
        @selected_method = @selected_runes
      }
      call_proc(@proc_name, @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @selected_method)
    }
  }
}

## 스킬 리셋 (액티브 스킬 설정 초기화, 투자 포인트 초기화, 각각의 스킬 포인트 초기화)
# 사용 확인 gui
# 아이템 사용
proc _ask_using_skill_reset_scroll(@player, @uuid, @item, @players_data, @skills_spec, @text) {
  @texture_layer = @text['space_fonts']['space.-8'].'\uec2c'.@text['space_fonts']['space.-169']
  @message = '사용할 아이템'.@text['space_fonts']['space.21'].'아이템을 사용할까요?'
  @inventory = array()
  for(@index = 0, @index < 9, @index++) {
    @inventory[@index] = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': ' ',
        'model': 1
      )
    )
  }
  @inventory[1] = @item
  @inventory[5]['meta']['display'] = '§a네'
  @inventory[7]['meta']['display'] = '§c아니요'
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @item, @players_data, @skills_spec, @text) {
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @item, @players_data, @skills_spec, @text) {
      cancel()
      # 슬롯
      if(@event['action'] == 'PICKUP_ALL') {
        @slot = @event['rawslot']
        switch(@slot) { // 네 클릭시
        case 5:
          ptake_item(@player, @item)
          _reset_skills(@players_data, @player, @uuid, @skills_spec)
          close_pinv(@player)
          tmsg(@player, @text['prefix']['info'] '§7스킬 포인트가 초기화 되었습니다.')
          play_named_sound(ploc(@player), array(
            'sound': 'minecraft:entity.illusioner.cast_spell',
            'category': 'PLAYERS',
            'volume': 1,
            'pitch': 0.675
          ), @player)
          break()
        case 7: // 아니요 클릭시
          close_pinv(@player)
          break()
        }
      }
    }
  }
  # GUI 보여주기
  _show_gui(@player, 'asking_skill_reset', 9, @texture_layer, @message, @inventory, @closure, @uuid, @item, @players_data, @skills_spec, @text)
}

proc _reset_skills(@players_data, @player, @uuid, @skills_spec) {
  @player_data = @players_data[@uuid]
  ## 스킬 매니저 초기화
  @skill_manager = @player_data['skill_manager']
  @selected_methods = json_decode(@skill_manager[4])
  # 액티브 스킬에서 선택한 스킬 방식 초기화
  @selected_combat_method = @selected_methods['combat_method']
  _reset_active_skill(@player_data, @uuid, @selected_combat_method)
  @selected_sowing_method = @selected_methods['sowing_method']
  _reset_active_skill(@player_data, @uuid, @selected_sowing_method)
  @selected_harvesting_method = @selected_methods['harvesting_method']
  _reset_active_skill(@player_data, @uuid, @selected_harvesting_method)
  # 스킬 메니져에서 선택한 스킬 방식 초기화
  @skill_manager[4] = json_encode(
    array(
      'combat_method': '',
      'harvesting_method': '',
      'sowing_method': ''
    )
  )
  # @player_data에서 skill_manager 설정
  @player_data['skill_manager'] = @skill_manager
  # cup에 저장
  _set_skill_manager(@uuid, @skill_manager)

  ## invested_point 설정
  @player_data['invested_point'] = 0

  ## 스킬 데이터 초기화
  foreach(@skill: @skill_spec in @skills_spec) {
    # 카테고리 선언
    @category = @skill_spec['category']
    # 스킬 데이터 로드
    @skill_data = _get_skill_data(@uuid, @skill, @skill_spec)
    # 룬 제외한 모든 스킬 @skill_data 초기화
    if(@category != 'rune') {
      @skill_data[0] = 0
      # @player_data에서 skill_data 설정
      @player_data['skill_data'][@skill] = @skill_data
      # cup에 저장
      _set_skill_data(@uuid, @skill, @skill_data)
    }
  }
}

## 비법서 사용 ()
proc _add_max_skill_point(@player_data, @player, @uuid, @skill, @power, @skill_spec) {
  # 스킬 데이터 로드
  @skill_data = _get_skill_data(@uuid, @skill, @skill_spec)

  #
  # 맥스 포인트보다 power가 클 경우 + 1 아닐경우 바닐라 경험치 쓸지 물어보기
  # 작을 경우 2^power * 100 의 바닐라 경험치로 돌려주기
  #

  # 맥스 포인트 +1
  @skill_data[1] += 1
  # @player_data에서 skill_data 설정
  @player_data['skill_data'][@skill] = @skill_data
  # cup에 저장
  _set_skill_data(@uuid, @skill, @skill_data)
}


## 룬 gui
proc _open_rune(@player, @uuid, @players_data, @skills_info, @skills_spec, @page, @text) {
  @player_data = @players_data[@uuid]
  @skill_manager = @player_data['skill_manager']
  @skills_data = @player_data['skill_data']
  # 인벤토리 프리셋
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
  # 소유중인 룬
  @runes = array()
  foreach(@skill: @skill_spec in @skills_spec) {
    @category = @skill_spec['category']
    if(@category == 'rune') {
      @skill_data = @player_data['skill_data'][@skill]
      if(@skill_data[0] > -1) { // > 0 으로 수정해야 함
        @runes[] = @skill
        #broadcast(@skill @skill_data 소지)
      }
    }
  }
  # 룬 슬롯 갯수 구하기
  @rune_slot = @skill_manager[3]
  @rune_slot = 3 // 테스트 제거해야함
  @rune_slots = array()
  array_resize(@rune_slots, @rune_slot, array(
    'name': 'STRUCTURE_VOID',
    'meta': array(
      'display': '§8비어 있음',
      'lore': array(
        '§7해당 슬롯에 장착한 룬이 없습니다.',
        '§7아래, 룬 백에서 룬을 좌 클릭하여 룬을 장착할 수 있습니다.'
      ),
      'model': 1
    )
  ))
  # 룬 슬롯 텍스트
  @filled_slot = @text['space_fonts']['space.-1'].'\ue540'
  @empty_slot = @text['space_fonts']['space.18']
  switch(@rune_slot) {
  case 1:
    @line_1 = @filled_slot.@filled_slot.@filled_slot.@filled_slot.@empty_slot.@filled_slot.@filled_slot.@filled_slot.@filled_slot
    break()
  case 2:
    @line_1 = @filled_slot.@filled_slot.@filled_slot.@empty_slot.@filled_slot.@empty_slot.@filled_slot.@filled_slot.@filled_slot
    break()
  case 3:
    @line_1 = @filled_slot.@filled_slot.@empty_slot.@filled_slot.@empty_slot.@filled_slot.@empty_slot.@filled_slot.@filled_slot
    break()
  case 4:
    @line_1 = @filled_slot.@empty_slot.@filled_slot.@empty_slot.@filled_slot.@empty_slot.@filled_slot.@empty_slot.@filled_slot
    break()
  case 5:
    @line_1 = @empty_slot.@filled_slot.@empty_slot.@filled_slot.@empty_slot.@filled_slot.@empty_slot.@filled_slot.@empty_slot
    break()
  default:
    @line_1 = @filled_slot.@filled_slot.@filled_slot.@filled_slot.@filled_slot.@filled_slot.@filled_slot.@filled_slot.@filled_slot
    break()
  }
  # 착용중인 룬
  @selected_runes = json_decode(@skill_manager[5])
  # 소유중인 룬 목록에서 에서 착용한 룬 제거, (착용중인 룬 효과 반영?)
  foreach(@key: @selected_rune in @selected_runes) {
    array_remove_values(@runes, @selected_rune)
    # 룬 레벨
    @rune_level = @skills_data[@selected_rune][0]
    # 룬 정보
    @rune_info = @skills_info[@selected_rune]
    # 룬 이름
    @rune_display = @rune_info['display']
    # 룬 설명
    @rune_descriptions = @rune_info['descriptions']
    @rune_descriptions_size = array_size(@rune_descriptions)
    if(@rune_descriptions_size > 0) {
      if(@rune_descriptions_size < @rune_level) {
        @description_index = @rune_descriptions_size - 1 // 마지막 레벨 설명
      } else {
        @description_index = @rune_level - 1 // 해당 레벨 설명
      }
      @rune_description = @rune_descriptions[@description_index]
    } else {
      @rune_description = array()
    }
    # 아이템 세팅
    @item = array(
      'name': 'ENCHANTED_BOOK',
      'meta': array(
        'display': "§8Lv.@rune_level @rune_display @selected_rune",
        'lore': array(
          '§7이 슬롯에는§c'@rune_display'§7룬이 장착되어 있습니다.',
          '§7좌 클릭 시 룬 장착을 해제합니다.',
          ''
        ),
        'model': @rune_info['icon']
      )
    )
    @item['meta']['lore'] = array_merge(@item['meta']['lore'], @rune_description)
    @item['rune'] = @selected_rune
    @rune_slots[@key] = @item
  }
  # 슬롯 세팅
  foreach(@key: @rune_slot in @rune_slots) {
    @slot = 5 - array_size(@rune_slots) + @key * 2
    @inventory[@slot] = @rune_slot
  }
  # 소유중인 룬
  @rune_pages = _paging(@runes, 7)
  # 현 페이지 기준으로 4줄 구하기
  @filled_slots = array(@text['space_fonts']['space.-1'].'\ue600', @text['space_fonts']['space.-1'].'\ue660' , @text['space_fonts']['space.-1'].'\ue6c0', @text['space_fonts']['space.-1'].'\ue720')
  @lines = array()
  for(@i = 0, @i < 4, @i++) {
    if(array_index_exists(@rune_pages, @page + @i)) {
      @rune_page_size = array_size(@rune_pages[@page + @i])
      @lines[] = string_multiply(@empty_slot, @rune_page_size).string_multiply(@filled_slots[@i], 7 - @rune_page_size)
      # 룬 불러온 후아이템 세팅
      foreach(@key: @rune in @rune_pages[@page + @i]) {
        # 룬 레벨
        @rune_level = @skills_data[@rune][0]
        # 룬 정보
        @rune_info = @skills_info[@rune]
        # 룬 이름
        @rune_display = @rune_info['display']
        # 룬 설명
        @rune_descriptions = @rune_info['descriptions']
        @rune_descriptions_size = array_size(@rune_descriptions)
        if(@rune_descriptions_size > 0) {
          if(@rune_descriptions_size < @rune_level) {
            @description_index = @rune_descriptions_size - 1 // 마지막 레벨 설명
          } else {
            @description_index = @rune_level - 1 // 해당 레벨 설명
          }
          @rune_description = @rune_descriptions[@description_index]
        } else {
          @rune_description = array()
        }
        # 아이템 세팅
        @item = array(
          'name': 'ENCHANTED_BOOK',
          'meta': array(
            'display': "§8Lv.@rune_level @rune_display @rune",
            'lore': array(),
            'model': @rune_info['icon']
          )
        )
        @item['meta']['lore'] = array_merge(@item['meta']['lore'], @rune_description)
        @item['rune'] = @rune
        # 슬롯 세팅
        @slot = (@i + 2) * 9 + @key + 1
        @inventory[@slot] = @item
      }
    } else {
      @lines[] = string_multiply(@filled_slots[@i], 7)
    }
  }
  # 위 화살표
  if(@page > 0) {
    @up_arrow = @text['space_fonts']['space.18']
    @inventory[26]['meta']['display'] = '§7위로'
  } else {
    @up_arrow = @text['space_fonts']['space.-1'].'\ue600'
  }
  # 아래 화살표
  if(array_size(@rune_pages) - @page > 4) {
    @down_arrow = @text['space_fonts']['space.18']
    @inventory[53]['meta']['display'] = '§7아래로'
  } else {
    @down_arrow = @text['space_fonts']['space.-1'].'\ue720'
  }
  # GUI 타이틀 세팅
  @texture_layer = @text['space_fonts']['space.-8'].'\uec2b'.@text['space_fonts']['space.-169'].@line_1.@text['space_fonts']['space.-18'].@up_arrow.@text['space_fonts']['space.-18'].@down_arrow.@text['space_fonts']['space.-144'].@lines[0].@text['space_fonts']['space.-126'].@lines[1].@text['space_fonts']['space.-126'].@lines[2].@text['space_fonts']['space.-126'].@lines[3].@text['space_fonts']['space.-144']
  @message = '룬 백'
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @players_data, @skills_info, @skills_spec, @page, @text) {
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @inventory, @player, @uuid, @id, @players_data, @skills_info, @skills_spec,@page,  @text) {
      cancel()
      # 데이터 선언
      @player_data = @players_data[@uuid]
      @skill_manager = @player_data['skill_manager']
      @skills_data = @player_data['skill_data']
      # 룬 슬롯 갯수
      @rune_slot = @skill_manager[3]
      @rune_slot = 3 // 테스트 제거해야함
      # 착용중인 룬
      @selected_runes = json_decode(@skill_manager[5])
      # 클릭
      @slot = @event['rawslot']
      if(@event['action'] == 'PICKUP_ALL' && @slot < 54) {
        @item = @inventory[@slot]
        if(@item['meta']['display'] != ' ') {
          switch(@slot) {
          case 0..8:
              if(@item['meta']['model'] != 1) {
                array_remove_values(@selected_runes, @item['rune'])
                @skill_manager[5] = json_encode(@selected_runes)
                _set_skill_manager(@uuid, @skill_manager)
                _open_rune(@player, @uuid, @players_data, @skills_info, @skills_spec, @page, @text)
              }
            break()
          case 19..25:
          case 28..34:
          case 37..43:
          case 46..52:
            if(array_size(@selected_runes) < @rune_slot) {
              @selected_runes[] = @item['rune']
              @skill_manager[5] = json_encode(@selected_runes)
              _set_skill_manager(@uuid, @skill_manager)
              _open_rune(@player, @uuid, @players_data, @skills_info, @skills_spec, @page, @text)
            }
            break()
          case 26:
            @page -= 1
            _open_rune(@player, @uuid, @players_data, @skills_info, @skills_spec, @page, @text)
            break()
          case 53:
            @page += 1
            _open_rune(@player, @uuid, @players_data, @skills_info, @skills_spec, @page, @text)
            break()
          }
        }
      }
    }
  }
  # GUI 보여주기
  _show_gui(@player, 'runebag', 54, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_info, @skills_spec, @page, @text)
}

## 스킬 gui
# 전투
proc _open_combat_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  @skill_manager = @player_data['skill_manager']
  @skills_data = @player_data['skill_data']
  # 레벨
  @level = @skill_manager[0]
  # 경험치
  @experience = @skill_manager[1]
  # 포인트
  @total_point = _get_total_skill_point(@skill_manager)
  @remaining_point = @total_point - @player_data['invested_point']
  # 선택한 전투 방식
  @selected_methods = json_decode(@skill_manager[4])
  @selected_combat_method = @selected_methods['combat_method']
  # GUI 기본 데이터 선언
  @texture_layer = @text['space_fonts']['space.-8'].'\uec1d'.@text['space_fonts']['space.-169'].@text['space_fonts']['space.-1'].'\ue720'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue991'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue75b'.@text['space_fonts']['space.126'].@text['space_fonts']['space.-1'].'\ue720'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue992'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue75c'.@text['space_fonts']['space.-162']
  @message = "전투 방식 · 보조 전투( 남은 포인트: @remaining_point / @total_point )"
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
      'icon': 10,
      'button': 19
    ),
    'knockback': array(
      'icon': 12,
      'button': 21
    ),
    'cleaving': array(
      'icon': 14,
      'button': 23
    ),
    'blocking': array(
      'icon': 16,
      'button': 25
    ),
    'bow_mastery': array(
      'icon': 28,
      'button': 37
    ),
    'crossbow_mastery': array(
      'icon': 30,
      'button': 39
    ),
    'health_traing': array(
      'icon': 32,
      'button': 41
    )
  )
  foreach(@skill: @slots in @skill_setup) {
    @skill_point = @skills_data[@skill][0]
    @skill_max_point = @skills_data[@skill][1]
    @skill_info = @skills_info[@skill]
    @skill_spec = @skills_spec[@skill]
    @category = @skill_spec['category']
    @skill_display = @skill_info['display']
    if(@skill_point == 0) {
      @skill_point_text = "§8Lv.@skill_point @skill_display §8(최대: @skill_max_point)"
      @skill_icon = @skill_info['icon']['off']
      if(@category == 'combat_method') {
        @lore = array(
          '§7포인트를 사용하여 스킬 레벨을 올릴 시',
          '§7스킬 아이콘 좌 클릭하면 전투 방식이 선택되며',
          '§7스킬 효과를 받을 수 있습니다.',
          ''
        )
      } else {
        @lore = array(
          '§7포인트를 사용하여 스킬 레벨을 올릴 시',
          '§7스킬 효과를 받을 수 있습니다.',
          ''
        )
      }

    } else {
      if(@category == 'combat_method') {
        if(@skill == @selected_combat_method) {
          @skill_point_text = "§bLv.@skill_point @skill_display §8(최대: @skill_max_point)"
          @skill_icon = @skill_info['icon']['on']
          @lore = array(
            '§7현재 해당 전투 방식 사용중입니다.',
            '§7좌 클릭 시 해당 전투 방식 사용을 해제합니다.',
            ''
          )
        } else {
          @skill_point_text = "§8Lv.@skill_point @skill_display §8(최대: @skill_max_point)"
          @skill_icon = @skill_info['icon']['off']
          if(@selected_combat_method == '') {
            @lore = array(
              '§7현재 사용중인 전투 방식이 없습니다.',
              '§7좌 클릭 시 §c'.@skill_display.' §7전투 방식을 사용합니다.',
              ''
            )
          } else {
            @lore = array(
              '§7현재 §c'.@skills_info[@selected_combat_method]['display'].'§7 전투 방식 사용중입니다.',
              '§7좌 클릭 시 §c'.@skill_display.' §7전투 방식을 사용합니다.',
              ''
            )
          }
        }
      } else {
        @skill_point_text = "§bLv.@skill_point @skill_display §8(최대: @skill_max_point)"
        @skill_icon = @skill_info['icon']['on']
        @lore = array()
      }
    }
    @skill_descriptions = @skill_info['descriptions']
    if(array_size(@skill_descriptions) > 0) {
      if(array_size(@skill_descriptions) != 0) {
        if(array_size(@skill_descriptions) - 1 < @skill_point) {
          @description_index = array_size(@skill_descriptions) - 1
        } else {
          @description_index = @skill_point
        }
        @skill_description = @skill_descriptions[@description_index]
        if(array_size(@skill_descriptions) - 1 < @skill_point + 1) {
          @button_description_index = array_size(@skill_descriptions) - 1
        } else {
          @button_description_index = @skill_point + 1
        }
        @button_description = @skill_descriptions[@button_description_index]
      } else {
        @skill_description = array()
        @button_description = array()
      }
    } else {
      @skill_description = array()
      if(array_size(@skill_descriptions) != 0) {
        if(array_size(@skill_descriptions) - 1 < @skill_point + 1) {
          @button_description_index = array_size(@skill_descriptions) - 1
        } else {
          @button_description_index = @skill_point + 1
        }
        @button_description = @skill_descriptions[@button_description_index]
      } else {
        @button_description = array()
      }
    }
    @inventory[@slots['icon']]['skill'] = @skill
    @inventory[@slots['icon']]['slot_type'] = @category
    @inventory[@slots['icon']]['meta']['display'] = @skill_point_text
    @inventory[@slots['icon']]['meta']['lore'] = array_merge(@lore, @skill_description)
    @inventory[@slots['icon']]['meta']['model'] = @skill_icon

    if(@remaining_point > 0 && @skills_data[@skill][0] < @skills_data[@skill][1]) {
      @inventory[@slots['button']]['skill'] = @skill
      @inventory[@slots['button']]['slot_type'] = 'button'
      @inventory[@slots['button']]['meta']['display'] = '§7좌 클릭 시 포인트 사용'
      @inventory[@slots['button']]['meta']['model'] = 6
      @inventory[@slots['button']]['meta']['lore'] = array_merge(
        array(
          '§bLv.'.string(@skill_point + 1) @skill_display.' 정보:',
          ''
        ),
        @button_description
      )
    }
  }
  @inventory[45]['meta']['display'] = '§f파종 · 수확 방식'
  @inventory[53]['meta']['display'] = '§f채광'
  # GUI 이벤트 익스큐터 설정
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @players_data, @skills_info, @skills_spec, @text) {
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @inventory, @player, @uuid, @id, @players_data, @skills_info, @skills_spec, @text) {
      cancel()
      
      # 데이터 선언
      @player_data = @players_data[@uuid]
      
      if(@player_data['cache']['gui_click_time'] < time()) {

        # 스킬 데이터 선언
        @skill_manager = @player_data['skill_manager']
        @skills_data = @player_data['skill_data']
        # 포인트
        @total_point = _get_total_skill_point(@skill_manager)
        @remaining_point = @total_point - @player_data['invested_point']
        # 선택한 전투 방식
        @selected_methods = json_decode(@skill_manager[4])
        # 슬롯
        @slot = @event['rawslot']
        if(@event['action'] == 'PICKUP_ALL' && @slot < 54) {
          switch(@slot) {
          case 45:
            runas(@player, '/skill farmingmethod')
            @player_data['cache']['gui_click_time'] = time() + 100
            play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            break()
          case 53:
            runas(@player, '/skill mining')
            @player_data['cache']['gui_click_time'] = time() + 100
            play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            break()
          default:
            if(@slot > 0 && array_index_exists(@inventory[@slot], 'slot_type')) {
              switch(@inventory[@slot]['slot_type']) {
              case 'combat_method':
                @new_skill = @inventory[@slot]['skill']
                if(@skills_data[@new_skill][0] > 0) {
                  play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                  @category = 'combat_method'
                  @selected_combat_method = @selected_methods['combat_method']
                  @new_skill_proc_name = "_apply_loading_by_@new_skill"
                  @new_skill_spec = @skills_spec[@new_skill]
                  @new_skill_point = @skills_data[@new_skill][0]
                  if(@selected_combat_method == @new_skill) { // 스킬 사용 해제시
                    @player_data['cache']['gui_click_time'] = time() + 100
                    @selected_combat_method = ''
                    @selected_methods['combat_method'] = @selected_combat_method
                    @skill_manager[4] = json_encode(@selected_methods)
                    if(is_proc(@new_skill_proc_name)) {
                      call_proc(@new_skill_proc_name, @player_data, @player, @uuid, @category, @new_skill, @new_skill_spec, @new_skill_point, @selected_combat_method)
                    }
                  } else { // 스킬 선택시
                    @player_data['cache']['gui_click_time'] = time() + 100
                    @old_skill = @selected_combat_method
                    @selected_combat_method = @new_skill
                    @selected_methods['combat_method'] = @selected_combat_method
                    @skill_manager[4] = json_encode(@selected_methods)
                    if(@old_skill != '') { // 스킬 변경시
                      @old_skill_proc_name = "_apply_loading_by_@old_skill"
                      @old_skill_spec = @skills_spec[@old_skill]
                      @old_skill_point = @skills_data[@old_skill][0]
                      if(is_proc(@old_skill_proc_name)) {
                        call_proc(@old_skill_proc_name, @player_data, @player, @uuid, @category, @old_skill, @old_skill_spec, @old_skill_point, @selected_combat_method)
                      }
                    }
                    if(is_proc(@new_skill_proc_name)) {
                      call_proc(@new_skill_proc_name, @player_data, @player, @uuid, @category, @new_skill, @new_skill_spec, @new_skill_point, @selected_combat_method)
                    }
                  }
                  _set_skill_manager(@uuid, @skill_manager)
                  runas(@player, '/skill')
                }
                break()
              case 'subcombat':
                break()
              case 'button':
                @total_point = _get_total_skill_point(@skill_manager)
                @remaining_point = @total_point - @player_data['invested_point']
                if(@remaining_point > 0) {
                  @player_data['cache']['gui_click_time'] = time() + 100
                  play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                  @skill = @inventory[@slot]['skill']
                  @selected_combat_method = @selected_methods['combat_method']
                  @skills_data[@skill][0] += 1
                  @player_data['invested_point'] += 1
                  _set_skill_data(@uuid, @skill, @skills_data[@skill])
                  _set_skill_manager(@uuid, @skill_manager)
                  if(@skill == @selected_combat_method) {
                    @category = 'combat_method'
                    @skill_spec = @skills_spec[@skill]
                    @point = @skills_data[@skill][0]
                    @proc_name = "_apply_loading_by_@skill"
                    if(is_proc(@proc_name)) { // 방식 사용중 포인트 사용시 쿨탐, 어트리뷰트 초기화 
                      call_proc(@proc_name, @player_data, @player, @uuid, @category, @skill, @skill_spec, 0, @selected_combat_method)
                      call_proc(@proc_name, @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @selected_combat_method)
                    }
                  }
                  runas(@player, '/skill')
                }
                break()
              }
            }
            break()
          }
        }

      }
    }
  }
  # GUI 보여주기
  _show_gui(@player, 'skillbook_combat', 54, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_info, @skills_spec, @text)
}
# 농사 방식
proc _open_farming_method_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  @skill_manager = @player_data['skill_manager']
  @skills_data = @player_data['skill_data']
  # 레벨
  @level = @skill_manager[0]
  # 경험치
  @experience = @skill_manager[1]
  # 포인트
  @total_point = _get_total_skill_point(@skill_manager)
  @remaining_point = @total_point - @player_data['invested_point']
  # 선택한 농사 방식
  @selected_methods = json_decode(@skill_manager[4])
  @selected_sowing_method = @selected_methods['sowing_method']
  @selected_harvesting_method = @selected_methods['harvesting_method']
  # GUI 기본 데이터 선언
  @texture_layer = @text['space_fonts']['space.-8'].'\uec1d'.@text['space_fonts']['space.-169'].@text['space_fonts']['space.-1'].'\ue720'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue991'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue75b'.@text['space_fonts']['space.126'].@text['space_fonts']['space.-1'].'\ue720'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue992'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue75c'.@text['space_fonts']['space.-162']
  @message = "파종 · 수확 방식 ( 남은 포인트: @remaining_point / @total_point )"
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
    'wet_hands': array(
      'icon': 11,
      'button': 20
    ),
    'fertile_touch': array(
      'icon': 15,
      'button': 24
    ),
    'wide_hands': array(
      'icon': 29,
      'button': 38
    ),
    'golden_finger': array(
      'icon': 33,
      'button': 42
    )
  )
  foreach(@skill: @slots in @skill_setup) {
    @skill_point = @skills_data[@skill][0]
    @skill_max_point = @skills_data[@skill][1]
    @skill_info = @skills_info[@skill]
    @skill_spec = @skills_spec[@skill]
    @category = @skill_spec['category']
    @skill_display = @skill_info['display']
    if(@skill_point == 0) {
      @skill_point_text = "§8Lv.@skill_point @skill_display §8(최대: @skill_max_point)"
      @skill_icon = @skill_info['icon']['off']
      if(@category == 'sowing_method') {
        @lore = array(
          '§7포인트를 사용하여 스킬 레벨을 올릴 시',
          '§7스킬 아이콘 좌 클릭하면 파종 방식이 선택되며',
          '§7스킬 사용 시 효과를 받을 수 있습니다.',
          ''
        )
      } else if(@category == 'harvesting_method') {
        @lore = array(
          '§7포인트를 사용하여 스킬 레벨을 올릴 시',
          '§7스킬 아이콘 좌 클릭하면 수확 방식이 선택되며',
          '§7스킬 사용 시 효과를 받을 수 있습니다.',
          ''
        )
      }
    } else {
      if(@category == 'sowing_method') {
        if(@skill == @selected_sowing_method) {
          @skill_point_text = "§bLv.@skill_point @skill_display §8(최대: @skill_max_point)"
          @skill_icon = @skill_info['icon']['on']
          @lore = array(
            '§7현재 해당 파종 방식 사용중입니다.',
            '§7좌 클릭 시 해당 파종 방식 사용을 해제합니다.',
            ''
          )
        } else {
          @skill_point_text = "§8Lv.@skill_point @skill_display §8(최대: @skill_max_point)"
          @skill_icon = @skill_info['icon']['off']
          if(@selected_sowing_method == '') {
            @lore = array(
              '§7현재 사용중인 파종 방식이 없습니다.',
              '§7좌 클릭 시 §c'.@skill_display.' §7파종 방식을 사용합니다.',
              ''
            )
          } else {
            @lore = array(
              '§7현재 §c'.@skills_info[@selected_sowing_method]['display'].'§7 파종 방식 사용중입니다.',
              '§7좌 클릭 시 §c'.@skill_display.' §7파종 방식을 사용합니다.',
              ''
            )
          }
        }
      } else if(@category == 'harvesting_method') {
        if(@skill == @selected_harvesting_method) {
          @skill_point_text = "§bLv.@skill_point @skill_display §8(최대: @skill_max_point)"
          @skill_icon = @skill_info['icon']['on']
          @lore = array(
            '§7현재 해당 수확 방식 사용중입니다.',
            '§7좌 클릭 시 해당 수확 방식 사용을 해제합니다.',
            ''
          )
        } else {
          @skill_point_text = "§8Lv.@skill_point @skill_display §8(최대: @skill_max_point)"
          @skill_icon = @skill_info['icon']['off']
          if(@selected_harvesting_method == '') {
            @lore = array(
              '§7현재 사용중인 수확 방식이 없습니다.',
              '§7좌 클릭 시 §c'.@skill_display.' §7수확 방식을 사용합니다.',
              ''
            )
          } else {
            @lore = array(
              '§7현재 §c'.@skills_info[@selected_harvesting_method]['display'].'§7 수확 방식 사용중입니다.',
              '§7좌 클릭 시 §c'.@skill_display.' §7수확 방식을 사용합니다.',
              ''
            )
          }
        }
      }
    }
    @skill_descriptions = @skill_info['descriptions']
    if(array_size(@skill_descriptions) > 0) {
      if(array_size(@skill_descriptions) != 0) {
        if(array_size(@skill_descriptions) - 1 < @skill_point) {
          @description_index = array_size(@skill_descriptions) - 1
        } else {
          @description_index = @skill_point
        }
        @skill_description = @skill_descriptions[@description_index]
        if(array_size(@skill_descriptions) - 1 < @skill_point + 1) {
          @button_description_index = array_size(@skill_descriptions) - 1
        } else {
          @button_description_index = @skill_point + 1
        }
        @button_description = @skill_descriptions[@button_description_index]
      } else {
        @skill_description = array()
        @button_description = array()
      }
    } else {
      @skill_description = array()
      if(array_size(@skill_descriptions) != 0) {
        if(array_size(@skill_descriptions) - 1 < @skill_point + 1) {
          @button_description_index = array_size(@skill_descriptions) - 1
        } else {
          @button_description_index = @skill_point + 1
        }
        @button_description = @skill_descriptions[@button_description_index]
      } else {
        @button_description = array()
      }
    }
    @inventory[@slots['icon']]['skill'] = @skill
    @inventory[@slots['icon']]['slot_type'] = @category
    @inventory[@slots['icon']]['meta']['display'] = @skill_point_text
    @inventory[@slots['icon']]['meta']['lore'] = array_merge(@lore, @skill_description)
    @inventory[@slots['icon']]['meta']['model'] = @skill_icon

    if(@remaining_point > 0 && @skills_data[@skill][0] < @skills_data[@skill][1]) {
      @inventory[@slots['button']]['skill'] = @skill
      @inventory[@slots['button']]['slot_type'] = 'button'
      @inventory[@slots['button']]['meta']['display'] = '§7좌 클릭 시 포인트 사용'
      @inventory[@slots['button']]['meta']['model'] = 6
      @inventory[@slots['button']]['meta']['lore'] = array_merge(
        array(
          '§bLv.'.string(@skill_point + 1) @skill_display.' 정보:',
          ''
        ),
        @button_description
      )
    }
  }
  @inventory[45]['meta']['display'] = '§f농사'
  @inventory[53]['meta']['display'] = '§f전투 방식 · 보조 전투'
  # GUI 이벤트 익스큐터 설정
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @players_data, @skills_info, @skills_spec, @text) {
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @inventory, @player, @uuid, @id, @players_data, @skills_info, @skills_spec, @text) {
      cancel()
      # 데이터 선언
      @player_data = @players_data[@uuid]
      
      if(@player_data['cache']['gui_click_time'] < time()) {
      
        @skill_manager = @player_data['skill_manager']
        @skills_data = @player_data['skill_data']
        # 포인트
        @total_point = _get_total_skill_point(@skill_manager)
        @remaining_point = @total_point - @player_data['invested_point']
        # 선택한 전투 방식
        @selected_methods = json_decode(@skill_manager[4])
        # 슬롯
        @slot = @event['rawslot']
        if(@event['action'] == 'PICKUP_ALL' && @slot < 54) {
          switch(@slot) {
          case 45:
            runas(@player, '/skill farming')
            play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            @player_data['cache']['gui_click_time'] = time() + 100
            break()
          case 53:
            runas(@player, '/skill combat')
            play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            @player_data['cache']['gui_click_time'] = time() + 100
            break()
          default:
            if(@slot > 0 && array_index_exists(@inventory[@slot], 'slot_type')) {
              switch(@inventory[@slot]['slot_type']) {
              case 'sowing_method':
                @new_skill = @inventory[@slot]['skill']
                if(@skills_data[@new_skill][0] > 0) {
                  play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                  @category = 'sowing_method'
                  @selected_sowing_method = @selected_methods['sowing_method']
                  @new_skill_proc_name = "_apply_loading_by_@new_skill"
                  @new_skill_spec = @skills_spec[@new_skill]
                  @new_skill_point = @skills_data[@new_skill][0]
                  if(@selected_sowing_method == @new_skill) { // 스킬 사용 해제시
                    @player_data['cache']['gui_click_time'] = time() + 100
                    @selected_sowing_method = ''
                    @selected_methods['sowing_method'] = @selected_sowing_method
                    @skill_manager[4] = json_encode(@selected_methods)
                    if(is_proc(@new_skill_proc_name)) {
                      call_proc(@new_skill_proc_name, @player_data, @player, @uuid, @category, @new_skill, @new_skill_spec, @new_skill_point, @selected_sowing_method)
                    }
                  } else { // 스킬 선택시
                    @player_data['cache']['gui_click_time'] = time() + 100
                    @old_skill = @selected_sowing_method
                    @selected_sowing_method = @new_skill
                    @selected_methods['sowing_method'] = @selected_sowing_method
                    @skill_manager[4] = json_encode(@selected_methods)
                    if(@old_skill != '') { // 스킬 변경시
                      @old_skill_proc_name = "_apply_loading_by_@old_skill"
                      @old_skill_spec = @skills_spec[@old_skill]
                      @old_skill_point = @skills_data[@old_skill][0]
                      if(is_proc(@old_skill_proc_name)) {
                        call_proc(@old_skill_proc_name, @player_data, @player, @uuid, @category, @old_skill, @old_skill_spec, @old_skill_point, @selected_sowing_method)
                      }
                    }
                    if(is_proc(@new_skill_proc_name)) {
                      call_proc(@new_skill_proc_name, @player_data, @player, @uuid, @category, @new_skill, @new_skill_spec, @new_skill_point, @selected_sowing_method)
                    }
                  }
                  _set_skill_manager(@uuid, @skill_manager)
                  runas(@player, '/skill farmingmethod')
                }
                break()
              case 'harvesting_method':
                @new_skill = @inventory[@slot]['skill']
                if(@skills_data[@new_skill][0] > 0) {
                  play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                  @category = 'harvesting_method'
                  @selected_harvesting_method = @selected_methods['harvesting_method']
                  @new_skill_proc_name = "_apply_loading_by_@new_skill"
                  @new_skill_spec = @skills_spec[@new_skill]
                  @new_skill_point = @skills_data[@new_skill][0]
                  if(@selected_harvesting_method == @new_skill) { // 스킬 사용 해제시
                    @player_data['cache']['gui_click_time'] = time() + 100
                    @selected_harvesting_method = ''
                    @selected_methods['harvesting_method'] = @selected_harvesting_method
                    @skill_manager[4] = json_encode(@selected_methods)
                    if(is_proc(@new_skill_proc_name)) {
                      call_proc(@new_skill_proc_name, @player_data, @player, @uuid, @category, @new_skill, @new_skill_spec, @new_skill_point, @selected_harvesting_method)
                    }
                  } else { // 스킬 선택시
                    @player_data['cache']['gui_click_time'] = time() + 100
                    @old_skill = @selected_harvesting_method
                    @selected_harvesting_method = @new_skill
                    @selected_methods['harvesting_method'] = @selected_harvesting_method
                    @skill_manager[4] = json_encode(@selected_methods)
                    if(@old_skill != '') { // 스킬 변경시
                      @old_skill_proc_name = "_apply_loading_by_@old_skill"
                      @old_skill_spec = @skills_spec[@old_skill]
                      @old_skill_point = @skills_data[@old_skill][0]
                      if(is_proc(@old_skill_proc_name)) {
                        call_proc(@old_skill_proc_name, @player_data, @player, @uuid, @category, @old_skill, @old_skill_spec, @old_skill_point, @selected_harvesting_method)
                      }
                    }
                    if(is_proc(@new_skill_proc_name)) {
                      call_proc(@new_skill_proc_name, @player_data, @player, @uuid, @category, @new_skill, @new_skill_spec, @new_skill_point, @selected_harvesting_method)
                    }
                  }
                  _set_skill_manager(@uuid, @skill_manager)
                  runas(@player, '/skill farmingmethod')
                }
                break()
              case 'button':
                @total_point = _get_total_skill_point(@skill_manager)
                @remaining_point = @total_point - @player_data['invested_point']
                if(@remaining_point > 0) {
                  @player_data['cache']['gui_click_time'] = time() + 100
                  play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                  @skill = @inventory[@slot]['skill']
                  @selected_sowing_method = @selected_methods['sowing_method']
                  @selected_harvesting_method = @selected_methods['harvesting_method']
                  @skills_data[@skill][0] += 1
                  @player_data['invested_point'] += 1
                  _set_skill_data(@uuid, @skill, @skills_data[@skill])
                  _set_skill_manager(@uuid, @skill_manager)
                  if(@skill == @selected_sowing_method) {
                    @category = 'sowing_method'
                    @skill_spec = @skills_spec[@skill]
                    @point = @skills_data[@skill][0]
                    @proc_name = "_apply_loading_by_@skill"
                    if(is_proc(@proc_name)) { // 방식 사용중 포인트 사용시 쿨탐, 어트리뷰트 초기화 
                      call_proc(@proc_name, @player_data, @player, @uuid, @category, @skill, @skill_spec, 0, @selected_sowing_method)
                      call_proc(@proc_name, @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @selected_sowing_method)
                    }
                  } else if(@skill == @selected_harvesting_method) {
                    @category = 'harvesting_method'
                    @skill_spec = @skills_spec[@skill]
                    @point = @skills_data[@skill][0]
                    @proc_name = "_apply_loading_by_@skill"
                    if(is_proc(@proc_name)) { // 방식 사용중 포인트 사용시 쿨탐, 어트리뷰트 초기화 
                      call_proc(@proc_name, @player_data, @player, @uuid, @category, @skill, @skill_spec, 0, @selected_harvesting_method)
                      call_proc(@proc_name, @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @selected_harvesting_method)
                    }
                  }
                  runas(@player, '/skill farmingmethod')
                }
                break()
              }
            }
            break()
          }
        }
        
      }
    }
  }
  # GUI 보여주기
  _show_gui(@player, 'skillbook_farming_method', 54, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_info, @skills_spec, @text)
}
# 농사
proc _open_farming_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  @skill_manager = @player_data['skill_manager']
  @skills_data = @player_data['skill_data']
  # 레벨
  @level = @skill_manager[0]
  # 경험치
  @experience = @skill_manager[1]
  # 포인트
  @total_point = _get_total_skill_point(@skill_manager)
  @remaining_point = @total_point - @player_data['invested_point']
  # GUI 기본 데이터 선언
  @texture_layer = @text['space_fonts']['space.-8'].'\uec1d'.@text['space_fonts']['space.-169'].@text['space_fonts']['space.-1'].'\ue720'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue991'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue75b'.@text['space_fonts']['space.126'].@text['space_fonts']['space.-1'].'\ue720'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue992'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue75c'.@text['space_fonts']['space.-162']
  @message = "농사 ( 남은 포인트: @remaining_point / @total_point )"
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
    'plenty': array(
      'icon': 10,
      'button': 19
    ),
    'wheat_farming_mastery': array(
      'icon': 12,
      'button': 21
    ),
    'carrot_farming_mastery': array(
      'icon': 14,
      'button': 23
    ),
    'potato_farming_mastery': array(
      'icon': 16,
      'button': 25
    ),
    'beetroot_farming_mastery': array(
      'icon': 28,
      'button': 37
    ),
    'berries_farming_mastery': array(
      'icon': 30,
      'button': 39
    ),
    'pumpkin_farming_mastery': array(
      'icon': 32,
      'button': 41
    ),
    'melon_farming_mastery': array(
      'icon': 34,
      'button': 43
    )
  )
  foreach(@skill: @slots in @skill_setup) {
    @skill_point = @skills_data[@skill][0]
    @skill_max_point = @skills_data[@skill][1]
    @skill_info = @skills_info[@skill]
    @skill_spec = @skills_spec[@skill]
    @category = @skill_spec['category']
    @skill_display = @skill_info['display']
    if(@skill_point == 0) {
      @skill_point_text = "§8Lv.@skill_point @skill_display §8(최대: @skill_max_point)"
      @skill_icon = @skill_info['icon']['off']
      @lore = array(
        '§7포인트를 사용하여 스킬 레벨을 올릴 시',
        '§7스킬 효과를 받을 수 있습니다.',
        ''
      )
    } else {
        @skill_point_text = "§bLv.@skill_point @skill_display §8(최대: @skill_max_point)"
        @skill_icon = @skill_info['icon']['on']
        @lore = array()
    }
    @skill_descriptions = @skill_info['descriptions']
    if(array_size(@skill_descriptions) > 0) {
      if(array_size(@skill_descriptions) != 0) {
        if(array_size(@skill_descriptions) - 1 < @skill_point) {
          @description_index = array_size(@skill_descriptions) - 1
        } else {
          @description_index = @skill_point
        }
        @skill_description = @skill_descriptions[@description_index]
        if(array_size(@skill_descriptions) - 1 < @skill_point + 1) {
          @button_description_index = array_size(@skill_descriptions) - 1
        } else {
          @button_description_index = @skill_point + 1
        }
        @button_description = @skill_descriptions[@button_description_index]
      } else {
        @skill_description = array()
        @button_description = array()
      }
    } else {
      @skill_description = array()
      if(array_size(@skill_descriptions) != 0) {
        if(array_size(@skill_descriptions) - 1 < @skill_point + 1) {
          @button_description_index = array_size(@skill_descriptions) - 1
        } else {
          @button_description_index = @skill_point + 1
        }
        @button_description = @skill_descriptions[@button_description_index]
      } else {
        @button_description = array()
      }
    }
    @inventory[@slots['icon']]['skill'] = @skill
    @inventory[@slots['icon']]['slot_type'] = @category
    @inventory[@slots['icon']]['meta']['display'] = @skill_point_text
    @inventory[@slots['icon']]['meta']['lore'] = array_merge(@lore, @skill_description)
    @inventory[@slots['icon']]['meta']['model'] = @skill_icon

    if(@remaining_point > 0 && @skills_data[@skill][0] < @skills_data[@skill][1]) {
      @inventory[@slots['button']]['skill'] = @skill
      @inventory[@slots['button']]['slot_type'] = 'button'
      @inventory[@slots['button']]['meta']['display'] = '§7좌 클릭 시 포인트 사용'
      @inventory[@slots['button']]['meta']['model'] = 6
      @inventory[@slots['button']]['meta']['lore'] = array_merge(
        array(
          '§bLv.'.string(@skill_point + 1) @skill_display.' 정보:',
          ''
        ),
        @button_description
      )
    }
  }
  @inventory[45]['meta']['display'] = '§f채광'
  @inventory[53]['meta']['display'] = '§f파종 · 수확 방식'
  # GUI 이벤트 익스큐터 설정
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @players_data, @skills_info, @skills_spec, @text) {
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @inventory, @player, @uuid, @id, @players_data, @skills_info, @skills_spec, @text) {
      cancel()
      # 데이터 선언
      @player_data = @players_data[@uuid]
      
      if(@player_data['cache']['gui_click_time'] < time()) {

        @skill_manager = @player_data['skill_manager']
        @skills_data = @player_data['skill_data']
        # 포인트
        @total_point = _get_total_skill_point(@skill_manager)
        @remaining_point = @total_point - @player_data['invested_point']
        # 슬롯
        @slot = @event['rawslot']
        if(@event['action'] == 'PICKUP_ALL' && @slot < 54) {
          switch(@slot) {
          case 45:
            runas(@player, '/skill mining')
            play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            @player_data['cache']['gui_click_time'] = time() + 100
            break()
          case 53:
            runas(@player, '/skill farmingmethod')
            play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            @player_data['cache']['gui_click_time'] = time() + 100
            break()
          default:
            if(@slot > 0 && array_index_exists(@inventory[@slot], 'slot_type')) {
              switch(@inventory[@slot]['slot_type']) {
              case 'farming':
                break()
              case 'button':
                @total_point = _get_total_skill_point(@skill_manager)
                @remaining_point = @total_point - @player_data['invested_point']
                if(@remaining_point > 0) {
                  @player_data['cache']['gui_click_time'] = time() + 100
                  play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                  @skill = @inventory[@slot]['skill']
                  @skills_data[@skill][0] += 1
                  @player_data['invested_point'] += 1
                  _set_skill_data(@uuid, @skill, @skills_data[@skill])
                  _set_skill_manager(@uuid, @skill_manager)
                  runas(@player, '/skill farming')
                }
                break()
              }
            }
            break()
          }
        }

      }
    }
  }
  # GUI 보여주기
  _show_gui(@player, 'skillbook_combat', 54, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_info, @skills_spec, @text)
}
# 채광
proc _open_mining_skill(@player, @uuid, @players_data, @skills_info, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  @skill_manager = @player_data['skill_manager']
  @skills_data = @player_data['skill_data']
  # 레벨
  @level = @skill_manager[0]
  # 경험치
  @experience = @skill_manager[1]
  # 포인트
  @total_point = _get_total_skill_point(@skill_manager)
  @remaining_point = @total_point - @player_data['invested_point']
  # GUI 기본 데이터 선언
  @texture_layer = @text['space_fonts']['space.-8'].'\uec1d'.@text['space_fonts']['space.-169'].@text['space_fonts']['space.-1'].'\ue720'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue991'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue75b'.@text['space_fonts']['space.126'].@text['space_fonts']['space.-1'].'\ue720'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue992'.@text['space_fonts']['space.-18'].@text['space_fonts']['space.-1'].'\ue75c'.@text['space_fonts']['space.-162']
  @message = "채광 ( 남은 포인트: @remaining_point / @total_point )"
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
    'over_ore_selecting': array(
      'icon': 10,
      'button': 19
    ),
    'nether_ore_selecting': array(
      'icon': 12,
      'button': 21
    ),
    'tough_shoulder': array(
      'icon': 14,
      'button': 23
    ),
    'copper_mining_mastery': array(
      'icon': 16,
      'button': 25
    ),
    'iron_mining_mastery': array(
      'icon': 28,
      'button': 37
    ),
    'gold_mining_mastery': array(
      'icon': 30,
      'button': 39
    ),
    'diamond_mining_mastery': array(
      'icon': 32,
      'button': 41
    ),
    'ancient_debris_mining_mastery': array(
      'icon': 34,
      'button': 43
    )
  )
  foreach(@skill: @slots in @skill_setup) {
    @skill_point = @skills_data[@skill][0]
    @skill_max_point = @skills_data[@skill][1]
    @skill_info = @skills_info[@skill]
    @skill_spec = @skills_spec[@skill]
    @category = @skill_spec['category']
    @skill_display = @skill_info['display']
    if(@skill_point == 0) {
      @skill_point_text = "§8Lv.@skill_point @skill_display §8(최대: @skill_max_point)"
      @skill_icon = @skill_info['icon']['off']
      @lore = array(
        '§7포인트를 사용하여 스킬 레벨을 올릴 시',
        '§7스킬 효과를 받을 수 있습니다.',
        ''
      )
    } else {
        @skill_point_text = "§bLv.@skill_point @skill_display §8(최대: @skill_max_point)"
        @skill_icon = @skill_info['icon']['on']
        @lore = array()
    }
    @skill_descriptions = @skill_info['descriptions']
    if(array_size(@skill_descriptions) > 0) {
      if(array_size(@skill_descriptions) != 0) {
        if(array_size(@skill_descriptions) - 1 < @skill_point) {
          @description_index = array_size(@skill_descriptions) - 1
        } else {
          @description_index = @skill_point
        }
        @skill_description = @skill_descriptions[@description_index]
        if(array_size(@skill_descriptions) - 1 < @skill_point + 1) {
          @button_description_index = array_size(@skill_descriptions) - 1
        } else {
          @button_description_index = @skill_point + 1
        }
        @button_description = @skill_descriptions[@button_description_index]
      } else {
        @skill_description = array()
        @button_description = array()
      }
    } else {
      @skill_description = array()
      if(array_size(@skill_descriptions) != 0) {
        if(array_size(@skill_descriptions) - 1 < @skill_point + 1) {
          @button_description_index = array_size(@skill_descriptions) - 1
        } else {
          @button_description_index = @skill_point + 1
        }
        @button_description = @skill_descriptions[@button_description_index]
      } else {
        @button_description = array()
      }
    }
    @inventory[@slots['icon']]['skill'] = @skill
    @inventory[@slots['icon']]['slot_type'] = @category
    @inventory[@slots['icon']]['meta']['display'] = @skill_point_text
    @inventory[@slots['icon']]['meta']['lore'] = array_merge(@lore, @skill_description)
    @inventory[@slots['icon']]['meta']['model'] = @skill_icon

    if(@remaining_point > 0 && @skills_data[@skill][0] < @skills_data[@skill][1]) {
      @inventory[@slots['button']]['skill'] = @skill
      @inventory[@slots['button']]['slot_type'] = 'button'
      @inventory[@slots['button']]['meta']['display'] = '§7좌 클릭 시 포인트 사용'
      @inventory[@slots['button']]['meta']['model'] = 6
      @inventory[@slots['button']]['meta']['lore'] = array_merge(
        array(
          '§bLv.'.string(@skill_point + 1) @skill_display.' 정보:',
          ''
        ),
        @button_description
      )
    }
  }
  @inventory[45]['meta']['display'] = '§f전투 방식 · 보조 전투'
  @inventory[53]['meta']['display'] = '§f농사'
  # GUI 이벤트 익스큐터 설정
  @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @players_data, @skills_info, @skills_spec, @text) {
    bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @inventory, @player, @uuid, @id, @players_data, @skills_info, @skills_spec, @text) {
      cancel()
      # 데이터 선언
      @player_data = @players_data[@uuid]
      
      if(@player_data['cache']['gui_click_time'] < time()) {

        @skill_manager = @player_data['skill_manager']
        @skills_data = @player_data['skill_data']
        # 포인트
        @total_point = _get_total_skill_point(@skill_manager)
        @remaining_point = @total_point - @player_data['invested_point']
        # 슬롯
        @slot = @event['rawslot']
        if(@event['action'] == 'PICKUP_ALL' && @slot < 54) {
          switch(@slot) {
          case 45:
            runas(@player, '/skill combat')
            play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            @player_data['cache']['gui_click_time'] = time() + 100
            break()
          case 53:
            runas(@player, '/skill farming')
            play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            @player_data['cache']['gui_click_time'] = time() + 100
            break()
          default:
            if(@slot > 0 && array_index_exists(@inventory[@slot], 'slot_type')) {
              switch(@inventory[@slot]['slot_type']) {
              case 'mining':
                break()
              case 'button':
                @total_point = _get_total_skill_point(@skill_manager)
                @remaining_point = @total_point - @player_data['invested_point']
                if(@remaining_point > 0) {
                  @player_data['cache']['gui_click_time'] = time() + 100
                  play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                  @skill = @inventory[@slot]['skill']
                  @skills_data[@skill][0] += 1
                  @player_data['invested_point'] += 1
                  _set_skill_data(@uuid, @skill, @skills_data[@skill])
                  _set_skill_manager(@uuid, @skill_manager)
                  runas(@player, '/skill mining')
                }
                break()
              }
            }
            break()
          }
        }

      }
    }
  }
  # GUI 보여주기
  _show_gui(@player, 'skillbook_combat', 54, @texture_layer, @message, @inventory, @closure, @uuid, @players_data, @skills_info, @skills_spec, @text)
}

# 공격 반영
proc _player_attack_event(@event, @player, @puuid, @euuid, @players_data, @skills_spec, @allowed_entity, @text, @server, @items, @weapons) {
  @allowed_entity = array(
    'MAGMA_CUBE': 0.75,
    'SILVERFISH': 0.3,
    'MULE': 1.6,
    'HOGLIN': 1.4,
    'HUSK': 1.95,
    'VINDICATOR': 1.95,
    'PILLAGER': 1.95,
    'SHULKER_BULLET': 0.25,
    'VILLAGER': 1.95,
    'TURTLE': 0.4,
    'TRADER_LLAMA': 1.87,
    'CAVE_SPIDER': 0.5,
    'SLIME': 0.75,
    'DROWNED': 1.95,
    'EVOKER': 1.95,
    'ENDERMITE': 0.3,
    //'PLAYER': 1.8,
    'SALMON': 0.4,
    'ZOMBIE': 1.95,
    'STRIDER': 1.7,
    'PANDA': 1.25,
    "OCELOT": 0.7,
    'ENDERMAN': 2.9,
    'ZOMBIE_VILLAGER': 1.95,
    'LLAMA': 1.87,
    'ENDER_DRAGON': 5,
    'WITCH': 1.95,
    'WITHER': 3.5,
    'CREEPER': 1.7,
    'ILLUSIONER': 1.95,
    'COD': 0.5,
    'ZOMBIE_HORSE': 1.4,
    'RAVAGER': 2.2,
    'SHULKER': 1,
    'BEE': 0.6,
    'PHANTOM': 0.5,
    'BLAZE': 1.8,
    'SKELETON_HORSE': 1.6,
    'COW': 1.4,
    'WANDERING_TRADER': 1.95,
    'PIG': 0.9,
    'ZOGLIN': 1.4,
    'WOLF': 0.86,
    'IRON_GOLEM': 2.7,
    'SHEEP':1.3,
    'VEX': 0.8,
    'PIGLIN_BRUTE': 1.95,
    'POLAR_BEAR': 1.4,
    'SNOWMAN': 1.9,
    'SQUID': 0.8,
    'ELDER_GUARDIAN': 2,
    'HORSE': 1.4,
    'PARROT': 0.9,
    'FOX': 0.6,
    'STRAY': 1.99,
    'CAT': 0.7,
    'RABBIT': 0.5,
    'DONKEY': 1.6,
    'ENDER_CRYSTAL': 2,
    'TROPICAL_FISH': 0.4,
    'SPIDER': 0.9,
    'SKELETON': 1.99,
    'WITHER_SKELETON': 2.4,
    'MUSHROOM_COW': 1.5,
    'CHICKEN': 0.7,
    'ZOMBIFIED_PIGLIN': 1.95,
    'PUFFERFISH': 0.4,
    'GUARDIAN': 0.85,
    'PIGLIN': 1.95,
    'GHAST': 4,
    'BAT': 0.9,
    'DOLPHIN': 0.6
  )
  @entity_type = entity_type(@euuid)
  # 기본 변수 선언
  @player_data = @players_data[@puuid]
  @skill_manager = @player_data['skill_manager']
  @selected_methods = json_decode(@skill_manager[4])
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
      if(entity_exists(@euuid)) {
        set_timeout(0, closure( set_entity_immunity_ticks(@euuid, @immunity_tick) ))
      }
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
      @skill_data = @player_data['skill_data'][@selected_combat_method]
      @point = @skill_data[0]
      call_proc(@proc_name, @event, @player_data, @player, @puuid, @category, @selected_combat_method, @skill_spec, @point, @attack_cooldown, @attribute_attack_damage, @attribute_attack_speed)
    }
  }
  ## 룬
  foreach(@selected_rune in @selected_runes) {
    @proc_name = "_apply_attacking_by_@selected_rune"
    if(is_proc(@proc_name)) {
      @category = 'rune'
      @point = @skill_manager
      @skill_spec = @skills_spec[@selected_rune]
      @skill_data = @player_data['skill_data'][@selected_rune]
      @point = @skill_data[0]
      call_proc(@proc_name, @event, @player_data, @player, @puuid, @category, @selected_rune, @skill_spec, @point, @attack_cooldown, @attribute_attack_damage, @attribute_attack_speed)
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
          @range = 15
        } else {
          @range = 7
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
        @range = 7
        @has_storm = false
        if(get_block(@entity_location) == 'WATER') {
          @range = 15
        }
        if(get_highest_block_at(@entity_location)['y'] <= @entity_location['y'] + 2) {
          if(has_thunder(@entity_location['world'])) {
            @range = 15
          } else if(has_storm(@entity_location['world'])) {
            @range = 15
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

# 스킬 HUD 아이콘
proc _update_skill_hud(@player, @uuid, @player_data, @skills_spec, @text) {
  # 스킬 매니징
  @skill_manager = @player_data['skill_manager']
  @selected_methods = json_decode(@skill_manager[4])

  # 변수들 선언
  @icons = array(
    'combat_method': array(
      'sweeping': '\uee20',
      'knockback': '\uee21',
      'cleaving': '\uee22',
      'blocking': '\uee23'
    ),
    'harvesting_method': array(
      'wide_hands': '\uee30',
      'golden_finger': '\uee31'
    ),
    'sowing_method': array(
      'wet_hands': '\uee40',
      'fertile_touch': '\uee41'
    )
  )
  @cooldowns = array('\uee10', '\uee11', '\uee12', '\uee13', '\uee14', '\uee15', '\uee16', '\uee17', '\uee18', '\uee19', '\uee1a', '\uee1b', '\uee1c', '\uee1d', '\uee1e', '\uee1f', @text['space_fonts']['space.17'])
  @charges = array('\uee02', '\uee03')
  @huds = array(
    'combat_method': '',
    'harvesting_method': '',
    'sowing_method': ''
  )
  //broadcast(@player @selected_methods)
  foreach(@method_type: @selected_method in @selected_methods) {
    @icon = @text['space_fonts']['space.17']
    @cooldown = @text['space_fonts']['space.17']
    @charge = ''
    if(@selected_method != '' && array_index_exists(@player_data['active_skill'], @selected_method)) {
      # 아이콘
      @icon = @icons[@method_type][@selected_method]
      # 쿨다운
      @active_skill = @player_data['active_skill'][@selected_method]
      @point = @player_data['skill_data'][@selected_method][0]
      @skill_spec = @skills_spec[@selected_method]
      if(@active_skill[1] > 0) { // 스킬 지속시간 있을시
        @max_duration = @skill_spec['effect_by_point'][@point]['active']['duration']
        @index = 16 - integer(@active_skill[1] / @max_duration * 16)
      } else { // 쿨타임중일시
        @max_cooldown = @skill_spec['effect_by_point'][@point]['active']['cooldown']
        @remain_cooldown = @max_cooldown - @active_skill[0]
        @index = 16 - integer(@remain_cooldown / @max_cooldown * 16)
      }
      if(@index > 16) { @index = 16}
      if(@index == 16 && (@active_skill[2] == 0 || @skill_spec['effect_by_point'][@point]['active']['count'] > @active_skill[2])) {
        @index = 15 // 지속시간 다 끝난후 or 충전 횟수 있을경우 쿨타임 16(쿨타임 다됨)될시 15(쿨타임 꽉참)로 변경
      } else if(@index == 0 && @active_skill[2] == 1 && @active_skill[0] == 0) {
        // 최대카운트 0인 스킬 쿨타임 다 됬을시
        @index = 16
      }
      @cooldown = @cooldowns[@index]
      # 충전 갯수
      if(@skill_spec['effect_by_point'][@point]['active']['count'] > 0) {
        @slots = array()
        @psfs = array()
        for(@i = 0, @i < @skill_spec['effect_by_point'][@point]['active']['count'], @i++) {
          if(@i < @active_skill[2]) {
            @slots[] = @text['space_fonts']['space.-6'].@charges[1]
          } else {
            @slots[] = @text['space_fonts']['space.-6'].@charges[0]
          }
          @psfs[] = @text['space_fonts']['space.3']
        }
        @charge = array_implode(array_merge(@slots, @psfs), '')
      }
    }
    @huds[@method_type] = @icon.@text['space_fonts']['space.-17'].@cooldown.@text['space_fonts']['space.2'].@charge.@text['space_fonts']['space.-2'].@text['space_fonts']['space.3']
  }

  @skill_hud = color('#fd0080').@text['space_fonts']['space.129'].@huds['combat_method'].@huds['harvesting_method'].@huds['sowing_method']
  _set_sidebar(@uuid, 1, @skill_hud, @text)
}

# 스킬 HUD 핫바 선택
proc _update_selected_skill_hotbar(@player, @uuid, @player_data, @skills_spec, @text) {
  # 스킬 매니징
  @skill_manager = @player_data['skill_manager']
  @selected_methods = json_decode(@skill_manager[4])
  # 손에 든 아이템 구하기
  @main_hand_item = @player_data['item']['main_hand']
  @hoes = array(
    'WOODEN_HOE',
    'STONE_HOE',
    'IRON_HOE',
    'GOLDEN_HOE',
    'DIAMOND_HOE',
    'NETHERITE_HOE'
  )
  @seeds = array(
    'WHEAT_SEEDS',
    'BEETROOT_SEEDS',
    'POTATO',
    'CARROT',
    'PUMPKIN_SEEDS',
    'MELON_SEEDS',
    'SWEET_BERRIES'
  )
  # 손에든 아이템, 사용중인 스킬에 따라 핫바 선택 조정
  if(!is_null(@main_hand_item)) { // 무언가 들고 있을시
    if(array_contains(@hoes, @main_hand_item['name'])) {
      @selected_hotbar = @text['space_fonts']['space.-64'].'\uee01'
      @skill = @selected_methods['harvesting_method']
    } else if(array_contains(@seeds, @main_hand_item['name'])) {
      @selected_hotbar = @text['space_fonts']['space.-44'].'\uee01'
      @skill = @selected_methods['sowing_method']
    } else {
      @selected_hotbar = @text['space_fonts']['space.-84'].'\uee01'
      @skill = @selected_methods['combat_method']
    }
    if(@skill == '') { // 파종, 수확 스킬 선택 안했을시
      @selected_hotbar = @text['space_fonts']['space.-84'].'\uee01'
      @skill = @selected_methods['combat_method']
    }
  } else { // 특별한 도구 든거 없을시
    @selected_hotbar = @text['space_fonts']['space.-84'].'\uee01'
    @skill = @selected_methods['combat_method']
  }
  if(@skill == '' || !array_index_exists(@player_data['active_skill'], @skill)) { // 전투스킬마저 없을시
    @selected_hotbar = ''
  }
  # 텍스트 생성
  @hotbar_texts = array(color('#fd0000'), @text['space_fonts']['space.126'].'\uee00', @selected_hotbar)
  @hotbar_text = array_implode(@hotbar_texts, '')

  _set_sidebar(@uuid, 2, @hotbar_text, @text)
}