## Data Procedure
proc _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text) {
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
    'indicator_remove_task': 0
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
    json_encode(array('default', 'local', 'town')), // 듣기 활성화 할 채널들
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

# 스코어보드 변경
proc _set_sidebar(@uuid, @line, @message, @text) {
  @scoreboard = "ch_scoreboard.@uuid"
  if(length(@message) <= 63) {
    set_team_display(@line, array('prefix': @message.@text['space_fonts']['space.-max'] ), @scoreboard)
  } else {
    set_team_display(@line, array('prefix': @line.'번째 줄이 너무 깁니다. '.@text['space_fonts']['space.-max'] ), @scoreboard)
  }
}

# 아이템 업데이트
proc _update_item(@player, @uuid, @items, @player_data, @skills_spec, @text) {
  @seeds = array(
    'WHEAT_SEEDS',
    'BEETROOT_SEEDS',
    'POTATO',
    'CARROT',
    'PUMPKIN_SEEDS',
    'MELON_SEEDS',
    'SWEET_BERRIES'
  )
  # 업뎃전 아이템
  @old_items = array_deep_clone(@items)
  # 인첸트 (오른손 왼손 갑빠)
  @enchantments = @player_data['item']['enchantments']
  # 스킬 매니징
  @skill_manager = @player_data['skill_manager']
  @selected_methods = json_decode(@skill_manager[4])
  @selected_combat_method = @selected_methods['combat_method']
  @selected_runes = json_decode(@skill_manager[5])
  # 적용할 스킬들
  @applying_skills = array()
  # 전투 방식
  if(@selected_combat_method != '') {
    @skill_proc_name = "_apply_item_update_by_@selected_combat_method"
    if(is_proc(@skill_proc_name))  {
      @applying_skill_data = array(
        'skill_spec': @skills_spec[@selected_combat_method],
        'point': @player_data['skill_data'][@selected_combat_method][0],
        'proc_name': @skill_proc_name
      )
      @applying_skills[@selected_combat_method] = @applying_skill_data
    }
  }
  # 룬
  foreach(@selected_rune in @selected_runes) {
    @skill_proc_name = "_apply_item_update_by_@selected_rune"
    if(is_proc(@skill_proc_name))  {
      @applying_skill_data = array(
        'skill_spec': @skills_spec[@selected_rune],
        'point': @player_data['skill_data'][@selected_rune][0],
        'proc_name': @skill_proc_name
      )
    }
  }
  # 기타 (서브 컴뱃 처럼 전투 방식, 룬은 아니면서 아이템(도구,무기)에 영향 미칠 스킬들)
  @extra_skills = array(
    'bow_bastery',
    'crossbow_mastery'
  )
  foreach(@extra_skill in @extra_skills) {
    @skill_proc_name = "_apply_item_update_by_@extra_skill"
    if(is_proc(@skill_proc_name))  {
      @applying_skill_data = array(
        'skill_spec': @skills_spec[@extra_skill],
        'point': @player_data['skill_data'][@extra_skill][0],
        'proc_name': @skill_proc_name
      )
    }
  }
  # 아이템 업데이트
  ## 주로 사용하는 손
  if(array_index_exists(@items, 'main_hand')) {
    @item = @items['main_hand']
    # 아이템 업뎃발동 했으니 일단 인첸트 없는것으로 선언
    @enchantments['main_hand'] = null
    if(!is_null(@item)) { // 도구 들고 있을 시
      if(!array_contains(@seeds, @item['name'])) {
        # 바닐라 인첸 목록 선언
        @vanilla_enchants = array()
        # 스킬 적용
        foreach(@applying_skill: @applying_skill_data in @applying_skills) {
          @skill_spec = @applying_skill_data['skill_spec']
          @point = @applying_skill_data['point']
          @proc_name = @applying_skill_data['proc_name']
          call_proc(@proc_name, @player_data, @player, @uuid, @applying_skill, @skill_spec, @point, @item, @vanilla_enchants)
        }
        # 기타 적용
        if(@item['name'] == 'TRIDENT') {
          @vanilla_enchants['loyalty'] = array(
            'etype': 'LOYALTY',
            'elevel': 5
          )
        }
        # 인첸트 적용
        if(!is_null(@item['meta']) && !is_null(@item['meta']['modifiers']) && !is_null(@item['meta']['lore'])) {
          @modifiers = @item['meta']['modifiers']
          @lore = @item['meta']['lore']
          if(array_size(@lore) > array_size(@modifiers)) {
            @enchantment = substr(strip_colors(@lore[array_size(@modifiers) + 1]), 2)
            @enchantments['main_hand'] = @enchantment
            switch(@enchantment) {
            case '내구성':
              @vanilla_enchants['unbreaking'] = array(
                'etype': 'DURABILITY',
                'elevel': 5
              )
              break()
            case '효율':
              @vanilla_enchants['efficiency'] = array(
                'etype': 'DIG_SPEED',
                'elevel': 3
              )
              break()
            case '행운':
              @vanilla_enchants['fortune'] = array(
                'etype': 'LOOT_BONUS_BLOCKS',
                'elevel': 2
              )
              @vanilla_enchants['looting'] = array(
                'etype': 'LOOT_BONUS_MOBS',
                'elevel': 2
              )
              break()
            }
          }
        }
        if(!@item['meta'] || !@item['meta']['flags']) {
          @item['meta'] = array('flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES'))
        }
        @item['meta']['enchants'] = @vanilla_enchants
        set_timeout(0, closure() {
          if(get_inventory_item(@uuid, pheld_slot(@player)) == @old_items['main_hand']) {
            set_inventory_item(@uuid, pheld_slot(@player), @item)
          }
        })
      }
    }
    @player_data['item']['main_hand'] = @item
  }
  ## 보조 손
  if(array_index_exists(@items, 'off_hand')) {
    @item = @items['off_hand']
    # 아이템 업뎃발동 했으니 일단 인첸트 없는것으로 선언
    @enchantments['off_hand'] = null
    if(!is_null(@item)) { // 도구 들고 있을 시
      if(!array_contains(@seeds, @item['name'])) {
        # 바닐라 인첸 목록 선언
        @vanilla_enchants = array()
        # 스킬 적용
        foreach(@applying_skill: @applying_skill_data in @applying_skills) {
          @skill_spec = @applying_skill_data['skill_spec']
          @point = @applying_skill_data['point']
          @proc_name = @applying_skill_data['proc_name']
          call_proc(@proc_name, @player_data, @player, @uuid, @applying_skill, @skill_spec, @point, @item, @vanilla_enchants)
        }
        #기타 적용
        if(@item['name'] == 'TRIDENT') {
          @vanilla_enchants['loyalty'] = array(
            'etype': 'LOYALTY',
            'elevel': 5
          )
        }
        # 인첸트 적용
        if(!is_null(@item['meta']) && !is_null(@item['meta']['modifiers']) && !is_null(@item['meta']['lore'])) {
          @modifiers = @item['meta']['modifiers']
          @lore = @item['meta']['lore']
          if(array_size(@lore) > array_size(@modifiers)) {
            @enchantment = substr(strip_colors(@lore[array_size(@modifiers) + 1]), 2)
            @enchantments['off_hand'] = @enchantment
            switch(@enchantment) {
            case '내구성':
              @vanilla_enchants['unbreaking'] = array(
                'etype': 'DURABILITY',
                'elevel': 5
              )
              break()
            }
          }
        }
        if(!@item['meta'] || !@item['meta']['flags']) {
          @item['meta'] = array('flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES'))
        }
        @item['meta']['enchants'] = @vanilla_enchants
        set_timeout(0, closure() {
          if(get_inventory_item(@uuid, 40) == @old_items['off_hand']) {
            set_inventory_item(@uuid, 40, @item)
          }
        })
      }
    }
    @player_data['item']['off_hand'] = @item
  }
  ## 갑옷
  if(array_index_exists(@items, 'armor')) {
    @item = @items['armor']
    # 아이템 업뎃발동 했으니 일단 인첸트 없는것으로 선언
    @enchantments['armor'] = null
    # 인첸트 적용
    if(!is_null(@item)) { // 갑옷 입었을 시
      #인첸트 적용
      if(!is_null(@item['meta']) && !is_null(@item['meta']['modifiers']) && !is_null(@item['meta']['lore'])) {
        @modifiers = @item['meta']['modifiers']
        @lore = @item['meta']['lore']
        if(array_size(@lore) > array_size(@modifiers)) {
          @enchantment = substr(strip_colors(@lore[array_size(@modifiers) + 1]), 2)
          @enchantments['armor'] = @enchantment
          @vanilla_enchants = array()
          switch(@enchantment) {
          case '견교':
            @vanilla_enchants['unbreaking'] = array(
              'etype': 'DURABILITY',
              'elevel': 5
            )
            break()
          case '복원':
          case '귀속':
            @vanilla_enchants['unbreaking'] = array(
              'etype': 'DURABILITY',
              'elevel': 1
            )
            break()
          case '보호':
            @vanilla_enchants['protection'] = array(
              'etype': 'PROTECTION_ENVIRONMENTAL',
              'elevel': 5
            )
            break()
          case '원소 보호':
            @vanilla_enchants['fire_protection'] = array(
              'etype': 'PROTECTION_FIRE',
              'elevel': 4
            )
            break()
          case '친수성':
            @vanilla_enchants['respiration'] = array(
              'etype': 'OXYGEN',
              'elevel': 3
            )
            @vanilla_enchants['aqua_affinity'] = array(
              'etype': 'WATER_WORKER',
              'elevel': 1
            )
            @vanilla_enchants['depth_strider'] = array(
              'etype': 'DEPTH_STRIDER',
              'elevel': 3
            )
            break()
          case '반엔트로피':
            @vanilla_enchants['fire_protection'] = array(
              'etype': 'PROTECTION_FIRE',
              'elevel': 10
            )
            break()
          case '깃털':
            @vanilla_enchants['feather_falling'] = array(
              'etype': 'PROTECTION_FALL',
              'elevel': 10
            )
            break()
          }
          @item['meta']['enchants'] = @vanilla_enchants
        }
      }
      set_timeout(0, closure() {
        if(get_inventory_item(@uuid, 36) == @old_items['armor']) {
          set_inventory_item(@uuid, 36, @item)
          @decoration_armors = array()
          switch(@item['name']) {
          case 'LEATHER_BOOTS':
            #if(머리 치장이 없을 시) {
              @decoration_armors[39] = array(
                'name': 'LEATHER_HELMET',
                'meta': array(
                  'display': ' ',
                  'enchants': array(
                    'binding_curse': array(
                      'etype': 'BINDING_CURSE',
                      'elevel': 1
                    )
                  ),
                  'modifiers': array(
                    array(
                      'attribute': 'GENERIC_ARMOR',
                      'operation': 'ADD_NUMBER',
                      'amount': 0,
                      'slot': 'HELMET'
                    )
                  ),
                  'unbreakable': true,
                  'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
                )
              )
            #}
            @decoration_armors[38] = array(
              'name': 'LEATHER_CHESTPLATE',
              'meta': array(
                'display': ' ',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'CHESTPLATE'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            @decoration_armors[37] = array(
              'name': 'LEATHER_LEGGINGS',
              'meta': array(
                'display': color('WHITE').'유틸 GUI',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'LEGGINGS'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            break()
          case 'CHAINMAIL_BOOTS':
            #if(머리 치장이 없을 시) {
              @decoration_armors[39] = array(
                'name': 'CHAINMAIL_HELMET',
                'meta': array(
                  'display': ' ',
                  'enchants': array(
                    'binding_curse': array(
                      'etype': 'BINDING_CURSE',
                      'elevel': 1
                    )
                  ),
                  'modifiers': array(
                    array(
                      'attribute': 'GENERIC_ARMOR',
                      'operation': 'ADD_NUMBER',
                      'amount': 0,
                      'slot': 'HELMET'
                    )
                  ),
                  'unbreakable': true,
                  'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
                )
              )
            #}
            @decoration_armors[38] = array(
              'name': 'CHAINMAIL_CHESTPLATE',
              'meta': array(
                'display': ' ',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'CHESTPLATE'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            @decoration_armors[37] = array(
              'name': 'CHAINMAIL_LEGGINGS',
              'meta': array(
                'display': color('WHITE').'유틸 GUI',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'LEGGINGS'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            break()
          case 'IRON_BOOTS':
            #if(머리 치장이 없을 시) {
              @decoration_armors[39] = array(
                'name': 'IRON_HELMET',
                'meta': array(
                  'display': ' ',
                  'enchants': array(
                    'binding_curse': array(
                      'etype': 'BINDING_CURSE',
                      'elevel': 1
                    )
                  ),
                  'modifiers': array(
                    array(
                      'attribute': 'GENERIC_ARMOR',
                      'operation': 'ADD_NUMBER',
                      'amount': 0,
                      'slot': 'HELMET'
                    )
                  ),
                  'unbreakable': true,
                  'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
                )
              )
            #}
            @decoration_armors[38] = array(
              'name': 'IRON_CHESTPLATE',
              'meta': array(
                'display': ' ',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'CHESTPLATE'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            @decoration_armors[37] = array(
              'name': 'IRON_LEGGINGS',
              'meta': array(
                'display': color('WHITE').'유틸 GUI',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'LEGGINGS'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            break()
          case 'GOLDEN_BOOTS':
            #if(머리 치장이 없을 시) {
              @decoration_armors[39] = array(
                'name': 'GOLDEN_HELMET',
                'meta': array(
                  'display': ' ',
                  'enchants': array(
                    'binding_curse': array(
                      'etype': 'BINDING_CURSE',
                      'elevel': 1
                    )
                  ),
                  'modifiers': array(
                    array(
                      'attribute': 'GENERIC_ARMOR',
                      'operation': 'ADD_NUMBER',
                      'amount': 0,
                      'slot': 'HELMET'
                    )
                  ),
                  'unbreakable': true,
                  'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
                )
              )
            #}
            @decoration_armors[38] = array(
              'name': 'GOLDEN_CHESTPLATE',
              'meta': array(
                'display': ' ',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'CHESTPLATE'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            @decoration_armors[37] = array(
              'name': 'GOLDEN_LEGGINGS',
              'meta': array(
                'display': color('WHITE').'유틸 GUI',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'LEGGINGS'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            break()
          case 'DIAMOND_BOOTS':
            #if(머리 치장이 없을 시) {
              @decoration_armors[39] = array(
                'name': 'DIAMOND_HELMET',
                'meta': array(
                  'display': ' ',
                  'enchants': array(
                    'binding_curse': array(
                      'etype': 'BINDING_CURSE',
                      'elevel': 1
                    )
                  ),
                  'modifiers': array(
                    array(
                      'attribute': 'GENERIC_ARMOR',
                      'operation': 'ADD_NUMBER',
                      'amount': 0,
                      'slot': 'HELMET'
                    )
                  ),
                  'unbreakable': true,
                  'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
                )
              )
            #}
            @decoration_armors[38] = array(
              'name': 'DIAMOND_CHESTPLATE',
              'meta': array(
                'display': ' ',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'CHESTPLATE'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            @decoration_armors[37] = array(
              'name': 'DIAMOND_LEGGINGS',
              'meta': array(
                'display': color('WHITE').'유틸 GUI',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'LEGGINGS'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            break()
          case 'NETHERITE_BOOTS':
            #if(머리 치장이 없을 시) {
              @decoration_armors[39] = array(
                'name': 'NETHERITE_HELMET',
                'meta': array(
                  'display': ' ',
                  'enchants': array(
                    'binding_curse': array(
                      'etype': 'BINDING_CURSE',
                      'elevel': 1
                    )
                  ),
                  'modifiers': array(
                    array(
                      'attribute': 'GENERIC_ARMOR',
                      'operation': 'ADD_NUMBER',
                      'amount': 0,
                      'slot': 'HELMET'
                    )
                  ),
                  'unbreakable': true,
                  'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
                )
              )
            #}
            @decoration_armors[38] = array(
              'name': 'NETHERITE_CHESTPLATE',
              'meta': array(
                'display': ' ',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'CHESTPLATE'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            @decoration_armors[37] = array(
              'name': 'NETHERITE_LEGGINGS',
              'meta': array(
                'display': color('WHITE').'유틸 GUI',
                'enchants': array(
                  'binding_curse': array(
                    'etype': 'BINDING_CURSE',
                    'elevel': 1
                  )
                ),
                'modifiers': array(
                  array(
                    'attribute': 'GENERIC_ARMOR',
                    'operation': 'ADD_NUMBER',
                    'amount': 0,
                    'slot': 'LEGGINGS'
                  )
                ),
                'unbreakable': true,
                'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
              )
            )
            break()
          }
          foreach(@decoration_slot: @decoration_armor in @decoration_armors) {
            set_inventory_item(@uuid, @decoration_slot, @decoration_armor)
          }
        }
      })
    } else { // 갑옷 벗었을 시
      #머리 치장 없을경우
        set_inventory_item(@uuid, 39, array(
          'name': 'STRUCTURE_VOID',
          'meta': array(
            'display': ' ',
            'model': 1,
            'enchants': array(
              'binding_curse': array(
                'etype': 'BINDING_CURSE',
                'elevel': 1
              )
            ),
            'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
          )
        ))
      #
      set_inventory_item(@uuid, 38, array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': ' ',
          'model': 1,
          'enchants': array(
            'binding_curse': array(
              'etype': 'BINDING_CURSE',
              'elevel': 1
            )
          ),
          'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
        )
      ))
      set_inventory_item(@uuid, 37, array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': color('WHITE').'유틸 GUI',
          'model': 2,
          'enchants': array(
            'binding_curse': array(
              'etype': 'BINDING_CURSE',
              'elevel': 1
            )
          ),
          'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
        )
      ))
    }
    @player_data['item']['armor'] = @item
  }
  foreach(@slot: @enchantment in @enchantments) {
    @player_data['item']['enchantments'][@slot] = @enchantment
  }
  set_timeout(0, closure() {
    _update_selected_skill_hotbar(@player, @uuid, @player_data, @skills_spec, @text)
  })
}

# 리소스팩 보내기
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
    _load_data(@player, @uuid, @players_data, @skills_spec, @effective_items, @text)
  })
}

# 플레이어 접속
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

# 플레이어 퇴장
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

# 서버 이동시 카운트 다운 (카운트 다운이 다 되면 서버 나간것으로 간주)
proc _countdown_reconnectable_players(@reconnectable_players) {
  foreach(@uuid: @remaining_second in @reconnectable_players) {
    if(@remaining_second > 0) {
      @reconnectable_players[@uuid] -= 1
    } else {
      array_remove(@reconnectable_players, @uuid)
    }
  }
}

# 인디케이터
proc _show_indicator(@uuid, @player_data, @indicator_data, @text) {

  @queue_id = @indicator_data['id']'.'@indicator_data['block']
  @queue = "@uuid.indicator"

  @icons = array(
    'COAL_ORE': '\ue4c7',
    'COPPER_ORE': '\ue4c8',
    'IRON_ORE': '\ue4c9',
    'LAPIS_ORE': '\ue4ca',
    'GOLD_ORE': '\ue4cb',
    'NETHER_QUARTZ_ORE': '\ue4cc',
    'REDSTONE_ORE': '\ue4cd',
    'EMERALD_ORE': '\ue4ce',
    'DIAMOND_ORE': '\ue4cf',
    'ANCIENT_DEBRIS': '\ue4d0',
    'DEEPSLATE_COAL_ORE': '\ue4d1',
    'DEEPSLATE_COPPER_ORE': '\ue4d2',
    'DEEPSLATE_IRON_ORE': '\ue4d3',
    'DEEPSLATE_LAPIS_ORE': '\ue4d4',
    'DEEPSLATE_GOLD_ORE': '\ue4d5',
    'NETHER_GOLD_ORE': '\ue4d6',
    'DEEPSLATE_REDSTONE_ORE': '\ue4d7',
    'DEEPSLATE_EMERALD_ORE': '\ue4d8',
    'DEEPSLATE_DIAMOND_ORE': '\ue4d9',
    'FARMLAND': '\ue4da'

  )
  @backgrounds = array(
    '\ue406',
    '\ue408', '\ue409', '\ue40a', '\ue40b', '\ue40c', '\ue40d', '\ue40e', '\ue40f', '\ue410', '\ue411',
    '\ue412', '\ue413', '\ue414', '\ue415', '\ue416', '\ue417', '\ue418', '\ue419', '\ue41a', '\ue41b',
    '\ue41c', '\ue41d', '\ue41e', '\ue41f', '\ue420', '\ue421', '\ue422', '\ue423', '\ue424', '\ue425',
    '\ue426', '\ue427', '\ue428', '\ue429', '\ue42a', '\ue42b', '\ue42c', '\ue42d', '\ue42e', '\ue42f',
    '\ue430', '\ue431', '\ue432', '\ue433', '\ue434', '\ue435', '\ue436', '\ue437', '\ue438', '\ue439',
    '\ue43a', '\ue43b', '\ue43c', '\ue43d', '\ue43e', '\ue43f', '\ue440', '\ue441', '\ue442', '\ue443',
    '\ue444', '\ue445', '\ue446', '\ue447', '\ue448', '\ue449', '\ue44a', '\ue44b', '\ue44c', '\ue44d',
    '\ue4b2', '\ue4b3', '\ue4b4', '\ue4b5', '\ue4b6', '\ue4b7', '\ue4b8', '\ue4b9', '\ue4ba', '\ue4bb',
    '\ue4bc', '\ue4bd', '\ue4be', '\ue4bf'
  )

  @icon = @icons[@indicator_data['block']]

  @old_background_index = integer((1- @indicator_data['old_hp'] / @indicator_data['max_hp']) * 84)
  @new_background_index = integer((1- @indicator_data['new_hp'] / @indicator_data['max_hp']) * 84)

  clear_task(@player_data['cache']['indicator_remove_task'])

  // 큐 프리셋
  if(queue_running(@queue)) {
    if(@player_data['cache']['indicator_id'] == @queue_id) {
      //같은 블럭 상호작용시 인디케이터 제거 큐 삭제
      queue_remove(@queue)
    } else{
      //다른 블럭 상호작용시 큐 클리어
      queue_clear(@queue)
    }
  }

  // 인디케이터 메인 큐 푸시
  if(@new_background_index != @old_background_index) {
    // 체력 변화 있을시
    for(@i = @old_background_index, @i <= @new_background_index, @i++) {
      @chance = ((@i - @old_background_index) / (@new_background_index - @old_background_index)) ** 2
      if(rand() < @chance) {
        @background = @backgrounds[@i]
        @closure = closure() {
          _set_sidebar(@uuid, 4, color('#fc8080').@text['space_fonts']['space.4'].@background.@text['space_fonts']['space.-20'].@icon, @text)
        }
        queue_push(@closure, @queue)
      }
    }
  } else {
    // 체력 변화 없을시
    @background = @backgrounds[@new_background_index]
    _set_sidebar(@uuid, 4, color('#fc8080').@text['space_fonts']['space.4'].@background.@text['space_fonts']['space.-20'].@icon, @text)
  }

  // 인디케이터 제거 큐 푸시
  @closure = closure() {
    @task = set_timeout(integer(@indicator_data['countdown'] * 1000), closure() {
      _set_sidebar(@uuid, 4, '', @text)
    })
    @player_data['cache']['indicator_remove_task'] = @task
  }
  queue_push(@closure, @queue)

  // 인디케이터 id 저장
  @player_data['cache']['indicator_id'] = @queue_id
}

# 레벨 HUDs
proc _replace_tunalevel_text(@tunalevel) {
  @background = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      @tunalevel, '0', '\uf802\uef10\uf801'
                    ), '1', '\uf802\uef11\uf801'
                  ), '2', '\uf802\uef12\uf801'
                ), '3', '\uf802\uef13\uf801'
              ), '4', '\uf802\uef14\uf801'
            ), '5', '\uf802\uef15\uf801'
          ), '6', '\uf802\uef16\uf801'
        ), '7', '\uf802\uef17\uf801'
      ), '8', '\uf802\uef18\uf801'
    ), '9', '\uf802\uef19\uf801'
  )
  @text = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      @tunalevel, '0', '\uef00\uf801'
                    ), '1', '\uef01\uf801'
                  ), '2', '\uef02\uf801'
                ), '3', '\uef03\uf801'
              ), '4', '\uef04\uf801'
            ), '5', '\uef05\uf801'
          ), '6', '\uef06\uf801'
        ), '7', '\uef07\uf801'
      ), '8', '\uef08\uf801'
    ), '9', '09\uf801'
  )
  @chars = split('', @tunalevel)
  @nsf = ''
  foreach(@char in @chars) {
    if(@char == 1) {
      @nsf = @nsf.'\uF803'
    } else {
      @nsf = @nsf.'\uF804'
    }
  }
  @tunalevel_text = '\uef1c\uf801'.@background.'\uf801'.@nsf.'\uf808\uf801'.'\uef1b\uf801'.@text
  return(@tunalevel_text)
}

proc _replace_arcanelevel_text(@arcanelevel) {
  @background = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      @arcanelevel, '0', '\uf802\uef30\uf801'
                    ), '1', '\uf802\uef31\uf801'
                  ), '2', '\uf802\uef32\uf801'
                ), '3', '\uf802\uef33\uf801'
              ), '4', '\uf802\uef34\uf801'
            ), '5', '\uf802\uef35\uf801'
          ), '6', '\uf802\uef36\uf801'
        ), '7', '\uf802\uef37\uf801'
      ), '8', '\uf802\uef38\uf801'
    ), '9', '\uf802\uef39\uf801'
  )
  @text = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      @arcanelevel, '0', '\uef20\uf801'
                    ), '1', '\uef21\uf801'
                  ), '2', '\uef22\uf801'
                ), '3', '\uef23\uf801'
              ), '4', '\uef24\uf801'
            ), '5', '\uef25\uf801'
          ), '6', '\uef26\uf801'
        ), '7', '\uef27\uf801'
      ), '8', '\uef28\uf801'
    ), '9', '\uef29\uf801'
  )
  @chars = split('', @arcanelevel)
  @nsf = ''
  foreach(@char in @chars) {
    if(@char == 1) {
      @nsf = @nsf.'\uF803'
    } else {
      @nsf = @nsf.'\uF804'
    }
  }
  @arcanelevel_text = '\uef3c\uf801'.@background.'\uf801'.@nsf.'\uf808\uf801'.'\uef3b\uf801'.@text
  return(@arcanelevel_text)
}

proc _show_arcanelevel(@player, @uuid, @text) {
  # bar
  @bars = array(
    '\ueeb0', '\ueeb1', '\ueeb2', '\ueeb3', '\ueeb4', '\ueeb5', '\ueeb6', '\ueeb7', '\ueeb8', '\ueeb9', '\ueeba', '\ueebb', '\ueebc', '\ueebd', '\ueebe', '\ueebf',
    '\ueec0', '\ueec1', '\ueec2', '\ueec3', '\ueec4', '\ueec5', '\ueec6', '\ueec7', '\ueec8', '\ueec9', '\ueeca', '\ueecb', '\ueecc', '\ueecd', '\ueece', '\ueecf',
    '\ueed0', '\ueed1', '\ueed2', '\ueed3', '\ueed4', '\ueed5', '\ueed6', '\ueed7', '\ueed8', '\ueed9', '\ueeda', '\ueedb', '\ueedc', '\ueedd', '\ueede', '\ueedf',
    '\ueee0', '\ueee1', '\ueee2', '\ueee3', '\ueee4', '\ueee5', '\ueee6', '\ueee7', '\ueee8', '\ueee9', '\ueeea', '\ueeeb', '\ueeec', '\ueeed', '\ueeee', '\ueeef',
    '\ueef0', '\ueef1', '\ueef2', '\ueef3', '\ueef4', '\ueef5', '\ueef6', '\ueef7', '\ueef8', '\ueef9', '\ueefa', '\ueefb', '\ueefc', '\ueefd', '\ueefe', '\ueeff'
  )
  @bar_index = integer(pexp(@player) * 0.8)
  @bar = @bars[@bar_index]
  
  # level
  @arcanelevel_text = _replace_arcanelevel_text(plevel(@player))

  _set_sidebar(@uuid, 6, color('#fd0000').@text['space_fonts']['space.9'].@bar.@text['space_fonts']['space.-83'].@arcanelevel_text, @text)
}

proc _show_tunalevel(@uuid, @player_data, @text) {
  @tunalevel = @player_data['skill_manager'][0]
  @experience = @player_data['skill_manager'][1]
  @max_experience = _get_max_tuna_experience(@tunalevel)
  # bar
  @bars = array(
    '\uee60', '\uee61', '\uee62', '\uee63', '\uee64', '\uee65', '\uee66', '\uee67', '\uee68', '\uee69', '\uee6a', '\uee6b', '\uee6c', '\uee6d', '\uee6e', '\uee6f',
    '\uee70', '\uee71', '\uee72', '\uee73', '\uee74', '\uee75', '\uee76', '\uee77', '\uee78', '\uee79', '\uee7a', '\uee7b', '\uee7c', '\uee7d', '\uee7e', '\uee7f',
    '\uee80', '\uee81', '\uee82', '\uee83', '\uee84', '\uee85', '\uee86', '\uee87', '\uee88', '\uee89', '\uee8a', '\uee8b', '\uee8c', '\uee8d', '\uee8e', '\uee8f',
    '\uee90', '\uee91', '\uee92', '\uee93', '\uee94', '\uee95', '\uee96', '\uee97', '\uee98', '\uee99', '\uee9a', '\uee9b', '\uee9c', '\uee9d', '\uee9e', '\uee9f',
    '\ueea0', '\ueea1', '\ueea2', '\ueea3', '\ueea4', '\ueea5', '\ueea6', '\ueea7', '\ueea8', '\ueea9', '\ueeaa', '\ueeab', '\ueeac', '\ueead', '\ueeae', '\ueeaf'
  )
  @bar_index = integer((@experience / @max_experience) * 80)
  @bar = @bars[@bar_index]
  # level
  @tunalevel_text = _replace_tunalevel_text(@tunalevel)
  _set_sidebar(@uuid, 5, color('#fd0000').@text['space_fonts']['space.-92'].@bar.@text['space_fonts']['space.-83'].@tunalevel_text, @text)
}

bind('exp_change', null, null, @event, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  set_timeout(0, closure() {
    _show_arcanelevel(@player, @uuid, @text)
  })
}