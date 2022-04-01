@ch_items = json_decode(comp_read("items.json"))

proc _give_item_random_qty(@player, @category, @ch_item_name, @default_qty, @extra_qty, @ch_items) {
  if(array_index_exists(@ch_items, @category, @ch_item_name)) {
    @item = @ch_items[@category][@ch_item_name]
    @qty = integer(round(@default_qty + rand() * @extra_qty))
    if(@qty < 0) { @qty = 0 }
    @item['qty'] = @qty
    @item['qty'] = pgive_item(@player, @item)
    if(@item['qty'] > 0) { drop_item(@player, @item) }
    return(@qty)
  } else {
    return(0)
  }
}

proc _drop_item_random_qty(@location, @category, @ch_item_name, @default_qty, @extra_qty, @ch_items) {
  if(array_index_exists(@ch_items, @category, @ch_item_name)) {
    @item = @ch_items[@category][@ch_item_name]
    @qty = integer(round(@default_qty + rand() * @extra_qty))
    if(@qty < 0) { @qty = 0 }
    @item['qty'] = @qty
    if(@qty > 0) {
      drop_item(@location, @item)
      return(@item)
    } else {
      return(null)
    }
  } else {
    return(null)
  }
}

register_command('giveitemrand', array(
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) == 5) {
      @target_name = @args[0]
      @target_uuid = puuid(@target_name)
      @category = @args[1]
      @ch_item_name = @args[2]
      @default_qty = double(@args[3])
      @extra_qty = double(@args[4])
      @qty = _give_item_random_qty(@target_name, @category, @ch_item_name, @default_qty, @extra_qty, @ch_items)
      if(@qty > 0) {
        @item = @ch_items[@category][@ch_item_name]
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = @item['meta']['display']
        } else {
          @item_name = @item['name']
        }
        @prefix = @text['prefix']['success']
        if(@qty == 1) {
          tmsg(@target_name, "@prefix @item_name§f를 받았습니다")
        } else {
          tmsg(@target_name, "@prefix @item_name§7(x@qty)§f를 받았습니다")
        }
      }
    }
  }
))

register_command('giveitemone', array(
  permission: 'giveitemone',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) > 2) {
      @target_name = @args[0]
      @target_uuid = puuid(@target_name)
      @category = @args[1]
      @ch_item_name = array_implode(array_get(@args, cslice(2, array_size(@args) - 1)), ' ')
      //broadcast(@ch_item_name)
      if(array_index_exists(@ch_items, @category, @ch_item_name)) {
        pgive_item(@target_name, @ch_items[@category][@ch_item_name])
      }
      /*
      @default_qty = double(@args[3])
      @extra_qty = double(@args[4])
      @qty = _give_item_random_qty(@target_name, @category, @ch_item_name, @default_qty, @extra_qty, @ch_items)
      if(@qty > 0) {
        @item = @ch_items[@category][@ch_item_name]
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = @item['meta']['display']
        } else {
          @item_name = @item['name']
        }
        @prefix = @text['prefix']['success']
        if(@qty == 1) {
          tmsg(@target_name, "@prefix @item_name§f를 받았습니다")
        } else {
          tmsg(@target_name, "@prefix @item_name§7(x@qty)§f를 받았습니다")
        }
      }
       */
    }
  }
))


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
      //@applying_skills[@selected_rune] = @applying_skill_data
    }
  }
  # 기타 (서브 컴뱃 처럼 전투 방식, 룬은 아니면서 아이템(도구,무기)에 영향 미칠 스킬들)
  @extra_skills = array(
    'bow_mastery',
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
      @applying_skills[@extra_skill] = @applying_skill_data
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

        # 기타 적용
        if(@item['name'] == 'SHIELD') {
          @unbreaking = 0
          if(array_index_exists(@item, 'meta', 'model')) {
            switch(@item['meta']['model']) {
            case 0: // 구리
            case 1:
              @unbreaking = 3.1
              break()
            case 2: // 철
            case 3:
              @unbreaking = 6.8
              break()
            case 4: // 금
            case 5:
              @unbreaking = 0
              break()
            case 6: // 다이아
            case 7:
              @unbreaking = 47.8
              break()
            case 8: // 네더라이트
            case 9:
              @unbreaking = 62.5
              break()
            }
          }
          @vanilla_enchants['unbreaking'] = array(
            'etype': 'DURABILITY',
            'elevel': @unbreaking
          )
        }

        # 스킬 적용
        foreach(@applying_skill: @applying_skill_data in @applying_skills) {
          @skill_spec = @applying_skill_data['skill_spec']
          @point = @applying_skill_data['point']
          @proc_name = @applying_skill_data['proc_name']
          call_proc(@proc_name, @player_data, @player, @uuid, @applying_skill, @skill_spec, @point, @item, @vanilla_enchants)
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
              if(array_index_exists(@vanilla_enchants, 'unbreaking')) {
                @vanilla_enchants['unbreaking']['elevel'] *= 3
              } else {
                @vanilla_enchants['unbreaking'] = array(
                  'etype': 'DURABILITY',
                  'elevel': 3
                )
              }
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

        # 내구성 인첸 소수점 처리
        if(array_index_exists(@vanilla_enchants, 'unbreaking')) {
          @vanilla_enchants['unbreaking']['elevel'] = integer(@vanilla_enchants['unbreaking']['elevel'])
        }

        if(array_index_exists(@item, 'meta', 'flags')) {
          @item['meta']['flags'] = array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES')
        } else {
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

        # 기타 적용
        if(@item['name'] == 'SHIELD') {
          @unbreaking = 0
          if(array_index_exists(@item, 'meta', 'model')) {
            switch(@item['meta']['model']) {
            case 0: // 구리
            case 1:
              @unbreaking = 3.1
              break()
            case 2: // 철
            case 3:
              @unbreaking = 6.8
              break()
            case 4: // 금
            case 5:
              @unbreaking = 0
              break()
            case 6: // 다이아
            case 7:
              @unbreaking = 47.8
              break()
            case 8: // 네더라이트
            case 9:
              @unbreaking = 62.5
              break()
            }
          }
          @vanilla_enchants['unbreaking'] = array(
            'etype': 'DURABILITY',
            'elevel': @unbreaking
          )
        }

        # 스킬 적용
        foreach(@applying_skill: @applying_skill_data in @applying_skills) {
          @skill_spec = @applying_skill_data['skill_spec']
          @point = @applying_skill_data['point']
          @proc_name = @applying_skill_data['proc_name']
          call_proc(@proc_name, @player_data, @player, @uuid, @applying_skill, @skill_spec, @point, @item, @vanilla_enchants)
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
              if(array_index_exists(@vanilla_enchants, 'unbreaking')) {
                @vanilla_enchants['unbreaking']['elevel'] *= 3
              } else {
                @vanilla_enchants['unbreaking'] = array(
                  'etype': 'DURABILITY',
                  'elevel': 3
                )
              }
              break()
            }
          }
        }

        # 내구성 인첸 소수점 처리
        if(array_index_exists(@vanilla_enchants, 'unbreaking')) {
          @vanilla_enchants['unbreaking']['elevel'] = integer(@vanilla_enchants['unbreaking']['elevel'])
        }

        if(array_index_exists(@item, 'meta', 'flags')) {
          @item['meta']['flags'] = array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES')
        } else {
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