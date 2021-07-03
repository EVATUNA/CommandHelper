console('EvaEnchant loaded')

## Essence Data Load
@essences = array()
foreach(@file in list_files('essence_tables')) {
  @essence = replace(@file, '.json', '')
  async_read('essence_tables/'.@file, closure(@data) {
    @essences[@essence] = json_decode(@data)
  })
}

proc _get_enchanted_item(@enchanting_item, @entries, @luck) {
  @total_weight = 0
  foreach(@key: @entry in @entries) {
    @weight = @entry['weight']
    if(array_index_exists(@entry, 'quality')) {
      @quality = @entry['quality']
    } else {
      @quality = 0
    }
    @weight = @weight + @quality * @luck # new_weight = quality x luck + weight
    if(@weight < 0) {
      @weight = 0
    }
    @entries[@key]['weight'] = @weight
    @total_weight += @weight
  }
  @result_weight = @total_weight * round(rand(), 5)
  @min_weight = 0
  @final_entry = null
  foreach(@entry in @entries) {
    @weight = @entry['weight']
    @max_weight = @min_weight + @weight
    if(@max_weight > @result_weight) {
      @final_entry = @entry
      break()
    } else {
      @min_weight = @max_weight
    }
  }
  @enchanted_item = @enchanting_item
  if(!is_null(@enchanting_item) && !is_null(@enchanting_item['meta']) && array_index_exists(@enchanting_item['meta'], 'modifiers')) {
    @lore_size = array_size(@enchanting_item['meta']['modifiers'])
  } else {
    @lore_size = 0
  }
  @enchanted_item['meta']['lore'] = array_get(@enchanting_item['meta']['lore'], cslice(0, @lore_size - 1))
  if(!is_null(@final_entry)) {
    @enchanted_item['meta']['lore'][@lore_size] = ''
    @enchanted_item['meta']['lore'][@lore_size + 1] = '§f'.@final_entry['icon'].' '.hexcolor(@final_entry['color']).@final_entry['name']
    @descriptions = @final_entry['descriptions']
    foreach(@key: @description in @descriptions) {
      @enchanted_item['meta']['lore'][@lore_size + 2 + @key] = '§7'.@description
    }
  }
  return(@enchanted_item)
}

proc _apply_passive_armor_enchantment(@player, @player_data) {
  switch(@player_data['item']['enchantments']['armor']) {
  case '원소 보호':
    @debuff_effects = array(
      'blindness': 'BLINDNESS',
      'hunger': 'HUNGER',
      'levitation': 'LEVITATION',
      'mining_fatigue': 'MINING_FATIGUE',
      'nausea': 'NAUSEA',
      'poison': 'POISON',
      'slowness': 'SLOWNESS',
      'unluck': 'BAD_LUCK',
      'weakness': 'WEAKNESS',
      'wither': 'WITHER'
    )
    foreach(@effect: @effect_data in get_peffect(@player)) {
      if(array_contains(array_keys(@debuff_effects), @effect) && rand() < 0.6) {
        if(@effect_data['seconds'] > 1) {
          @effect_data['seconds'] -= 1
          set_peffect(@player, @debuff_effects[@effect], @effect_data['strength'], 0, @effect_data['ambient'], @effect_data['particles'])
          set_peffect(@player, @debuff_effects[@effect], @effect_data['strength'], @effect_data['seconds'], @effect_data['ambient'], @effect_data['particles'])
        }
      }
    }
    break()
  case '날렵함':
    set_peffect(@player, 'SPEED', 1, 11.5, false, true)
    set_peffect(@player, 'JUMP_BOOST', 1, 11.5, false, true)
    break()
  case '깃털':
    if(!psneaking(@player)) {
      set_peffect(@player, 'SLOW_FALLING', 4, 11.5, false, true)
    }
    break()
  case '심안':
    set_peffect(@player, 'NIGHT_VISION', 0, 16.5, false, true)
    @effects = get_peffect(@player)
    if(array_index_exists(@effects, 'blindness')) {
      set_peffect(@player, 'BLINDNESS', 0, 0, false, true)
    }
    if(array_index_exists(@effects, 'nausea')) {
      set_peffect(@player, 'NAUSEA', 0, 0, false, true)
    }
    break()
  }
}

proc _preset_item_armorstand(@item_location) {
  @item_armorstands = entities_in_radius(@item_location, 0, 'ARMOR_STAND')
  if(array_size(@item_armorstands) == 0) {
    @item_armorstand = spawn_entity('ARMOR_STAND', 1, @item_location, closure(@item_armorstand) {
      set_entity_spec(@item_armorstand, array(
        'gravity': false,
        'marker': true,
        'visible': false,
        'poses': array(
          'poseHead': array(
            'x': to_radians(90),
            'y': to_radians(0),
            'z': to_radians(0)
          )
        )
      ))
      set_mob_name(@item_armorstand, '0')
      add_scoreboard_tag(@item_armorstand, 'enchanted_item')
    })[0]
  } else {
    @is_item_armorstand_exists = false
    foreach(@unknown_armorstand in @item_armorstands) {
      if(!@is_item_armorstand_exists && array_size(get_scoreboard_tags(@unknown_armorstand)) == 1 && get_scoreboard_tags(@unknown_armorstand)[0] == 'enchanted_item') {
        @item_armorstand = @unknown_armorstand
        @is_item_armorstand_exists = true
      } else {
        #broadcast('B 아이템 아머스탠드 이외의 아머스탠드 감지!')
      }
    }
    if(!@is_item_armorstand_exists) {
      @item_armorstand = spawn_entity('ARMOR_STAND', 1, @item_location, closure(@item_armorstand) {
        set_entity_spec(@item_armorstand, array(
          'gravity': false,
          'marker': true,
          'visible': false,
          'poses': array(
            'poseHead': array(
              'x': to_radians(90),
              'y': to_radians(0),
              'z': to_radians(0)
            )
          )
        ))
        set_mob_name(@item_armorstand, '0')
        add_scoreboard_tag(@item_armorstand, 'enchanted_item')
      })[0]
    }
  }
  return(@item_armorstand)
}

proc _preset_essence_armorstand(@essence_location) {
  @essence_armorstands = entities_in_radius(@essence_location, 0, 'ARMOR_STAND')
  if(array_size(@essence_armorstands) == 0) {
    @essence_armorstand = spawn_entity('ARMOR_STAND', 1, @essence_location, closure(@essence_armorstand) {
      set_entity_spec(@essence_armorstand, array(
        'gravity': false,
        'marker': true,
        'visible': false,
        'poses': array(
          'poseHead': array(
            'x': to_radians(0),
            'y': to_radians(0),
            'z': to_radians(90)
          )
        )
      ))
      add_scoreboard_tag(@essence_armorstand, 'enchanted_essence')
    })[0]
  } else {
    @is_essence_armorstand_exists = false
    foreach(@unknown_armorstand in @essence_armorstands) {
      if(!@is_essence_armorstand_exists && array_size(get_scoreboard_tags(@unknown_armorstand)) == 1 && get_scoreboard_tags(@unknown_armorstand)[0] == 'enchanted_essence') {
        @essence_armorstand = @unknown_armorstand
        @is_essence_armorstand_exists = true
      } else {
        #broadcast('B 아이템 아머스탠드 이외의 아머스탠드 감지!')
      }
    }
    if(!@is_essence_armorstand_exists) {
      @essence_armorstand = spawn_entity('ARMOR_STAND', 1, @essence_location, closure(@essence_armorstand) {
        set_entity_spec(@essence_armorstand, array(
          'gravity': false,
          'marker': true,
          'visible': false,
          'poses': array(
            'poseHead': array(
              'x': to_radians(0),
              'y': to_radians(0),
              'z': to_radians(90)
            )
          )
        ))
        add_scoreboard_tag(@essence_armorstand, 'enchanted_essence')
      })[0]
    }
  }
  #set_timeout(1, closure() {
  #  set_mob_equipment(@essence_armorstand, array(
  #    'HELMET': null
  #  ))
  #})
  return(@essence_armorstand)
}