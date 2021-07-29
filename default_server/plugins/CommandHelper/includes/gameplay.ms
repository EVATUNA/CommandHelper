## Include
include('crafting/crafting.ms')
include('enchant/enchant.ms')
include('skill/skill.ms')

## Item Management
@effective_items = array(
  'armor': array(
    'LEATHER_BOOTS',
    'CHAINMAIL_BOOTS',
    'IRON_BOOTS',
    'GOLDEN_BOOTS',
    'DIAMOND_BOOTS',
    'NETHERITE_BOOTS'
  ),
  'weapon': array(
    'WOODEN_SWORD',
    'WOODEN_SHOVEL',
    'WOODEN_PICKAXE',
    'WOODEN_AXE',
    'WOODEN_HOE',
    'STONE_SWORD',
    'STONE_SHOVEL',
    'STONE_PICKAXE',
    'STONE_AXE',
    'STONE_HOE',
    'GOLDEN_SWORD',
    'GOLDEN_SHOVEL',
    'GOLDEN_PICKAXE',
    'GOLDEN_AXE',
    'GOLDEN_HOE',
    'IRON_SWORD',
    'IRON_SHOVEL',
    'IRON_PICKAXE',
    'IRON_AXE',
    'IRON_HOE',
    'DIAMOND_SWORD',
    'DIAMOND_SHOVEL',
    'DIAMOND_PICKAXE',
    'DIAMOND_AXE',
    'DIAMOND_HOE',
    'NETHERITE_SWORD',
    'NETHERITE_SHOVEL',
    'NETHERITE_PICKAXE',
    'NETHERITE_AXE',
    'NETHERITE_HOE',
    'TRIDENT',
    'BOW',
    'CROSSBOW',
    'SHIELD',
    'WHEAT_SEEDS',
    'BEETROOT_SEEDS',
    'POTATO',
    'CARROT',
    'PUMPKIN_SEEDS',
    'MELON_SEEDS',
    'SWEET_BERRIES'
  )
)

# PROC
proc _update_item(@player, @uuid, @items, @player_data, @skills_spec, @text) {
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
      if(array_size(@vanilla_enchants) > 0) {
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
      if(array_size(@vanilla_enchants) > 0) {
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
        }
      }
      @item['meta']['enchants'] = @vanilla_enchants
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
    _send_action_msg(@player, @player_data, @skills_spec, @text)
  })
}

@death_penalties_multiply = array(
  'main': array(
    'default': array('multiply': 1, 'deviation': 0),
  ),
  'over': array(
    'default': array('multiply': 0.9, 'deviation': 0.05),
  ),
  'nether': array(
    'default': array('multiply': 0.6, 'deviation': 0.2),
    #'DIAMOND': array('multiply': 0.5, 'deviation': 0.2)
  )
)

proc _apply_death_penalty(@player, @uuid, @death_penalties_multiply, @players_data, @server) {
  @inventory = get_inventory(@uuid)
  modify_event('death_message', null)
  if(@server != 'main') {
    if(@players_data[@uuid]['item']['enchantments']['armor'] == '귀속') {
      tmsg(@player, '💀 §7데스패널티로 약 '.integer(round((1 - @death_penalties_multiply[@server]['default']['multiply']) * 50)).'%의 아이템이 소실되었습니다..')
    } else {
      tmsg(@player, '💀 §7데스패널티로 약 '.integer(round((1 - @death_penalties_multiply[@server]['default']['multiply']) * 100)).'%의 아이템이 소실되었습니다..')
    }
  }
  foreach(@key: @item in @inventory) {
    if(!is_null(@item) && @item['name'] != 'STRUCTURE_VOID') {
      if(array_index_exists(@death_penalties_multiply[@server], @item['name'])) {
        @death_penalty_multiply = @death_penalties_multiply[@server][@item['name']]
      } else {
        @death_penalty_multiply = @death_penalties_multiply[@server]['default']
      }
      if(@players_data[@uuid]['item']['enchantments']['armor'] == '귀속') {
        @death_penalty_multiply['multiply'] += (1 - @death_penalty_multiply['multiply']) / 2
        @death_penalty_multiply['deviation'] = @death_penalty_multiply['deviation'] / 2
      }
      @max_durability = material_info(@item['name'], 'maxDurability')
      if(@max_durability == 0) {
        @inventory[@key]['qty'] = integer(_multiply_value(@item['qty'], @death_penalty_multiply['multiply'], @death_penalty_multiply['deviation']))
      } else {
        #내구도 반영
        @new_damage = integer(_multiply_value(@max_durability, 1 - @death_penalty_multiply['multiply'], @death_penalty_multiply['deviation']))
        if(is_null(@item['meta'])) {
          @durability = @new_damage
          @inventory[@key]['meta'] = array()
        } else {
          @durability = @item['meta']['damage'] + @new_damage
        }
        if(@durability < @max_durability) {
          @inventory[@key]['meta']['damage'] = @durability
        } else {
          @inventory[@key] = null
        }
      }
    }
  }
  set_inventory(@uuid, @inventory)
}

bind('inventory_click', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid)) {
    @player_data = @players_data[@uuid]
    @held_slot = pheld_slot(@player)
    @clicked_slot = @event['slot']
    @slot_item = @event['slotitem']
    @items = array()
    switch(@event['action']) {
    case 'HOTBAR_SWAP':
      @button = @event['hotbarbutton']
      if(@button == -1) { @button = 40 }
      @button_item = get_inventory_item(@uuid, @button)
      if(@button == @held_slot && @button != @clicked_slot) {
        if(!is_null(@slot_item) && array_contains(@effective_items['weapon'], @slot_item['name'])) {
          @items['main_hand'] = @slot_item
        } else {
          @items['main_hand'] = null
        }
        if(@clicked_slot == 40) {
          if(!is_null(@button_item) && array_contains(@effective_items['weapon'], @button_item['name'])) {
            @items['off_hand'] = @button_item
          } else {
            @items['off_hand'] = null
          }
        }
      } else if(@clicked_slot == @held_slot && @button != @clicked_slot) {
        if(!is_null(@button_item) && array_contains(@effective_items['weapon'], @button_item['name'])) {
          @items['main_hand'] = @button_item
        } else {
          @items['main_hand'] = null
        }
        if(@button == 40) {
          if(!is_null(@slot_item) && array_contains(@effective_items['weapon'], @slot_item['name'])) {
            @items['off_hand'] = @slot_item
          } else {
            @items['off_hand'] = null
          }
        }
      }
      if(@clicked_slot == 36) {
        @items['armor'] = get_inventory_item(@uuid, @button)
      }
      break()
    case 'MOVE_TO_OTHER_INVENTORY':
      @inventory = get_inventory(@uuid)
      @other_inventory = @event['inventory']
      if(pinventory_holder(@player) == @uuid) {
        array_remove(@other_inventory, 0)
        if(array_size(@other_inventory) == 4) {
          if(array_contains(@effective_items['armor'], @slot_item['name'])) {
            if(@clicked_slot == 36) {
              @is_inventory_empty = false
              for(@i = 0, @i <= 35, @i ++) {
                if(is_null(@inventory[@i])) {
                  @is_inventory_empty = true
                  break()
                }
              }
              if(@is_inventory_empty) {
                @items['armor'] = null
              }
            } else if(is_null(get_inventory_item(@uuid, 36))) {
              @items['armor'] = @slot_item
            }
          }
          if(array_contains(@effective_items['weapon'], @slot_item['name'])) {
            if(@clicked_slot == 40) {
              @is_inventory_empty = false
              for(@i = 0, @i <= 35, @i ++) {
                if(is_null(@inventory[@i])) {
                  @is_inventory_empty = true
                  break()
                }
              }
              if(@is_inventory_empty) {
                @items['off_hand'] = null
              }
            }
            if(is_null(get_inventory_item(@uuid, @held_slot))) {
              if(@clicked_slot == 40 || @event['rawslot'] < array_size(@other_inventory)) {
                @is_inventory_empty = false
                for(@i = 9, @i <= 35, @i ++) {
                  if(is_null(@inventory[@i])) {
                    @is_inventory_empty = true
                    break()
                  }
                }
                if(!@is_inventory_empty) {
                  @is_pre_hotbar_slot_empty = false
                  for(@i = 0, @i < @held_slot, @i ++) {
                    if(is_null(@inventory[@i])) {
                      @is_pre_hotbar_slot_empty = true
                      break()
                    }
                  }
                  if(!@is_pre_hotbar_slot_empty) {
                    @items['main_hand'] = @slot_item
                    if(@clicked_slot == 40) {
                      @items['off_hand'] = null
                    }
                  } else {
                    @is_pre_hotbar_slot_empty = true
                    for(@i = 0, @i < @held_slot, @i ++) {
                      if(is_null(@inventory[@i])) {
                        @is_pre_hotbar_slot_empty = true
                        break()
                      }
                    }
                  }
                } else {
                  if(@clicked_slot == 40) {
                    @items['off_hand'] = null
                  }
                }
              } else if(@clicked_slot > 8 && @clicked_slot < 36) {
                @is_pre_hotbar_slot_empty = false
                for(@i = 0, @i < @held_slot, @i ++) {
                  if(is_null(@inventory[@i])) {
                    @is_pre_hotbar_slot_empty = true
                    break()
                  }
                }
                if(!@is_pre_hotbar_slot_empty) {
                  @items['main_hand'] = @slot_item
                }
              }
            } else if(@held_slot == @clicked_slot && !is_null(@player_data['item']['main_hand'])) {
              @is_inventory_empty = false
              for(@i = 9, @i <= 35, @i ++) {
                if(is_null(@inventory[@i])) {
                  @is_inventory_empty = true
                  break()
                }
              }
              if(@is_inventory_empty) {
                @items['main_hand'] = null
              }
            }
          }
        } else {
          if(array_contains(@effective_items['weapon'], @slot_item['name'])) {
            if(is_null(get_inventory_item(@uuid, @held_slot))) {
              if(@event['rawslot'] < array_size(@other_inventory)) {
                @is_inventory_empty = false
                for(@i = 9, @i <= 35, @i ++) {
                  if(is_null(@inventory[@i])) {
                    @is_inventory_empty = true
                    break()
                  }
                }
                if(!@is_inventory_empty) {
                  @is_pre_hotbar_slot_empty = false
                  for(@i = 0, @i < @held_slot, @i ++) {
                    if(is_null(@inventory[@i])) {
                      @is_pre_hotbar_slot_empty = true
                      break()
                    }
                  }
                  if(!@is_pre_hotbar_slot_empty) {
                    @items['main_hand'] = @slot_item
                  }
                }
              }
            } else if(@held_slot == @clicked_slot && !is_null(@player_data['item']['main_hand']) && array_contains(@other_inventory, null)) {
              @items['main_hand'] = null
            }
          }
        }
      } else {
        if(array_contains(@effective_items['weapon'], @slot_item['name'])) {
          if(is_null(get_inventory_item(@uuid, @held_slot))) {
            if(@event['rawslot'] < array_size(@other_inventory)) {
              @is_post_hotbar_slot_empty = false
              for(@i = 8, @i > @held_slot, @i --) {
                if(is_null(@inventory[@i])) {
                  @is_post_hotbar_slot_empty = true
                  break()
                }
              }
              if(!@is_post_hotbar_slot_empty) {
                @items['main_hand'] = @slot_item
              }
            }
          } else if(@held_slot == @clicked_slot && !is_null(@player_data['item']['main_hand']) && array_contains(@other_inventory, null)) {
            @items['main_hand'] = null
          }
        }
      }
      break()
    case 'PICKUP_HALF':
    case 'PICKUP_ALL':
      if(@clicked_slot == @held_slot && !is_null(@player_data['item']['main_hand'])) {
        @items['main_hand'] = null
      }
      if(pinventory_holder(@player) == @uuid && @clicked_slot == 40 && !is_null(@player_data['item']['off_hand'])) {
        @items['off_hand'] = null
      }
      if(pinventory_holder(@player) == @uuid && @clicked_slot == 36 && !is_null(@player_data['item']['armor'])) {
        @items['armor'] = null
      }
      break()
    case 'PLACE_ONE':
    case 'PLACE_ALL':
    case 'SWAP_WITH_CURSOR':
      @cursor_item = @event['cursoritem']
      if(@clicked_slot == @held_slot) {
        if(!is_null(@cursor_item) && array_contains(@effective_items['weapon'], @cursor_item['name'])) {
          @items['main_hand'] = @cursor_item
        } else {
          @items['main_hand'] = null
        }
      }
      if(pinventory_holder(@player) == @uuid && @clicked_slot == 40) {
        if(!is_null(@cursor_item) && array_contains(@effective_items['weapon'], @cursor_item['name'])) {
          @items['off_hand'] = @cursor_item
        } else {
          @items['off_hand'] = null
        }
      }
      if(pinventory_holder(@player) == @uuid && @clicked_slot == 36) {
        if(!is_null(@cursor_item) && array_contains(@effective_items['armor'], @cursor_item['name'])) {
          @items['armor'] = @cursor_item
        } else {
          @items['armor'] = null
        }
      }
      break()
    case 'DROP_ALL_SLOT':
    case 'DROP_ONE_SLOT':
      if(!@player_data['item']['is_inv_open']) {
        @player_data['item']['is_inv_open'] = true
      }
      if(@clicked_slot == @held_slot && array_contains(@effective_items['weapon'], @slot_item['name'])) {
        @items['main_hand'] = null
      }
      if(pinventory_holder(@player) == @uuid && @clicked_slot == 40 && array_contains(@effective_items['weapon'], @slot_item['name'])) {
        @items['off_hand'] = null
      }
      if(pinventory_holder(@player) == @uuid && @clicked_slot == 36 && array_contains(@effective_items['armor'], @slot_item['name'])) {
        @items['armor'] = null
      }
      break()
    }
    if(array_size(@items) > 0) {
      _update_item(@player, @uuid, @items, @player_data, @skills_spec, @text)
    }
  }
}

bind('inventory_open', null, null, @event, @players_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid) && ponline(@player)) {
    @players_data[@uuid]['item']['is_inv_open'] = true
  }
}

bind('inventory_close', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid) && ponline(@player)) {
    @player_data = @players_data[@uuid]
    @player_data['item']['is_inv_open'] = false
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
    if(array_size(@items) > 0) {
      _update_item(@player, @uuid, @items, @player_data, @skills_spec, @text)
    }
  }
}

bind('item_held', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid) && ponline(@player)) {
    @player_data = @players_data[@uuid]
    @held_item = get_inventory_item(@uuid, @event['to'])
    if(!is_null(@held_item) && array_contains(@effective_items['weapon'], @held_item['name'])) {
      _update_item(@player, @uuid, array('main_hand': @held_item), @player_data, @skills_spec, @text)
    } else if(!is_null(@player_data['item']['main_hand'])) {
      _update_item(@player, @uuid, array('main_hand': null), @player_data, @skills_spec, @text)
    }
  }
}

bind('item_swap', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid) && ponline(@player)) {
    @player_data = @players_data[@uuid]
    if(psneaking()) { // 아이템 스왑 시
      @items = array()
      @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
      @off_hand_item = get_inventory_item(@uuid, 40)
      set_timeout(1, closure() {
        @new_main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
        @new_off_hand_item = get_inventory_item(@uuid, 40)
        if(@main_hand_item != @new_main_hand_item && @off_hand_item != @new_off_hand_item) {
          if(!is_null(@main_hand_item) && array_contains(@effective_items['weapon'], @main_hand_item['name'])) {
            @items['off_hand'] = @main_hand_item
          } else if(!is_null(@player_data['item']['off_hand'])) {
            @items['off_hand'] = null
          }
          if(!is_null(@off_hand_item) && array_contains(@effective_items['weapon'], @off_hand_item['name'])) {
            @items['main_hand'] = @off_hand_item
          } else if(!is_null(@player_data['item']['main_hand'])) {
            @items['main_hand'] = null
          }
          if(array_size(@items) > 0) {
            _update_item(@player, @uuid, @items, @player_data, @skills_spec, @text)
          }
        }
      })
    } else { // 액티브 스킬 사용하려 할 시
      cancel()
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
      # 손에든 아이템에 따라 사용할 액티브 스킬 설정
      if(!is_null(@main_hand_item)) { // 무언가 들고 있을시
        if(array_contains(@hoes, @main_hand_item['name'])) {
          @skill = @selected_methods['harvesting_method']
        } else if(array_contains(@seeds, @main_hand_item['name'])) {
          @skill = @selected_methods['sowing_method']
        } else {
          @skill = @selected_methods['combat_method']
        }
        if(@skill == '') { // 파종, 수확 스킬 선택 안했을시
          @skill = @selected_methods['combat_method']
        }
      } else { // 특별한 도구 든거 없을시
        @skill = @selected_methods['combat_method']
      }
      # 액티브 스킬을 쓸수 있을시
      if(@skill != '' && array_index_exists(@player_data['active_skill'], @skill)) {
        @point = @player_data['skill_data'][@skill][0]
        @skill_spec = @skills_spec[@skill]
        @proc_name = "_apply_active_by_@skill"
        if(is_proc(@proc_name)) {
          broadcast('R' @player_data['active_skill'])
          call_proc(@proc_name, @player_data, @player, @uuid, @skill, @skill_spec, @point)
          //_send_action_msg(@player, @player_data, @skills_spec, @text) // 액션바 설정
        }
      }
    }
  }
}

bind('item_drop', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid) && ponline(@player)) {
    if(!@players_data[@uuid]['item']['is_inv_open']) {
      @player_data = @players_data[@uuid]
      @held_item = @event['item']
      if(array_contains(@effective_items['weapon'], @held_item['name'])) {
        _update_item(@player, @uuid, array('main_hand': null), @player_data, @skills_spec, @text)
      }
    }
  }
}

bind('item_pickup', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid) && ponline(@player)) {
    @player_data = @players_data[@uuid]
    @held_slot = pheld_slot(@player)
    @inventory = get_inventory(@uuid)
    if(array_contains(@effective_items['weapon'], @event['item']['name']) && is_null(@inventory[@held_slot])) {
      @is_pre_hotbar_slot_empty = false
      for(@i = 0, @i < @held_slot, @i ++) {
        if(is_null(@inventory[@i])) {
          @is_pre_hotbar_slot_empty = true
          break()
        }
      }
      if(!@is_pre_hotbar_slot_empty) {
        _update_item(@player, @uuid, array('main_hand': @event['item']), @player_data, @skills_spec, @text)
      }
    }
  }
}

bind('item_damage', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid) && ponline(@player)) {
    @player_data = @players_data[@uuid]
    @item = @event['item']
    @max_durability = material_info(@item['name'], 'maxDurability')
    if(is_null(@item['meta'])) {
      @durability = @event['damage']
    } else {
      @durability = @item['meta']['damage'] + @event['damage']
    }
    if(@durability >= @max_durability) {
      if(array_contains(@effective_items['armor'], @item['name'])) {
        _update_item(@player, @uuid, array('armor': null), @player_data, @skills_spec, @text)
      } else if(array_contains(@effective_items['weapon'], @item['name'])) {
        @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
        @off_hand_item = get_inventory_item(@uuid, 40)
        if(@item == @main_hand_item) {
          _update_item(@player, @uuid, array('main_hand': null), @player_data, @skills_spec, @text)
        } else if(@item == @off_hand_item) {
          _update_item(@player, @uuid, array('off_hand': null), @player_data, @skills_spec, @text)
        }
      }
    }
  }
}

bind('projectile_launch', null,, array('shootertype': 'PLAYER'), @event, @players_data) {
  @uuid = @event['shooter']
  @player = player(@uuid)
  @projectile = @event['id']
  if(@event['type'] == 'ARROW' || @event['type'] == 'SPECTRAL_ARROW') {
    @main_hand_item = @players_data[@uuid]['item']['main_hand']
    @off_hand_item = @players_data[@uuid]['item']['off_hand']
    if(!is_null(@main_hand_item) && array_contains(array('BOW', 'CROSSBOW'), @main_hand_item['name'])) {
      set_mob_name(@projectile, @main_hand_item['name'])
    } else if(!is_null(@off_hand_item) && array_contains(array('BOW', 'CROSSBOW'), @off_hand_item['name'])) {
      set_mob_name(@projectile, @off_hand_item['name'])
    }
  }
}

bind('entity_damage', null, null, @event, @players_data, @skills_spec, @text, @server) {
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
    'PLAYER': 1.8,
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
  if(array_index_exists(@event, 'damager')) {
    # 원거리 공격
    if(array_index_exists(@event, 'shooter') && is_string(@event['shooter']) && ponline(@event['shooter'])) {
      @player = @event['shooter']
      @puuid = puuid(@player)
      if(array_index_exists(@players_data, @puuid)) {
        @euuid = @event['id']
        @entity_type = entity_type(@euuid)
        @projectile = @event['damager']
        switch(entity_type(@projectile)) {
        case 'ARROW':
        case 'SPECTRAL_ARROW':
          switch(get_mob_name(@projectile)) {
          case 'BOW':
            break()
          case 'CROSSBOW':
            break()
          }
          break()
        }
      }
    }
    # 근접 공격
    if(ponline(@event['damager'])) {
      @player = @event['damager']
      @puuid = puuid(@player)
      if(array_index_exists(@players_data, @puuid)) {
        @euuid = @event['id']
        @entity_type = entity_type(@euuid)
        @items = @players_data[@puuid]['item']
        @weapons = array(
          'WOODEN_SWORD',
          'WOODEN_SHOVEL',
          'WOODEN_PICKAXE',
          'WOODEN_AXE',
          'WOODEN_HOE',
          'STONE_SWORD',
          'STONE_SHOVEL',
          'STONE_PICKAXE',
          'STONE_AXE',
          'STONE_HOE',
          'IRON_SWORD',
          'IRON_SHOVEL',
          'IRON_PICKAXE',
          'IRON_AXE',
          'IRON_HOE',
          'GOLDEN_SWORD',
          'GOLDEN_SHOVEL',
          'GOLDEN_PICKAXE',
          'GOLDEN_AXE',
          'GOLDEN_HOE',
          'DIAMOND_SWORD',
          'DIAMOND_SHOVEL',
          'DIAMOND_PICKAXE',
          'DIAMOND_AXE',
          'DIAMOND_HOE',
          'NETHERITE_SWORD',
          'NETHERITE_SHOVEL',
          'NETHERITE_PICKAXE',
          'NETHERITE_AXE',
          'NETHERITE_HOE',
          'TRIDENT'
        )
        if(array_contains(array_keys(@allowed_entity), @entity_type)) {
          _player_attack_event(@event, @player, @puuid, @euuid, @players_data, @skills_spec, @allowed_entity, @text, @server)
        }
      }
    }
  }
  # 방어
  if(@event['type'] == 'PLAYER') {
    @player = @event['player']
    @puuid = @event['id']
    if(array_index_exists(@players_data, @puuid)) {
      @items = @players_data[@puuid]['item']
      if(@event['finalamount'] == 0 && pblocking(@player)) {
        if(!is_null(@items['main_hand']) && @items['main_hand']['name'] == 'SHIELD') {
          @shield_slot = pheld_slot(@player)
        } else {
          @shield_slot = 40
        }
        set_timeout(1, closure() {
          @damaged_item = get_inventory_item(@puuid, @shield_slot)
          if(@damaged_item['name'] == 'SHIELD') {
            @dummy_item = array(
              'name': 'CLOCK',
              'qty': 1,
              'meta': array(
                'model': 1,
                'display': ' '
              )
            )
            set_inventory_item(@puuid, @shield_slot, @dummy_item)
            set_timeout(1, closure() {set_inventory_item(@puuid, @shield_slot, @damaged_item)})
          }
        })
        @skill_data = @players_data[@puuid]['skill_data']['blocking']
        @point = @skill_data[0]
        set_pcooldown(@player, 'SHIELD', integer(@event['amount'] * (5 - @point)))
      }
    }
  }
}

bind('player_death', null, null, @event, @death_penalties_multiply, @players_data, @server) {
  @player = @event['player']
  @uuid = puuid(@player)
  _apply_death_penalty(@player, @uuid, @death_penalties_multiply, @players_data, @server)
}

bind('entity_death', null, null, @event, @players_data) {
  if(array_index_exists(@event['cause'],'damager') && ponline(@event['cause']['damager'])) {
    @player = @event['cause']['damager']
    @uuid = puuid(@player)
    if(@players_data[@uuid]['item']['enchantments']['main_hand'] == '경험') {
      #broadcast(integer(@event['xp'] * 1.5))
      modify_event('xp', @event['xp'] * 2)
    }
  }
}

bind('creature_spawn', null, null, @event) {
  @uuid = @event['id']
  set_equipment_droprates(@uuid, array(
    'HELMET': 0,
    'CHESTPLATE': 0,
    'LEGGINGS': 0,
    'BOOTS': 0,
    'WEAPON': 0,
    'OFF_HAND': 0
  ))
}