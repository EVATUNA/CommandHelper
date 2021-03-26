## Gameplay
console('EvaGameplay loaded')

## Include
include('crafting/main.ms')
include('enchant/main.ms')
include('skill/main.ms')

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
    'CROSS_BOW',
    'SHIELD',
    'WHEAT_SEEDS',
    'BEETROOT_SEEDS'
    'POTATO',
    'CARROT',
    'PUMPKIN_SEEDS',
    'MELON_SEEDS',
    'SWEET_BERRIES'
  )
)

# PROC
proc _update_item(@player, @uuid, @items, @players_data, @skills_spec, @text) {
  @enchantments = @players_data[@uuid]['item']['enchantments']
  if(array_index_exists(@items, 'main_hand')) {
    @enchantments['main_hand'] = null
    if(!is_null(@items['main_hand']) && !is_null(@items['main_hand']['meta']) && !is_null(@items['main_hand']['meta']['modifiers']) && !is_null(@items['main_hand']['meta']['lore'])) {
      @modifiers = @items['main_hand']['meta']['modifiers']
      @lore = @items['main_hand']['meta']['lore']
      if(array_size(@lore) > array_size(@modifiers)) {
        @enchantment = substr(strip_colors(@lore[array_size(@modifiers) + 1]), 2)
        @enchantments['main_hand'] = @enchantment
        @vanilla_enchants = array()
        if(@items['main_hand']['name'] == 'TRIDENT') {
          @vanilla_enchants['loyalty'] = array(
            'etype': 'LOYALTY',
            'elevel': 5
          )
        }
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
          @vanilla_enchants['sharpness'] = array(
            'etype': 'DAMAGE_ALL',
            'elevel': 1
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

        @items['main_hand']['meta']['enchants'] = @vanilla_enchants
        set_timeout(0, closure() {
          set_inventory_item(@uuid, pheld_slot(@player), @items['main_hand'])
        })
      }
    }
    @players_data[@uuid]['item']['main_hand'] = @items['main_hand']
  }
  if(array_index_exists(@items, 'off_hand')) {
    @enchantments['off_hand'] = null
    if(!is_null(@items['off_hand']) && !is_null(@items['off_hand']['meta']) && !is_null(@items['off_hand']['meta']['modifiers']) && !is_null(@items['off_hand']['meta']['lore'])) {
      @modifiers = @items['off_hand']['meta']['modifiers']
      @lore = @items['off_hand']['meta']['lore']
      if(array_size(@lore) > array_size(@modifiers)) {
        @enchantment = substr(strip_colors(@lore[array_size(@modifiers) + 1]), 2)
        @enchantments['off_hand'] = @enchantment
      }
    }
    @players_data[@uuid]['item']['off_hand'] = @items['off_hand']
  }
  if(array_index_exists(@items, 'armor')) { #널이든 값이든 존재할 경우
    @enchantments['armor'] = null
    if(!is_null(@items['armor']) && !is_null(@items['armor']['meta']) && !is_null(@items['armor']['meta']['modifiers']) && !is_null(@items['armor']['meta']['lore'])) {
      @modifiers = @items['armor']['meta']['modifiers']
      @lore = @items['armor']['meta']['lore']
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
        @items['armor']['meta']['enchants'] = @vanilla_enchants
        set_timeout(0, closure() {
          set_inventory_item(@uuid, 36, @items['armor'])
        })
      }
      @decoration_armors = array()
      switch(@items['armor']['name']) {
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
            'display': color('WHITE').'치장 설정',
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
            'display': color('WHITE').'치장 설정',
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
            'display': color('WHITE').'치장 설정',
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
            'display': color('WHITE').'치장 설정',
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
            'display': color('WHITE').'치장 설정',
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
            'display': color('WHITE').'치장 설정',
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
    } else {
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
          'display': color('WHITE').'치장 설정',
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
    @players_data[@uuid]['item']['armor'] = @items['armor']
  }
  foreach(@slot: @enchantment in @enchantments) {
    @players_data[@uuid]['item']['enchantments'][@slot] = @enchantment
  }
  set_timeout(0, closure() {
    _send_action_msg(@player, @players_data[@uuid], @skills_spec, @text)
  })
}


@death_penalties_multiply = array(
  'world': array(
    'default': array('multiply': 0.8, 'deviation': 0.15),
    'DIAMOND': array('multiply': 0.5, 'deviation': 0.2)
  )
)

proc _apply_death_penalty(@player, @uuid, @death_penalties_multiply) {
  @inventory = get_inventory(@uuid)
  @world = 'world' #플레이어의 월드로 수정
  foreach(@key: @item in @inventory) {
    if(!is_null(@item) && @item['name'] != 'STRUCTURE_VOID') {
      if(array_index_exists(@death_penalties_multiply[@world], @item['name'])) {
        @death_penalty_multiply = @death_penalties_multiply[@world][@item['name']]
      } else {
        @death_penalty_multiply = @death_penalties_multiply[@world]['default']
      }
      @max_durability = material_info(@item['name'], 'maxDurability')
      if(@max_durability == 0) {
        @inventory[@key]['qty'] = integer(_multiply_value(@item['qty'], @death_penalty_multiply['multiply'], @death_penalty_multiply['deviation']))
      } else {
        #내구성 반영
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
  if(array_index_exists(@players_data, @uuid)) {
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
            } else if(@held_slot == @clicked_slot && !is_null(@players_data[@uuid]['item']['main_hand'])) {
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
            } else if(@held_slot == @clicked_slot && !is_null(@players_data[@uuid]['item']['main_hand']) && array_contains(@other_inventory, null)) {
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
          } else if(@held_slot == @clicked_slot && !is_null(@players_data[@uuid]['item']['main_hand']) && array_contains(@other_inventory, null)) {
            @items['main_hand'] = null
          }
        }
      }
      break()
    case 'PICKUP_HALF':
    case 'PICKUP_ALL':
      if(@clicked_slot == @held_slot && !is_null(@players_data[@uuid]['item']['main_hand'])) {
        @items['main_hand'] = null
      }
      if(pinventory_holder(@player) == @uuid && @clicked_slot == 40 && !is_null(@players_data[@uuid]['item']['off_hand'])) {
        @items['off_hand'] = null
      }
      if(pinventory_holder(@player) == @uuid && @clicked_slot == 36 && !is_null(@players_data[@uuid]['item']['armor'])) {
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
      if(!@players_data[@uuid]['item']['is_inv_open']) {
        @players_data[@uuid]['item']['is_inv_open'] = true
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
      _update_item(@player, @uuid, @items, @players_data, @skills_spec, @text)
    }
  }
}

bind('inventory_open', null, null, @event, @players_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
    @players_data[@uuid]['item']['is_inv_open'] = true
  }
}

bind('inventory_close', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
    @players_data[@uuid]['item']['is_inv_open'] = false
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
      _update_item(@player, @uuid, @items, @players_data, @skills_spec, @text)
    }
  }
}

bind('item_held', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
    @held_item = get_inventory_item(@uuid, @event['to'])
    if(!is_null(@held_item) && array_contains(@effective_items['weapon'], @held_item['name'])) {
      _update_item(@player, @uuid, array('main_hand': @held_item), @players_data, @skills_spec, @text)
    } else if(!is_null(@players_data[@uuid]['item']['main_hand'])) {
      _update_item(@player, @uuid, array('main_hand': null), @players_data, @skills_spec, @text)
    }
  }
}

bind('item_swap', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
    if(psneaking()) {
      @items = array()
      @off_hand_item = get_inventory_item(@uuid, 40)
      if(!is_null(@off_hand_item) && array_contains(@effective_items['weapon'], @off_hand_item['name'])) {
        @items['main_hand'] = @off_hand_item
      } else if(!is_null(@players_data[@uuid]['item']['main_hand'])) {
        @items['main_hand'] = null
      }
      @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
      if(!is_null(@main_hand_item) && array_contains(@effective_items['weapon'], @main_hand_item['name'])) {
        @items['off_hand'] = @main_hand_item
      } else if(!is_null(@players_data[@uuid]['item']['off_hand'])) {
        @items['off_hand'] = null
      }
      if(array_size(@items) > 0) {
        _update_item(@player, @uuid, @items, @players_data, @skills_spec, @text)
      }
    } else {
      cancel()
      #combat_method
      #든 아이템에 따라 카테고리와 스킬 바꾸기
      #스위치
      @category = 'combat_method'
      @skill = @players_data[@uuid]['skill_manager'][2]
      if(@skill != '') {
        @active_skill = @players_data[@uuid]['active_skill'][@category][@skill]
        @level = @level = @players_data[@uuid]['skill_data'][@category][@skill][0]
        @level = 3
        switch(@skill) {
        case 'sweeping':
          #broadcast(@active_skill)
          if(@active_skill[2] == 1) {
            @active_attack_speed = @skills_spec['combat_method'][@skill]['levels'][@level]['active']['attack_speed']
            @modifier = array(
              'attribute': 'GENERIC_ATTACK_SPEED',
              'operation': 'ADD_SCALAR',
              'amount': @active_attack_speed,
              'name': 'sweeping_active'
            )
            add_entity_attribute_modifier(@uuid, @modifier)
            @active_skill[2] = 0
            @active_skill[1] = @skills_spec['combat_method'][@skill]['levels'][@level]['active']['duration']
          }
          break()
        case 'knockback':
          #broadcast(@active_skill)
          if(@active_skill[2] > 0) {
            @old_ploc = ploc(@player)
            set_timeout(200, closure() {
              @new_ploc = ploc(@player)
              @yaw = get_yaw(@old_ploc, @new_ploc)
              @vector = get_vector(array('yaw': @yaw, 'pitch': 0), 2)
              set_pvelocity(@player, @vector)
              play_named_sound(ploc(@player), array('sound': 'entity.bat.takeoff', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1))
            })
            @active_skill[2] -= 1
            @active_skill[0] = 5
          }
          break()
        case 'cleaving':
          if(@active_skill[2] == 1) {
            #broadcast(스킬발동)
            @active_skill[2] = 0
            @active_skill[1] = 15
          }
          break()
        #case 'blocking':
        #  break()
        }
      }


    }
  }
}

bind('item_drop', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
    if(!@players_data[@uuid]['item']['is_inv_open']) {
      @held_item = @event['item']
      if(array_contains(@effective_items['weapon'], @held_item['name'])) {
        _update_item(@player, @uuid, array('main_hand': null), @players_data, @skills_spec, @text)
      }
    }
  }
}

bind('item_pickup', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
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
        _update_item(@player, @uuid, array('main_hand': @event['item']), @players_data, @skills_spec, @text)
      }
    }
  }
}

bind('item_damage', null, null, @event, @players_data, @effective_items, @skills_spec, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
    @item = @event['item']
    @max_durability = material_info(@item['name'], 'maxDurability')
    if(is_null(@item['meta'])) {
      @durability = @event['damage']
    } else {
      @durability = @item['meta']['damage'] + @event['damage']
    }
    if(@durability >= @max_durability) {
      if(array_contains(@effective_items['armor'], @item['name'])) {
        _update_item(@player, @uuid, array('armor': null), @players_data, @skills_spec, @text)
      } else if(array_contains(@effective_items['weapon'], @item['name'])) {
        @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
        @off_hand_item = get_inventory_item(@uuid, 40)
        if(@item == @main_hand_item) {
          _update_item(@player, @uuid, array('main_hand': null), @players_data, @skills_spec, @text)
        } else if(@item == @off_hand_item) {
          _update_item(@player, @uuid, array('off_hand': null), @players_data, @skills_spec, @text)
        }
      }
    }
  }
}

## Gui Management
## Enchant, Repair
bind('player_interact', null, array('main_hand': 'main_main_hand', 'button': 'right'), @event, @essences, @text) {
  if(is_cancelled()) {

  } else {
    @player = @event['player']
    @uuid = puuid(@player)
    if(!psneaking(@player) || is_null(get_inventory_item(@uuid, pheld_slot(@player))) || is_null(get_inventory_item(@uuid, 40))) {
      switch(@event['block']) {
      case 'ENCHANTING_TABLE':
        cancel()
        @location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 1.01, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
        if(plevel(@player) >= 30) {
          if(pcooldown(@player, 'CAVE_AIR') == 0) {
            set_pcooldown(@player, 'CAVE_AIR', 30)
            @task = array('tick': 10, 'id': null)
            @id = set_interval(100 , closure() {
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
            })
            @task['id'] = @id
          }
        }
        break()
      case 'SMITHING_TABLE':
        cancel()
        @id = 'enchant_table.'.@player
        if(!array_contains(get_virtual_inventories(), @id)) {
          @title = @text['space_fonts']['space.-8'].'§f\ue3fb'.@text['space_fonts']['space.-169'].hexcolor('#404040').'마법 작업대'
          @dummy_item = array(
            'name': 'STRUCTURE_VOID',
            'meta': array(
              'display': ' ',
              'model': 1
            )
          )
          @inventory = array()
          for(@i = 0, @i < 27, @i++){
            @inventory[@i] = @dummy_item
          }
          @inventory[22] = null
          create_virtual_inventory(@id, 'CHEST', @title, @inventory)
          if(!has_bind(@id.'.close')) {
            bind('inventory_close', array('id': @id.'.close'), array('virtual': true, 'player': @player), @event, @player, @id) {
              @item = @event['inventory'][22]
              if(!is_null(@item)) {
                @item['qty'] = pgive_item(@player, @item)
                @ploc = ploc(@player)
                @ploc['y'] += 1
                drop_item(@ploc, @item, false)
              }
              unbind(@id.'.close')
              unbind(@id.'.click')
              set_timeout(1, closure() {
                delete_virtual_inventory(@event['holder'])
              })
            }
          }
          if(!has_bind(@id.'.click')) {
            bind('inventory_click', array('id': @id.'.click'), array('virtual': true, 'player': @player), @event, @essences) {
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
                if(!is_null(@cursor_item) && @cursor_item['name'] == 'ENCHANTED_BOOK' && !is_null(@cursor_item['meta']) && !is_null(@cursor_item['meta']['display']) && @rawslot == 22 && @event['action'] == 'SWAP_WITH_CURSOR') {
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
                    modify_event('slotitem', @enchanted_item)
                    modify_event('cursoritem', null)
                  }
                }
              }
            }
          }
        }
        popen_inventory(@player, @id)
        break()

      case 'ANVIL':
      case 'CHIPPED_ANVIL':
      case 'DAMAGED_ANVIL':
        cancel()
        @id = 'anvil.'.@player
        if(!array_contains(get_virtual_inventories(), @id)) {
          @title = @text['space_fonts']['space.-8'].'§f\ue3fc'.@text['space_fonts']['space.-169'].hexcolor('#404040').'모루'
          @dummy_item = array(
            'name': 'STRUCTURE_VOID',
            'meta': array(
              'display': ' ',
              'model': 1
            )
          )
          @inventory = array()
          for(@i = 0, @i < 27, @i++){
            @inventory[@i] = @dummy_item
          }
          @inventory[2] = null
          @inventory[20] = null
          delete_virtual_inventory(@id)
          create_virtual_inventory(@id, 'CHEST', @title, @inventory)
          if(!has_bind(@id.'.close')) {
            bind('inventory_close', array('id': @id.'.close'), array('virtual': true, 'player': @player), @event, @player, @id) {
              @repair_item = @event['inventory'][2]
              @ploc = ploc(@player)
              @ploc['y'] += 1
              if(!is_null(@repair_item)) {
                @repair_item['qty'] = pgive_item(@player, @repair_item)
                drop_item(@ploc, @repair_item, false)
              }
              @ore_item = @event['inventory'][20]
              if(!is_null(@ore_item)) {
                @ore_item['qty'] = pgive_item(@player, @ore_item)
                drop_item(@ploc, @ore_item, false)
              }
              unbind(@id.'.close')
              unbind(@id.'.click')
              set_timeout(1, closure() {
                delete_virtual_inventory(@event['holder'])
              })
            }
          }
          if(!has_bind(@id.'.click')) {
            bind('inventory_click', array('id': @id.'.click'), array('virtual': true, 'player': @player), @event) {
              @rawslot = @event['rawslot']
              if(@rawslot >= 0 && @rawslot <= 26) {
                @clicked_item = @event['inventory'][@rawslot]
                if(!is_null(@clicked_item) && @clicked_item['name'] == 'STRUCTURE_VOID') {
                  cancel()
                }
              }
            }
          }
        }
        popen_inventory(@player, @id)
        break()
      }
    }
  }
}


bind('entity_damage', null, null, @event, @players_data) {
  if(array_index_exists(@event, 'damager') && ponline(@event['damager'])) { //플레이어가 때리는 경우
    @player = @event['damager']
    @puuid = puuid(@player)
    if(array_index_exists(@players_data, @puuid)) {
      @euuid = @event['id']
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
      if(!is_null(@items['main_hand']) && array_contains(@weapons, @items['main_hand']['name'])) {
        @attack_speed = entity_attribute_value(@puuid, 'GENERIC_ATTACK_SPEED')
        @tick = integer(1/ @attack_speed * 20)
        if(@tick < 20) {
          set_timeout(0, closure( set_entity_immunity_ticks(@euuid, @tick) ))
        }
      }
      switch(@items['enchantments']['main_hand']) {
      case '전격':
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
          #'PLAYER': 1.8,
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
        if(array_contains(array_keys(@allowed_entity), @entity_type)) {
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




        #_particle(@player, 'minecraft:firework', @pos, array('x': 0.2, 'y': 0.3, 'z': 0.2), 0.05, 3)


          #@delta = array(
          #  'x': sprintf('%.5f', round((@near_entity_location['x'] - @near_pos['x']) / 4, 5)),
          #  'y': sprintf('%.5f', round((@near_entity_location['y'] - @near_pos['y']) / 4, 5)),
          #  'z': sprintf('%.5f', round((@near_entity_location['z'] - @near_pos['z']) / 4, 5))
          #)
          #_particle(@player, 'minecraft:firework', @pos, @delta, 1, 0)
          #damage_entity(@near_entity, 3)
        
        break()
      case '천둥':
      
        break()
      case '화염':
        if(rand() < 0.1) {
          set_entity_onfire(@euuid, entity_onfire(@euuid) + 5)
        }
        break()
      case '유황불':
        if(rand() < 0.25) {
          if(entity_onfire(@euuid) > 0) {
            set_mob_effect(@euuid, 'WEAKNESS', 0, 3, false, true)
          }
          set_entity_onfire(@euuid, entity_onfire(@euuid) + 5)
        }
        break()
      case '냉기':
        if(rand() < 0.1) {
          set_mob_effect(@euuid, 'SLOWNESS', 1, 10, false, true)
        }
        #0.25 필드 효과 반감
        break()
      case '빙결':
        if(rand() < 0.25) {
          set_mob_effect(@euuid, 'SLOWNESS', 1, 10, false, true)
        }
        if(rand() < 0.025) {
          set_mob_effect(@euuid, 'SLOWNESS', 5, 4, false, true)
        }
        #1.0 필드 효과 반감
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
        if(array_contains(@undead_entities, entity_type(@euuid)) && rand() < 0.1) {
          broadcast(A)
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
        if(array_contains(@undead_entities, entity_type(@euuid)) && rand() < 0.25) {
          broadcast(A)
          set_mob_effect(@euuid, 'INSTANT_HEALTH', 2, 0.1, false, true)
        }
        break()
      case '독성':
        if(rand() < 0.1) {
          set_mob_effect(@euuid, 'POISON', 0, 5, false, true)
        }
        break()
      case '맹독':
        if(rand() < 0.1) {
          set_mob_effect(@euuid, 'POISON', 4, 5, false, true)
        }
        break()
      default:

      }
    }
  }
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
            set_inventory_item(@puuid, @shield_slot, array('name': 'CLOCK', 'qty: -1', 'meta': null))
            set_timeout(1, closure() {set_inventory_item(@puuid, @shield_slot, @damaged_item)})
          }
        })

        #@mastry_type = 'shield'
        #@masteries = import(@player.'.masteries')
        #@skill_level = integer(@masteries[@mastry_type] / 500)
        #if(@skill_level > 3) {
        #  @skill_level = 3
        #}
        @skill_level = 1
        
        set_pcooldown(@player, 'SHIELD', integer(@event['amount'] * (5 - @skill_level)))
        #set_timeout(0, closure() {
          #play_entity_effect(puuid(@player), 'SHIELD_BLOCK')#SHIELD_BLOCK
          #set_pcooldown(@player, 'SHIELD', integer(@event['amount'] * (5 - @skill_level)))
        #})
        #@defense_damage = @event['amount']
        #@adding_mastry_xp = @defense_damage / 20
        #if(@skill_level < 3) {
        #  if(@adding_mastry_xp > 0) {
        #    _add_mastry(@player, @mastry_type, @adding_mastry_xp)
        #  }
        #}
      }
    }
  }
}

bind('exp_change', null, null, @event, @players_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_data, @uuid)) {
    foreach(@slot: @enchantment in @players_data[@uuid]['item']['enchantments']) {
      switch(@enchantment) {
      case '풍요':
        break()
      case '치유':
        break()
      case '저항':
        break()
      case '친수성':
        break()
      case '반엔트로피':
        break()
      case '용력':
        break()
      default:
        #broadcast('A') #/summon minecraft:experience_orb ~ ~ ~ {Value:10}
      }
    }
  }
}

bind('player_death', null, null, @event, @death_penalties_multiply) {
  @player = @event['player']
  @uuid = puuid(@player)
  _apply_death_penalty(@player, @uuid, @death_penalties_multiply)
}