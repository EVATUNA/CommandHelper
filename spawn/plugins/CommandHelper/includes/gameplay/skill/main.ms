console('EvaSkill loaded')

@skills_info = array()
async_read('skills_info.json', closure(@value) {
  foreach(@category: @skills in json_decode(@value)) {
    @skills_info[@category] = @skills
  }
})
@skills_spec = array()
async_read('skills_spec.json', closure(@value) {
  foreach(@category: @skills in json_decode(@value)) {
    @skills_spec[@category] = @skills
  }
})
#["\ue3db\ue3dc\ue3dd\ue3de\ue3df", "\ue3e0\ue3e1\ue3e2\ue3e3\ue3e4", "\ue3e5\ue3e6\ue3e7\ue3e8\ue3e9", "\ue3ea\ue3eb\ue3ec\ue3ed\ue3ee", "\ue3ef\ue3f0\ue3f1\ue3f2\ue3f3", "\ue3f4\ue3f5\ue3f6\ue3f7\ue3f8"]

proc _load_skill_data(@uuid, @category, @skill, @is_default, @players_data, @skills_spec) {
  @skill_data = cup_get('SKILL_DATA', @uuid.'_'.@skill)
  if(@is_default) {
    if(is_null(@skill_data)) {
      @skill_data = array(
        1,
        10,
        3,
        @skills_spec[@category][@skill]['levels'][0]['max_experience']
      )
      cup_set('SKILL_DATA', @uuid.'_'.@skill, @skill_data)
    }
    @players_data[@uuid]['skill_data'][@category][@skill] = @skill_data
  } else {
    /* 나중에 아래 코드로 바꿔야 함 지금은 어떤 전투 특성이든 모두 배우게 되어있음
    if(!is_null(@skill_data)) {
      @players_data[@uuid]['skill_data'][@category][@skill] = @skill_data
    }
    */
    if(is_null(@skill_data)) {
      @skill_data = array(
        1,
        10,
        3,
        @skills_spec[@category][@skill]['levels'][0]['max_experience']
      )
      cup_set('SKILL_DATA', @uuid.'_'.@skill, @skill_data)
    }
    @players_data[@uuid]['skill_data'][@category][@skill] = @skill_data
  }
}

proc _load_active_skill(@uuid, @category, @skill, @level, @players_data, @skills_spec) {
  @active_skill = cup_get('ACTIVE_SKILL', @uuid.'_'.@skill)
  if(is_null(@active_skill)) {
    @active_skill = array(
      @skills_spec[@category][@skill]['levels'][@level]['active']['cooldown'],
      0,
      0,
      0
    )
    cup_set('ACTIVE_SKILL', @uuid.'_'.@skill, @active_skill)
  }
  @players_data[@uuid]['active_skill'][@category][@skill] = @active_skill
}

proc _set_skill_effect(@uuid, @category, @skill, @level, @players_data, @skills_spec) {
  switch(@category) {
  case 'combat_method':
    switch(@skill) {
    case 'sweeping':
      _load_active_skill(@uuid, @category, @skill, @level, @players_data, @skills_spec)
      @passive_attack_speed = @skills_spec['combat_method'][@skill]['levels'][@level]['passive']['attack_speed']
      @modifier = array(
        'attribute': 'GENERIC_ATTACK_SPEED',
        'operation': 'ADD_SCALAR',
        'amount': @passive_attack_speed,
        'name': 'sweeping_passive'
      )
      add_entity_attribute_modifier(@uuid, @modifier)
      break()
    case 'knockback':
      _load_active_skill(@uuid, @category, @skill, @level, @players_data, @skills_spec)
      break()
    case 'cleaving':
      _load_active_skill(@uuid, @category, @skill, @level, @players_data, @skills_spec)
      break()
    #case 'blocking':
    #  _load_active_skill(@uuid, @category, @skill, @level, @players_data, @skills_spec)
    #  break()
    }
    break()
  case 'subcombat':
    switch(@skill) {
    case 'health_traing':
      @max_health = @skills_spec['subcombat'][@skill]['levels'][@level]['max_health']
      set_entity_attribute_base(@uuid, 'GENERIC_MAX_HEALTH', @max_health)
      break()
    }
    break()
  #case 'farming':
  #  break()
  case 'harvesting_method':
    _load_active_skill(@uuid, @category, @skill, @level, @players_data, @skills_spec)
    #switch(@skill) {
    #case 'wide_hand':
    #  break()
    #case 'golden_finger':
    #  break()
    #}
    break()
  case 'sowing_method':
    _load_active_skill(@uuid, @category, @skill, @level, @players_data, @skills_spec)
    #switch(@skill) {
    #case 'wet_hands':
    #  break()
    #case 'fertile_touch':
    #  break()
    #}
    break()
  #case 'mining':
  #  break()
  }
}

proc _reset_skill_effect(@uuid, @category) {
  switch(@category) {
  case 'combat_method':
    remove_entity_attribute_modifier(@uuid, 'GENERIC_ATTACK_SPEED', 'sweeping_passive')
    remove_entity_attribute_modifier(@uuid, 'GENERIC_ATTACK_SPEED', 'sweeping_active')
    break()
  case 'combat_inclination':
    break()
  #case 'subcombat':
  #  break()
  #case 'farming':
  #  break()
  #case 'harvesting_method':
  #  break()
  #case 'sowing_method':
  #  break()
  #case 'mining':
  #  break()
  }
}

proc _load_skill_manager(@uuid, @players_data, @skills_spec) {
  @skill_manager = cup_get('SKILL_MANAGER', @uuid)
  if(is_null(@skill_manager)) {
    @skill_manager = array(
      '[]',
      1,
      '',
      '',
      ''
    )
    cup_set('SKILL_MANAGER', @uuid, @skill_manager)
  }
  @players_data[@uuid]['skill_manager'] = @skill_manager

  #reset effect
  _reset_skill_effect(@uuid, 'combat_method')
  _reset_skill_effect(@uuid, 'combat_inclination')

  #subcombat
  @category = 'subcombat'
  @skill = 'health_traing'
  @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
  if(@level > 0) {
    _set_skill_effect(@uuid, @category, @skill, @level, @players_data, @skills_spec)
  }

  #combat_inclination
  @category = 'combat_inclination'
  foreach(@skill in json_decode(@skill_manager[0])) {
    if(@skill != '') {
      @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
      if(@level > 0) {

      }
    }
    switch(@skill) {
    case 'test':
      #조건에 맞을시 효과 반영
      #액티브 스킬 있을시 액티브 추가
      break()
    }
  }

  #combat_method
  if(@skill_manager[2] != '') {
    @category = 'combat_method'
    @skill = @skill_manager[2]
    @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
    if(@level > 0) {
      _set_skill_effect(@uuid, @category, @skill, @level, @players_data, @skills_spec)
    }
  }

  #harvesting_method
  if(@skill_manager[3] != '') {
    @category = 'harvesting_method'
    @skill = @skill_manager[3]
    @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
    if(@level > 0) {
      _set_skill_effect(@uuid, @category, @skill, @level, @players_data, @skills_spec)
    }
  }

  #sowing_method
  if(@skill_manager[4] != '') {
    @category = 'sowing_method'
    @skill = @skill_manager[4]
    @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
    if(@level > 0) {
      _set_skill_effect(@uuid, @category, @skill, @level, @players_data, @skills_spec)
    }
  }
}

proc _load_skills(@uuid, @players_data, @skills_spec) {
  @default_skills = array(
    'combat_method': array(
      'sweeping',
      'knockback',
      'cleaving',
      'blocking'
    ),
    'subcombat': array(
      'bow_mastery',
      'crossbow_mastery',
      'health_traing'
    ),
    'farming': array(
      'wheat_farming_mastery',
      'beetroots_farming_mastery',
      'potatoes_farming_mastery',
      'carrots_farming_mastery',
      'berry_farming_mastery',
      'pumpkin_farming_mastery',
      'melon_farming_mastery',
      'plenty'
    ),
    'harvesting_method': array(
      'wide_hand',
      'golden_finger'
    ),
    'sowing_method': array(
      'wet_hands',
      'fertile_touch'
    ),
    'mining': array(
      'copper_mining_mastery',
      'iron_mining_mastery',
      'gold_mining_mastery',
      'diamond_mining_mastery',
      'ancient_debris_mining_mastery',
      'ore_selecting',
      'tough_shoulder'
    )
  )
  foreach(@category: @skills in @default_skills) {
    foreach(@skill in @skills) {
      _load_skill_data(@uuid, @category, @skill, true, @players_data, @skills_spec)
    }
  }
  @additional_skills = array(
    'combat_inclination': array(
      'test1'
    )
  )
  foreach(@category: @skills in @additional_skills) {
    foreach(@skill in @skills) {
      _load_skill_data(@uuid, @category, @skill, false, @players_data, @skills_spec)
    }
  }

  #전투 방식 로드시 레벨 1이상일 경우에만 로드
  #사용하지 않던 특성을 사용할 시 new / 매초마다 set
  _load_skill_manager(@uuid, @players_data, @skills_spec)
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
          @desription = @combat_method_info['display'].' 전투 방식을 사용중입니다.\n\n§c좌 클릭시, 전투 방식 선택창을 열어\n모든 전투 방식의 숙련 레벨과\n숙련 경험치를 확인 할 수 있으며\n전투 방식을 변경 할 수 있습니다.'
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
      @desription = '사용중인 전투 방식이 없습니다.\n\n§c좌 클릭시, 전투 방식 선택창을 열어\n모든 전투 방식의 숙련 레벨과\n숙련경험치를 확인 할 수 있으며\n전투 방식을 변경 할 수 있습니다.'
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
          @desription = @combat_inclination_info['display'].' 특성을 적용중입니다.\n\n§c좌 클릭시, 전투 특성 선택창을 열어\n습득한 모든 전투 특성을 확인 할 수 있으며\n특성 변경이 가능합니다.'
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
    @desription = '해당 슬롯에 적용된 특성이 없습니다.\n\n§c좌 클릭시, 전투 특성 선택창을 열어\n습득한 모든 전투 특성을 확인 할 수 있으며\n특성 변경이 가능합니다.'
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

register_command('skillbook', array(
  'description': 'can see skill book',
  'usage': '/skillbook',
  'aliases': array('ability', 'abilitybook', 'mastery', 'masterybook', 'skill'),
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) { 
    @uuid = puuid(@player)
    @player_skill_data = @players_data[@uuid]['skill_data']
    if(array_size(@args) > 0) {
      switch(@args[0]) {
      case 'open':
        switch(@args[1]) {
        case 'combat':
          _open_skillbook(@player, 'combat', null, @players_data, @skills_info, @text)
          break()
        case 'combat_method':
          _open_skillbook(@player, 'combat_method', null, @players_data, @skills_info, @text)
          break()
        case 'combat_inclination':
          if(array_size(@args) == 2) {
            @subpage = 0
          } else {
            @subpage = @args[2]
          }
          _open_skillbook(@player, 'combat_inclination', @subpage, @players_data, @skills_info, @text)
          break()
        case 'farming':
          if(array_size(@args) == 2) {
            @subpage = 0
          } else {
            @subpage = @args[2]
          }
          _open_skillbook(@player, 'farming', @subpage, @players_data, @skills_info, @text)
          break()
        case 'farming_method':
          _open_skillbook(@player, 'farming_method', null, @players_data, @skills_info, @text)
          break()
        case 'mining':
          if(array_size(@args) == 2) {
            @subpage = 0
          } else {
            @subpage = @args[2]
          }
          _open_skillbook(@player, 'mining', @subpage, @players_data, @skills_info, @text)
          break()
        }
        break()
      case 'select':
        switch(@args[1]) {
        case 'combat_method':
          @players_data[@uuid]['skill_manager'][2] = @args[2]
          cup_set('SKILL_MANAGER', @uuid, @players_data[@uuid]['skill_manager'])
          _reset_skill_effect(@uuid, 'combat_method')
          @level = @players_data[@uuid]['skill_data']['combat_method'][@args[2]][0]
          _set_skill_effect(@uuid, 'combat_method', @args[2], @level, @players_data, @skills_spec)
          _open_skillbook(@player, 'combat_method', null, @players_data, @skills_info, @text)
          break()
        case 'combat_inclination':
          _open_skillbook(@player, 'combat_inclination', @args[2], @players_data, @skills_info, @text)
          break()
        case 'harvesting_method':
          @players_data[@uuid]['skill_manager'][3] = @args[2]
          cup_set('SKILL_MANAGER', @uuid, @players_data[@uuid]['skill_manager'])
          _reset_skill_effect(@uuid, 'combat_method')
          @level = @players_data[@uuid]['skill_data']['harvesting_method'][@args[2]][0]
          _set_skill_effect(@uuid, 'harvesting_method', @args[2], @level, @players_data, @skills_spec)
          _open_skillbook(@player, 'farming_method', null, @players_data, @skills_info, @text)
          break()
        case 'sowing_method':
          @players_data[@uuid]['skill_manager'][4] = @args[2]
          cup_set('SKILL_MANAGER', @uuid, @players_data[@uuid]['skill_manager'])
          _reset_skill_effect(@uuid, 'combat_method')
          @level = @players_data[@uuid]['skill_data']['sowing_method'][@args[2]][0]
          _set_skill_effect(@uuid, 'sowing_method', @args[2], @level, @players_data, @skills_spec)
          _open_skillbook(@player, 'farming_method', null, @players_data, @skills_info, @text)
          break()
        }
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
        break()
      case 'unselect':
        switch(@args[1]) {
        case 'combat_method':
          @players_data[@uuid]['skill_manager'][2] = ''
          cup_set('SKILL_MANAGER', @uuid, @players_data[@uuid]['skill_manager'])
          _reset_skill_effect(@uuid, 'combat_method')
          _open_skillbook(@player, 'combat_method', null, @players_data, @skills_info, @text)
          break()
        case 'combat_inclination':
          _open_skillbook(@player, 'combat_inclination', @args[2], @players_data, @skills_info, @text)
          break()
        case 'harvesting_method':
          @players_data[@uuid]['skill_manager'][3] = ''
          cup_set('SKILL_MANAGER', @uuid, @players_data[@uuid]['skill_manager'])
          _reset_skill_effect(@uuid, 'combat_method')
          _open_skillbook(@player, 'farming_method', null, @players_data, @skills_info, @text)
          break()
        case 'sowing_method':
          @players_data[@uuid]['skill_manager'][4] = ''
          cup_set('SKILL_MANAGER', @uuid, @players_data[@uuid]['skill_manager'])
          _reset_skill_effect(@uuid, 'combat_method')
          _open_skillbook(@player, 'farming_method', null, @players_data, @skills_info, @text)
          break()
        }
        _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
        break()
      }
    } else {
      _open_skillbook(@player, 'combat', null, @players_data, @skills_info, @text)
    }
    
    /*
      
      if(array_size(@args) == 1) {
        switch(@args[0]) {
        case 'open_combat_inclination':
          _combat_inclination_page(@player, @player_skill_data, 0, @mastery_info, @text)
          break()
        case 'open_combat_method': 
          _open_skillbook(@player, 'combat_method', null, @players_data, @skills_info, @text)
          break()
        case 'open_farming_method': 
          _farming_method_page(@player, @player_skill_data, @mastery_info, @text)
          break()
        case 'open_sowing_method': 
          _sowing_method_page(@player, @player_skill_data, @mastery_info, @text)
          break()
        }
      } else if(array_size(@args) == 2) {
        switch(@args[0]) {
        case 'open_combat_inclination':
          _combat_inclination_page(@player, @player_skill_data, @args[1], @mastery_info, @text)
          break()
        }
      } else if(array_size(@args) >= 3) {
        @mastery = array_implode(array_get(@args, cslice(2, array_size(@args) - 1)), ' ')
        switch(@args[0]) {
        case 'select_combat_inclination':
          @players_data[@uuid]['skill']['skills_manager']['selected_combat_inclinations'][] = @mastery
          _combat_inclination_page(@player, @player_skill_data, @args[1], @mastery_info, @text)
          break()
        case 'unselect_combat_inclination':
          array_remove_values(@players_data[@uuid]['skill']['skills_manager']['selected_combat_inclinations'], @mastery)
          _combat_inclination_page(@player, @player_skill_data, @args[1], @mastery_info, @text)
          break()
        case 'select_combat_method':
          @players_data[@uuid]['skill']['skills_manager']['selected_combat_method'] = array(
            'name': @mastery
          )
          _combat_method_page(@player, @player_skill_data, @mastery_info, @text)
          break()
        case 'unselect_combat_method':
          @players_data[@uuid]['skill']['skills_manager']['selected_combat_method'] = null
          _combat_method_page(@player, @player_skill_data, @mastery_info, @text)
          break()
        case 'select_sowing_method':
          @players_data[@uuid]['skill']['skills_manager']['selected_sowing_method'] = array(
            'name': @mastery
          )
          _farming_method_page(@player, @player_skill_data, @mastery_info, @text)
          break()
        case 'unselect_sowing_method':
          @players_data[@uuid]['skill']['skills_manager']['selected_sowing_method'] = null
          _farming_method_page(@player, @player_skill_data, @mastery_info, @text)
          break()
        case 'select_harvesting_method':
          @players_data[@uuid]['skill']['skills_manager']['selected_harvesting_method'] = array(
            'name': @mastery
          )
          _farming_method_page(@player, @player_skill_data, @mastery_info, @text)
          break()
        case 'unselect_harvesting_method':
          @players_data[@uuid]['skill']['skills_manager']['selected_harvesting_method'] = null
          _farming_method_page(@player, @player_skill_data, @mastery_info, @text)
          break()
        }
      } else {
        
      }
    */
    #_open_masterybook(@player, @player_skill, @mastery_info, @text)
  }
))

proc _add_epxerience(@uuid, @skill, @skill_data, @add_experience) {
  if(@skill_data[0] < @skill_data[2]) {
    @new_experience = @skill_data[1] + @add_experience
    if(@new_experience < @skill_data[3]) {
      @skill_data[1] = @new_experience
    } else {
      @skill_data[0] += 1
      @skill_data[1] = 0
    }
    cup_set('SKILL_DATA', @uuid.'_'.@skill, @skill_data)
  }
}

proc _mineral_mine_event(@event, @player_item, @player_mining_skills, @hp_blocks) {
  @player = @event['player']
  @uuid = puuid(@player)
  @mineral = @event['block']
  @minerals_spec = array(                                                    #필요도구
    'COAL_ORE': array('hp': 8, 'hardness': 1, 'ore_selecting_xp': 1),        #나무
    'COPPER_ORE': array('hp': 20, 'hardness': 2, 'ore_selecting_xp': 2),     #돌, 금
    'IRON_ORE': array('hp': 35, 'hardness': 3, 'ore_selecting_xp': 4),       #구리
    'LAPIS_ORE': array('hp': 23, 'hardness': 3, 'ore_selecting_xp': 5),      #구리
    'GOLD_ORE': array('hp': 23, 'hardness': 4, 'ore_selecting_xp': 7),       #철
    'REDSTONE_ORE': array('hp': 35, 'hardness': 4, 'ore_selecting_xp': 5),   #철
    'DIAMOND_ORE': array('hp': 47, 'hardness': 4, 'ore_selecting_xp': 15),   #철
    'EMERALD_ORE': array('hp': 47, 'hardness': 4, 'ore_selecting_xp': 10),   #철
    'ANCIENT_DEBRIS': array('hp': 70, 'hardness': 5, 'ore_selecting_xp': 50) #다이야
  )
  @pickaxes_hardness = array(          # 캘수있는 광물
    'WOODEN_PICKAXE': 1,   #나무         (석탄)
    'GOLDEN_PICKAXE': 2,   #돌,금        (석탄, 구리)
    'STONE_PICKAXE': 3,    #구리         (석탄, 구리, 청금석, 철)
    'IRON_PICKAXE': 4,     #철           (석탄, 구리, 청금석, 철, 금, 레드스톤, 다이아)
    'DIAMOND_PICKAXE': 5,  #다이아       (석탄, 구리, 청금석, 철, 금, 레드스톤, 다이아, 고대파편)
    'NETHERITE_PICKAXE': 6 #네더라이트   (석탄, 구리, 청금석, 철, 금, 레드스톤, 다이아, 고대파편)
  )
  @pickaxe_hardness = 0
  @mining_power = 0
  if(!is_null(@player_item['main_hand']) && array_contains(array_keys(@pickaxes_hardness), @player_item['main_hand']['name'])) {
    @pickaxe_hardness = @pickaxes_hardness[@player_item['main_hand']['name']]
    if(!is_null(@player_item['main_hand']['meta'])) {
      if(@pickaxe_hardness == 0 && @player_item['main_hand']['meta']['model'] >= 8) {
        @pickaxe_hardness = 2
      }
      if(array_index_exists(@player_item['main_hand']['meta'], 'modifiers')) {
        foreach(@modifier in @player_item['main_hand']['meta']['modifiers']) {
          if(@modifier['attribute'] == 'HORSE_JUMP_STRENGTH') {
            @mining_power = @modifier['amount'] * (1 + @player_mining_skills['tough_shoulder'][0] * 0.1)
            #broadcast(@mining_power)
            break()
          }
        }
      }
    }
  }
  @location = @event['location']
  @drop_items = array()
  @id = array_implode(array(integer(@location['x']), integer(@location['y']), integer(@location['z']), @location['world']), '.')
  @max_hp = @minerals_spec[@mineral]['hp']
  if(@pickaxe_hardness >= @minerals_spec[@mineral]['hardness']) {
    if(!array_index_exists(@hp_blocks, @id)) {
      @hp_blocks[@id] = array(
        'name': @mineral,
        'hp': @minerals_spec[@mineral]['hp'],
        'reset_countdown': 3
      )
    } else if(@hp_blocks[@id]['name'] != @mineral) {
      @hp_blocks[@id] = array(
        'name': @mineral,
        'hp': @minerals_spec[@mineral]['hp'],
        'reset_countdown': 3
      )
    }
    @hp_blocks[@id]['hp'] -= @mining_power
    if(@hp_blocks[@id]['hp'] < 0) { @hp_blocks[@id]['hp'] = 0 }
    @hp_blocks[@id]['reset_countdown'] = 3
    @hp = @hp_blocks[@id]['hp']
    if(@hp_blocks[@id]['hp'] > 0) {
      cancel()
      @item = @player_item['main_hand']
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
          set_inventory_item(puuid(@player), @slot, null)
        } else {
          set_inventory_item(puuid(@player), @slot, @item)
        }
      }
    } else {
      array_remove(@hp_blocks, @id)
      play_named_sound(@location, array(
         'sound': 'minecraft:entity.player.levelup',
         'category': 'PLAYERS',
         'volume': 0.4,
         'pitch': 1.5
      ), @player)
      @multiply = @player_mining_skills['tough_shoulder'][0] + 0 #아이템에 행운이 있을시 + 1 축복이 있을시 + 2
      @alpha_qty = 1 + @multiply
      @is_normal_mineral = false
      switch(@mineral) {
      case 'REDSTONE_ORE':
        @drop_item = 'REDSTONE'
        @is_normal_mineral = true
        @alpha_qty = 5 + @multiply
        break()
      case 'LAPIS_ORE':
        @drop_item = 'LAPIS_LAZULI'
        @is_normal_mineral = true
        @alpha_qty = 5 + @multiply
        break()
      case 'COAL_ORE':
        @drop_item = 'COAL'
        @is_normal_mineral = true
        break()
      case 'EMERALD_ORE':
        @drop_item = 'EMERALD'
        @is_normal_mineral = true
        break()
      case 'COPPER_ORE':
        @drop_item = 'IRON_NUGGET'
        _add_epxerience(@uuid, 'copper_mining_mastery'. @player_mining_skills['copper_mining_mastery'], 1)
        @mastery_level = @player_mining_skills['copper_mining_mastery'][0]
        @display = '구리 주괴'
        break()
      case 'IRON_ORE':
        @drop_item = 'IRON_INGOT'
        _add_epxerience(@uuid, 'iron_mining_mastery', @player_mining_skills['iron_mining_mastery'], 1)
        @mastery_level = @player_mining_skills['iron_mining_mastery'][0]
        @display = '철괴'
        break()
      case 'GOLD_ORE':
      case 'NETHER_GOLD_ORE':
        @drop_item = 'GOLD_INGOT'
        _add_epxerience(@uuid, 'gold_mining_mastery', @player_mining_skills['gold_mining_mastery'], 1)
        @mastery_level = @player_mining_skills['gold_mining_mastery'][0]
        @display = '금괴'
        break()
      case 'DIAMOND_ORE':
        @drop_item = 'DIAMOND'
        _add_epxerience(@uuid, 'diamond_mining_mastery', @player_mining_skills['diamond_mining_mastery'], 1)
        @mastery_level = @player_mining_skills['diamond_mining_mastery'][0]
        @display = '다이아몬드'
        break()
      case 'ANCIENT_DEBRIS':
        @drop_item = 'NETHERITE_SCRAP'
        _add_epxerience(@uuid, 'ancient_debris_mining_mastery', @player_mining_skills['ancient_debris_mining_mastery'], 1)
        @mastery_level = @player_mining_skills['ancient_debris_mining_mastery'][0]
        @display = '네더라이트 파편'
        break()
      }
      if(@is_normal_mineral) {
        @qty = 1 + integer(rand() * @alpha_qty)
        @location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
        drop_item(@location, array('name': @drop_item, 'qty': @qty), false)
      } else {
        @qty = 1 + integer(rand() * @alpha_qty)
        @entries = array(
          array(
            'rank': '§f하급',
            'model': 1,
            'weight': 100 + 0 * @mastery_level
          ),
          array(
            'rank': '§e중급',
            'model': 2,
            'weight': 20 + 1 * @mastery_level
          ),
          array(
            'rank': '§b상급',
            'model': 3,
            'weight': 5 + 0.5 * @mastery_level
          ),
          array(
            'rank': '§d최상급',
            'model': 4,
            'weight': 0.5 + 0.1 * @mastery_level
          )
        )
        @total_weight = 0
        foreach(@key: @entry in @entries) {
          @total_weight += @entry['weight']
        }
        for(@i = 0, @i < @qty, @i++){
          @result_weight = @total_weight * round(rand(), 5)
          @min_weight = 0
          foreach(@entry in @entries) {
            @weight = @entry['weight']
            @max_weight = @min_weight + @weight
            if(@max_weight > @result_weight) {
              @location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
              drop_item(@location, array('name': @drop_item, 'meta': array('display': @entry['rank'] @display, 'model': @entry['model'])), false)
              break()
            } else {
              @min_weight = @max_weight
            }
          }
        }
      }
      _add_epxerience(@uuid, 'ore_selecting', @player_mining_skills['ore_selecting'], @minerals_spec[@mineral]['ore_selecting_xp'])
      #_add_epxerience(@player_mining_skills['tough_shoulder'], 1) #돌 캘시 이벤트로 이동# 돌을 캘시, 곡괭이로 전투 시 숙련도 상승
    }
  } else {
    if(array_index_exists(@hp_blocks, @id)) {
      @hp = @hp_blocks[@id]['hp']
    } else {
      @hp = @minerals_spec[@mineral]['hp']
    }
    cancel()
  }
  modify_event('drops', array())
  #경험 인첸트에 따른 경험치 드랍 조절
}

proc _farmland_sow_event(@event, @player_item, @player_farming_skills, @sowing_method_skills, @hp_blocks) {
  @player = @event['player']
  @block = @event['block']
  @hoes_cooldown = array(
    'WOODEN_HOE': 40, #30
    'STONE_HOE': 28, #21
    'IRON_HOE': 20, #15
    'DIAMOND_HOE': 12, #9
    'NETHERITE_HOE': 8, #6
    'GOLDEN_HOE': 4 #3
  )
  @location = array('x': @event['location']['x'], 'y': @event['location']['y'], 'z': @event['location']['z'], 'world': @event['location']['world'])
  if(@event['hand'] == 'main_hand') {
    @slot = pheld_slot(@player)
  } else {
    @slot = 40
  }
  @item = @player_item[@event['hand']]
  if(pcooldown(@player, @item['name']) == 0) {
    #효율 인첸트가 되어있을시 쿨타임 * 0.75
    foreach(@hoe:@hoe_cooldown in @hoes_cooldown) {
      if(@hoe_cooldown > @hoes_cooldown[@item['name']]) {
        set_pcooldown(@player, @hoe, @hoe_cooldown)
        #40 28
      } else {
        set_pcooldown(@player, @hoe, @hoes_cooldown[@item['name']]) #효율 인첸트 존재시 쿨타임 감소
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
      # @hp를 HUB에 표시
      cancel()
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
          #변수상 아이템 설정
        } else {
          set_inventory_item(puuid(@player), @slot, @item)
        }
      }
    } else {
      @hp = 0
      # @hp를 HUB에 표시
    }
  }
}


/*
bind('block_break', array('id': 'mastery.mining'), null, @e, @minerals, @pickaxes) {
   @player = @e['player']
   @location = @e['location']
   @allow_worlds = array('world')
   if(!array_contains(@allow_worlds, @location['world']), exit())
   @mineral_name = @e['block']
   if(!array_index_exists(@minerals, @mineral_name), exit())
   @progress_id = array_implode(@location, '.')
   @mineral_spec = @minerals[@mineral_name]
   @player_progress = _get_progress(@player)
   @drop_items = array()
   if(!array_index_exists(@player_progress, @progress_id)) { ## 아직 캐보지 않은 곳일 경우
      @player_progress[@progress_id] = array(
         'mineral_name': @mineral_name,
         'health': @mineral_spec['health']
      )
   }
   @here_progress = @player_progress[@progress_id]
   if(@here_progress['mineral_name'] != @mineral_name) { ###
      modify_event('xp', 0)
      set_timeout(0, closure() {
         set_block(@location, @mineral_name)
      })
      @player_progress[@progress_key] = array(
         'mineral_name': @mineral_name,
         'health': @mineral_spec['health']
      )
      _set_value(@progress)
      exit()
   }
   @held_item = pinv(@player, null)
   @pickaxe_hardness = 0
   @breakble = 0
   @mining_power = 1.0
   if(@held_item && array_index_exists(@pickaxes, @held_item['name'])) {
      if(@held_item['meta'] && array_index_exists(@held_item['meta'], 'modifiers')) {
         foreach(@modifier in @held_item['meta']['modifiers']) {
            if(@modifier['attribute'] == 'HORSE_JUMP_STRENGTH') {
               @mining_power = @modifier['amount']
               break()
            }
         }
      }
      @pickaxe_hardness = @pickaxes[@held_item['name']]
   }
   if(@pickaxe_hardness >= @mineral_spec['hardness']) { ## 곡괭이가 광물 수준에 맞을 경우
      @breakble = 1
   }
   #@masteries = _get_value(@player)
   #@experiences = @masteries['EXPERIENCE']
   @mineral_damage = (@breakble * @mining_power)
   #@mineral_damage = (@breakble * @mining_power + @breakble * @mining_power * (1 + (@experiences['MINER_SKILL'] * 2)) / 100)

   @mineral_max_health = @minerals[@mineral_name]['health']
   @mineral_health = integer(@here_progress['health'] - @mineral_damage)
   @here_progress['health'] = @mineral_health
   @progress_text
   if(@mineral_health <= 0) {
      @mineral_health = 0
      play_named_sound(@location, array(
         'sound': 'minecraft:entity.player.levelup',
         'category': 'PLAYERS',
         'volume': 0.4,
         'pitch': 1.5
      ), @player)
      array_remove(@player_progress, @progress_id)
      @progress_text = ''

      @use_ability_name = (split('_', @mineral_name)[0].'_MINING')
      @drop_items = _get_rank_mineral(@mineral_name, 3, 0)
      #if(array_index_exists(@experiences, @use_ability_name)) {
      #   @mining_level = _get_ability_level(@player, @use_ability_name)
      #   @ore_selecting_level = _get_ability_level(@player, 'ORE_SELECTING')
      #   @drop_items = _get_rank_mineral(@mineral_name, @mining_level, @ore_selecting_level)
      #   _add_mastery(@player, @use_ability_name, @rewards['MINERALS'][@mineral_name])
      #}
   } else {
      modify_event('xp', 0)
      set_timeout(0, closure() {
         set_block(@location, @mineral_name)
      })
   }
   _set_progress(@player, @player_progress)
   @progress_text_multiple = integer(@mineral_health / @mineral_max_health * 50)
   if(@mineral_health > 0) {
      @progress_text = '§9'.string_multiply('', @progress_text_multiple).string_multiply('', @progress_text_multiple) '§9'.string_multiply('', @progress_text_multiple).string_multiply('', @progress_text_multiple)
   }
   action_msg(@player, @progress_text)
   modify_event('drops', @drop_items)
}
*/
/*
bind('block_break', null, null, @event) {
  @player = @event['player']
  if(array_contains(array('WHEAT', 'CARROTS', 'POTATOS', 'BEETROOTS'), @event['block']) && array_contains(array('SURVIVAL', 'ADVENTURE'), pmode(@player))) {
    @slot = pheld_slot(@player)
    @item = get_inventory_item(puuid(@player), @slot)
    if(!is_null(@item) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @item['name'])) {
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
        if(material_info(@item['name'], 'maxDurability') <= @item['meta']['damage']) {
          play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
          set_inventory_item(puuid(@player), @slot, null)
        } else {
          set_inventory_item(puuid(@player), @slot, @item)
        }
      }
      @skill_mode = import('farming_skill')
      @location = @event['location']
      switch(@skill_mode) {
      case 'golden_finger':
        if(array_contains(array('WHEAT', 'CARROTS', 'POTATOS'), @event['block'])) {
          @max_age = 7
        } else {
          @max_age = 3
        }
        if(get_blockdata(@location)['age'] == @max_age) {
          @drops = @event['drops']
          array_remove(@drops, 0)
          modify_event('drops', @drops)
          set_timeout(0, closure() { set_block(@location, @event['block']) })
        } else {
          cancel()
        }
        break()
      case 'wide_hand':
        for(@x = -1, @x < 2, @x++) {
          for(@z = -1, @z < 2, @z++) {
            if(@x != 0 || @z != 0) {
              @breaking_location = array('x': @location['x'] + @x, 'y': @location['y'], 'z': @location['z'] + @z, 'world': @location['world'])
              if(array_contains(array('WHEAT', 'CARROTS', 'POTATOS'), @event['block'])) {
                @max_age = 7
              } else {
                @max_age = 3
              }
              if(get_block(@breaking_location) == @event['block'] && get_blockdata(@breaking_location)['age'] == @max_age) {
                @item = get_inventory_item(puuid(@player), @slot)
                if(!is_null(@item) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @item['name'])) {
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
                    if(material_info(@item['name'], 'maxDurability') <= @item['meta']['damage']) {
                      play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
                      set_inventory_item(puuid(@player), @slot, null)
                    } else {
                      set_inventory_item(puuid(@player), @slot, @item)
                    }
                  }
                  sudo(player(), '/loot spawn' @breaking_location['x'] + 0.5 @breaking_location['y'] @breaking_location['z'] + 0.5 'mine' integer(@breaking_location['x']) integer(@breaking_location['y']) integer(@breaking_location['z']) 'mainhand')
                  set_block(@breaking_location, 'AIR')
                }
              }
            }
          }
        }
        break()
      default:
        break()
      }
    }
    
  }
}






/*
bind('player_join', array('id': 'mastery.fishing.setup'), null, @event) {
  @player = @event['player']
  @fishing_data = array(
  )
  #bind('player_fish', array('id': 'mastery.fishing.reel_out.'.@player), array('player': @player, 'state': 'FISHING'), @event, @player, @fishing_data)
  bind('player_fish', array('id': 'mastery.fishing.bite.'.@player), array('player': @player, 'state': 'BITE'), @event, @player, @fishing_data) {
    cancel()
    set_interval(100, closure() {
      if(!ponline(@player)) {
        clear_task()
        if(has_bind('mastery.fishing.reel_out.'.@player)) { unbind('mastery.fishing.reel_out.'.@player) }
        if(has_bind('mastery.fishing.caught_fish.'.@player)) { unbind('mastery.fishing.reel_in.'.@player) }
        if(has_bind('mastery.fishing.bite.'.@player)) { unbind('mastery.fishing.bite.'.@player) }
      } else {
        @hook = @event['hook']
        if(!entity_exists(@hook)) {
          clear_task()
          if(has_bind('mastery.fishing.caught_fish.'.@player)) { unbind('mastery.fishing.caught_fish.'.@player) }
          if(has_bind('mastery.fishing.bite.'.@player)) { unbind('mastery.fishing.bite.'.@player) }
          #entity_remove(@fishing_players[@player]['armor_stand']) ### 추가 상황에서도 아머스탠드 제거 해줘야 함 (낚시중 서버 꺼져서 아머스탠드가 살아 있을수도 있음)
          #array_remove(@fishing_players, @player) #데이터 초기화
          stop_named_sound(@player, 'entity.fishing_bobber.splash', 'NEUTRAL')
          stop_named_sound(@player, 'entity.entity.player.swim', 'NEUTRAL')
          stop_named_sound(@player, 'entity.entity.player.splash', 'NEUTRAL')
          stop_named_sound(@player, 'entity.item.crossbow.quick_charge_3', 'NEUTRAL')
        } else {
          @hook_location = entity_loc(@hook)
          @hook_location['y'] += 0.125
          @player_location = ploc(@player)
          if(psneaking(@player)) { @y_adjustment = 2.255 } else { @y_adjustment = 2.625 }
          @player_location['y'] += @y_adjustment
          @magnitude = distance(@hook_location, @player_location)
          @vector = ('x': (@hook_location['x'] - @player_location['x']) / @magnitude, 'y': (@hook_location['y'] - @player_location['y']) / @magnitude, 'z': (@hook_location['z'] - @player_location['z']) / @magnitude)
          @rotating_yaw = get_yaw(@player_location, @hook_location)
          @rotating_pitch = get_pitch(@player_location, @hook_location)
          #
          if(@rotating_yaw < 180) {
            if(@player_location['yaw'] > @rotating_yaw && @player_location['yaw'] < @rotating_yaw + 180) {
              @leaning = 'right'
            } else {
              @leaning = 'left'
            }
          } else {
            @opposite_yaw = @rotating_yaw - 180
            if(@player_location['yaw'] < @rotating_yaw && @player_location['yaw'] > @rotating_yaw - 180) {
              @leaning = 'left'
            } else {
              @leaning = 'right'
            }
          }

          if(@leaning == 'left') {
            @new_yaw = @player_location['yaw'] + 0.1
          } else {
            @new_yaw = @player_location['yaw'] - 0.1
          }
          #
          #action_msg(@player, '내_yaw' round(@player_location['yaw'], 2) '위치기준 yaw' round(@rotating_yaw, 2) '좌우 회전 중심'round(@opposite_yaw, 2) @a)
          #relative_teleport(puuid(@player), array('x': ploc()[x], 'y': ploc()[y] + 1, 'z': ploc()[z], 'world':  ploc()['world'], 'yaw': @new_yaw, 'pitch': get_pitch(@player_location, @hook_location)))
        }
        
      }
    })
  }
}
*/
/*
@fishings = array()
bind('player_fish', null, array('state': 'BITE'), @event, @fishings) {
  @player = @event['player']
  @hook = @event['hook']
  @player_location = ploc(@player)
  @hook_location = entity_loc(@hook)
  @direction = array_rand(array(array('left', -90), array('right', 90)), 1, false)[0]
  @moving_yaw = get_yaw(@player_location, @hook_location) + @direction[1]
  @moving_vector = get_vector(array('yaw': @moving_yaw, 'pitch': 0), 0.2)
  play_named_sound(@hook_location, array('sound': 'entity.player.splash', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1 + rand() / 2))
  play_named_sound(@hook_location, array('sound': 'entity.fishing_bobber.splash', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 0.85 + rand() / 2))
  play_named_sound(@player_location, array('sound': 'entity.player.splash', 'category': 'NEUTRAL', 'volume': 0.05, 'pitch': 1 + rand() / 2), @player)
  play_named_sound(@player_location, array('sound': 'entity.fishing_bobber.splash', 'category': 'NEUTRAL', 'volume': 0.05, 'pitch': 0.85 + rand() / 2), @player)
  set_entity_velocity(@hook, @moving_vector)
  if(!array_index_exists(@fishings, @player)) {
    @hook_location['yaw'] = 0.0
    @fishings[@player] = array(
      'armor_stand': spawn_entity('ARMOR_STAND', 1, @hook_location, closure(@uuid) { set_entity_spec(@uuid, array('visible': false, 'small': true, 'marker': true, 'poses': array('poseHead': @moving_vector))) set_entity_rider(@hook, @uuid) set_mob_equipment(@uuid, array('HELMET': array('name': 'LEATHER_HORSE_ARMOR', 'meta': array('model': 1)))) })[0],
      'direction': @direction[0]
    )
    
    bind('player_interact', array('id': 'mastery.fishing.click.'.@player), array('player': @player, 'hand': 'main_hand', 'itemname': 'FISHING_ROD', 'button': 'right'), @event, @fishings, @player, @hook) {
      cancel()
      @player_location = ploc(@player)
      @hook_location = entity_loc(@hook)
      @relative_yaw = get_yaw(@player_location, @hook_location)
      if(@relative_yaw < 180) {
        if(@player_location['yaw'] > @relative_yaw && @player_location['yaw'] < @relative_yaw + 180) {
          @leaning = 'right'
        } else {
          @leaning = 'left'
        }
      } else {
        if(@player_location['yaw'] < @relative_yaw && @player_location['yaw'] > @relative_yaw - 180) {
          @leaning = 'left'
        } else {
          @leaning = 'right'
        }
      }
      if(@fishings[@player]['direction'] == 'left') {
        if(@leaning == 'left') {
          @moving_yaw = @relative_yaw - 90
          @draw = false
        } else {
          @moving_yaw = @relative_yaw + 90
          @draw = true
        }
      } else {
        if(@leaning == 'left') {
          @moving_yaw = @relative_yaw - 90
          @draw = true
        } else {
          @moving_yaw = @relative_yaw + 90
          @draw = false
        }
      }
      if(@draw) {
        @magnitude = 0.2 + 0.4 * rand()
        play_named_sound(@player_location, array('sound': 'item.crossbow.quick_charge_3', 'category': 'PLAYERS', 'volume': 0.8, 'pitch': 0.5 + rand() / 2))
        play_named_sound(@player_location, array('sound': 'item.crossbow.quick_charge_3', 'category': 'PLAYERS', 'volume': 0.8, 'pitch': 0.5 + rand() / 2), @player)
      } else {
        @magnitude = 0.5 + rand()
        play_named_sound(@player_location, array('sound': 'entity.fishing_bobber.retrieve', 'category': 'PLAYERS', 'volume': 1, 'pitch': 0.3 + rand() / 2))
        play_named_sound(@player_location, array('sound': 'entity.fishing_bobber.retrieve', 'category': 'PLAYERS', 'volume': 1, 'pitch': 0.3 + rand() / 2), @player)
      }
      @moving_vector = get_vector(array('yaw': @moving_yaw, 'pitch': 0), @magnitude)
      set_entity_velocity(@hook, @moving_vector)
    }
    @direction = array_rand(array(array('left', -90), array('right', 90)), 1, false)[0]
    @int = array(0)
    set_interval(100, closure() {
      if(!entity_exists(@hook)) {
        if(has_bind('mastery.fishing.click.'.@player)) { unbind('mastery.fishing.click.'.@player) }
        if(entity_exists(@fishings[@player]['armor_stand'])) { entity_remove(@fishings[@player]['armor_stand']) } ### 추가 상황에서도 아머스탠드 제거 해줘야 함 (낚시중 서버 꺼져서 아머스탠드가 살아 있을수도 있음)
        array_remove(@fishings, @player)
        stop_named_sound(@player, 'entity.fishing_bobber.splash', 'NEUTRAL')
        stop_named_sound(@player, 'entity.entity.player.swim', 'NEUTRAL')
        stop_named_sound(@player, 'entity.entity.player.splash', 'NEUTRAL')
        stop_named_sound(@player, 'entity.item.crossbow.quick_charge_3', 'NEUTRAL')
        if(has_bind('mastery.fishing.click.'.@player)) { unbind('mastery.fishing.click.'.@player) }
        clear_task()
      } else {
        @player_location = ploc()
        @hook_location = entity_loc(@hook)
        
        set_timeout(integer(rand() * 100), closure() {
          if(rand() > 0.95) {
            @direction = array_rand(array(array('left', -90), array('right', 90)), 1, false)[0]
            @fishings[@player]['direction'] = @direction[0]
            @moving_yaw = get_yaw(@player_location, @hook_location) + @direction[1]
            @moving_vector = get_vector(array('yaw': @moving_yaw, 'pitch': 0), 0.2)
            @moving_vector['y'] = - 0.1 - 0.2 * rand()
            set_entity_velocity(@hook, @moving_vector)
            ###
            play_named_sound(@hook_location, array('sound': 'entity.player.splash', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1 + rand() / 2))
            play_named_sound(@hook_location, array('sound': 'entity.fishing_bobber.splash', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 0.85 + rand() / 2))
            play_named_sound(@player_location, array('sound': 'entity.player.splash', 'category': 'NEUTRAL', 'volume': 0.05, 'pitch': 1 + rand() / 2), @player)
            play_named_sound(@player_location, array('sound': 'entity.fishing_bobber.splash', 'category': 'NEUTRAL', 'volume': 0.05, 'pitch': 0.85 + rand() / 2), @player)
            
          } else {
            @direction = @fishings[@player]['direction']
            if(@direction == 'left') { @moving_yaw = get_yaw(@player_location, @hook_location) - 90 } else { @moving_yaw = get_yaw(@player_location, @hook_location) + 90 }
            @moving_vector = get_vector(array('yaw': @moving_yaw, 'pitch': 0), 0.04 * rand())
            if(rand() > 0.9) { @moving_vector['y'] = -0.2 * rand()}
            set_entity_velocity(@hook, @moving_vector)
            @int[0] += 0.05
            set_entity_spec(@fishings[@player]['armor_stand'], array('poses': array('poseHead': array('x': 0, 'y': @moving_yaw / 60, 'z': 0))))
            #action_msg(@int[0] '|' entity_spec(@fishings[@player]['armor_stand'])['poses']['poseHead']['x'] entity_spec(@fishings[@player]['armor_stand'])['poses']['poseHead']['y'] entity_spec(@fishings[@player]['armor_stand'])['poses']['poseHead']['z'])
          }
        })
        if(rand() > 0.7) {
          spawn_particle(@hook_location, 'WATER_BUBBLE')
          play_named_sound(@hook_location, array('sound': 'entity.player.swim', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1 + rand() / 2))
          play_named_sound(@player_location, array('sound': 'entity.player.swim', 'category': 'NEUTRAL', 'volume': 0.08, 'pitch': 1 + rand() / 2), @player)
        }
        @hook_location['y'] += 0.2
        spawn_particle(@hook_location, 'WATER_SPLASH')
        spawn_particle(@hook_location, 'WATER_SPLASH')
        spawn_particle(@hook_location, 'WATER_SPLASH')
        spawn_particle(@hook_location, 'WATER_SPLASH')
        spawn_particle(@hook_location, 'WATER_SPLASH')
        #@fishing_players[@player]['player_location']['yaw'] - ploc(@player)['yaw']
        #@fishing_players[@player]['player_location']['pitch'] - ploc(@player)['pitch']
        #action_msg(@player, @fishing_players[@player]['player_location']['yaw'] - ploc(@player)['yaw'] @fishing_players[@player]['player_location']['pitch'] - ploc(@player)['pitch'])
        #relative_teleport(@player, array(yaw: 1, pitch: 0))
        #set_entity_rotation(puuid(@player), 0, 1)
        #set_entity_velocity(@hook, array('x': 0.05, 'y': 0, 'z': 0))
      }
    })
  } else {
    @fishings[@player]['direction'] = @direction[0]
  }
}

*/
  #@hook_location['y'] -= 0.8
  #@fishing_array = array(
  #  'dummy_item': drop_item(@hook_location, array('name': 'STONE'), false),
  #  'dummy_armorstand': spawn_entity('ARMOR_STAND', 1, @hook_location, closure(@uuid) { set_entity_spec(@uuid, array('visible': false, 'small': true)) })[0]
  #)
  #set_timeout(1, closure() {
  #  set_entity_rider(@fishing_array['dummy_item'], @fishing_array['dummy_armorstand'])
  #  set_entity_rider(@fishing_array['dummy_armorstand'], @hook)
  #})
  #@dummy_item = drop_item(@hook_location, array('name': 'STONE'), false)
  #spawn_entity('ARMOR_STAND', 1, @hook_location, closure(@dummy_armorstand) {
    #set_entity_spec(@dummy_armorstand, array('visible': false, 'small': true))
    #set_entity_rider(@dummy_item, @dummy_armorstand)
    #set_entity_rider(@dummy_armorstand, @hook)
  #})
  #@hook_vector = entity_velocity(@hook)
  #@fishing_array = array('is_ready': false, 'uuids': array('hook': @hook, 'dummy_item': null, 'dummy_armorstand': null))
  #set_interval(200, closure() {
    #if(!entity_exists(@hook)) {
      #clear_task()
    #} else {
      #if(@fishing_array['is_ready']) {
        #@hook_vector = entity_velocity(@hook)
        #@hook_location = entity_loc(@hook)
        #@under_block = get_block(@hook_location)
        #@hook_location['y'] += 0.25
        #@upper_block = get_block(@hook_location)

        #if(!@fishing_array['is_ready'] && @under_block == 'WATER' && @upper_block != 'WATER' && @hook_vector['magnitude'] < 0.1 && @hook_vector['x'] < 0.1 && @hook_vector['x'] < 0.1) {
        #  @fishing_array['is_ready'] = true
        #  #set_entity_loc(@hook, entity_loc(@hook))
        #  @dummy_item = drop_item(@hook_location, array('name': 'STONE'), false)

          
        #}
        #action_msg(@player, '던져지는 중' @fishing_array)
      #} else {
        #action_msg(@player, '안착' @fishing_array)
        #set_entity_velocity(@hook, array('x': 0, 'y': rand() / 5 * -1, 'z': 0))
      #}
    #}
  #})
  #@target_location = location_shift(@hook_location, @hook_vector)
  #broadcast(@target_location)
  #broadcast(round(@hook_location['x'], 3) round(@hook_location['y'], 3) round(@hook_location['z'], 3))
  #broadcast(round(@target_location['x'], 3) round(@target_location['y'], 3) round(@target_location['z'], 3))
  #shoot_projectile(player(), 'ARMOR_STAND', @target_location)
  #broadcast(a)
  #@uuid = drop_item(@hook_location, array('name': 'STONE'), false)
  #spawn_entity('PIG', 1, @hook_location, closure(@uuid) {
    #broadcast(@uuid)
    #set_timeout(100, closure() {
    #  broadcast(entity_spec(@uuid))
    #})
    #set_entity_spec(@uuid, array('pickupdelay': '-100'))
    #broadcast(entity_spec(@uuid))
    #set_entity_silent(@uuid, true)
    #set_can_pickup_items(@uuid, false)
    #set_entity_ai(@uuid, false)
    #set_mob_age(@uuid, -1, ture)
    #set_entity_velocity(@uuid, @hook_vector)
  #})

#include_dir('includes', true)

######################################################################################


