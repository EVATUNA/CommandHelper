console('EvaCrafting loaded')

## Crafting Data Load
@craftings = array()
foreach(@file in list_files('recipe_tables')) {
  @item = replace(@file, '.json', '')
  async_read('recipe_tables/'.@file, closure(@data) {
    @craftings[@item] = json_decode(@data)
    add_recipe(@craftings[@item]['recipe'])
  })
}

## Procedure
proc _get_result_item_rank(@ingredients_weight, @ingredient_items) { #등급있는 재료아이템 종류, 실제 조합하는 재료 아이템들
  if(array_size(@ingredients_weight) != 0) { #
    @ingredient_item_ranks = array()
    foreach(@ingredient_item in @ingredient_items) {
      if(array_index_exists(@ingredients_weight, @ingredient_item['name'])) {
        @ingredient_item_rank = 0.2 * @ingredients_weight[@ingredient_item['name']]
        if(is_array(@ingredient_item['meta']) && array_index_exists(@ingredient_item['meta'], 'model')) {
          switch(@ingredient_item['meta']['model']) {
          case 0:
            @ingredient_item_rank = 0.2 * @ingredients_weight[@ingredient_item['name']]
          case 1:
            @ingredient_item_rank = 0.4 * @ingredients_weight[@ingredient_item['name']]
          case 2:
            @ingredient_item_rank = 0.6 * @ingredients_weight[@ingredient_item['name']]
          case 3:
            @ingredient_item_rank = 0.8 * @ingredients_weight[@ingredient_item['name']]
          default:
            @ingredient_item_rank = 0.2 * @ingredients_weight[@ingredient_item['name']]
          }
        } else {
          @ingredient_item_rank = 0.2 * @ingredients_weight[@ingredient_item['name']]
        }
        @ingredient_item_ranks[] = @ingredient_item_rank
      }
    }
    @ingredient_item_average_rank = average(@ingredient_item_ranks)
    @result_item_rank = round(@ingredient_item_average_rank + rand() * 0.4 - 0.2, 5)
    return(@result_item_rank)
  } else {
    return(round(rand(), 5))
  }
}

proc _get_final_entry_from_first_entry(@entry, @result_item_rank, @luck) {
  #broadcast(@result_item_rank @luck)
  @type = @entry['type']
  switch(@type) {
  case 'entries_by_crafting_rank':
    @entries = @entry['entries']
    @total_weight = 0
    foreach(@key: @entry in @entries) {
      @weight = @entry['weight']
      @total_weight += @weight #weight 총합 선언
    }
    @result_weight = @total_weight * @result_item_rank
    @min_weight = 0
    @return = array('type': 'rank', 'display': '오류가 난 아이템') #범위안에 @result_weight가 들어가지 않을시
    foreach(@entry in @entries) {
      @weight = @entry['weight']
      @max_weight = @min_weight + @weight
      if(@max_weight > @result_weight) {
        if(@entry['type'] == 'rank') {
          @return = @entry
        } else {
          @return = _get_final_entry_from_first_entry(@entry, @result_item_rank, @luck)
        }
        break()
      } else {
        @min_weight = @max_weight
      }
    }
    return(@return)
  case 'entries_by_luck':
    @entries = @entry['entries']
    @total_weight = 0
    foreach(@key: @entry in @entries) {
      @weight = @entry['weight']
      if(array_index_exists(@entry, 'quality')) {
        @quality = @entry['quality']
      } else {
        @quality = 0
      }
      @weight = @weight + @quality * @luck #quality x 플래이어의 luck + weight
      if(@weight < 0) {
        @weight = 0
      }
      @entries[@key]['weight'] = @weight
      @total_weight += @weight
    } #weight 총합 계산
    @result_weight = @total_weight * round(rand(), 5)
    @min_weight = 0
    @return = array('type': 'rank', 'prefix': '오류가 난') #범위안에 @result_weight가 들어가지 않을시
    foreach(@entry in @entries) {
      @weight = @entry['weight']
      @max_weight = @min_weight + @weight
      if(@max_weight > @result_weight) {
        if(@entry['type'] == 'rank') {
          @return = @entry
        } else {
          @return = _get_final_entry_from_first_entry(@entry, @result_item_rank, @luck)
        }
        break()
      } else {
        @min_weight = @max_weight
      }
    }
    return(@return)
  case 'rank':
    return(@entry)
  default:
    broadcast('잘못된 json!즉시 json을 고치세요!', '*') #잘못된 타입을 작성함
  }
}

proc _get_modified_item(@entry, @item) {
  @items_slot = array(
    'WEAPON': array(
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
      
      'TRIDENT'
    ),
    'BOOTS': array('LEATHER_BOOTS', 'CHAINMAIL_BOOTS', 'IRON_BOOTS', 'DIAMOND_BOOTS', 'GOLDEN_BOOTS', 'NETHERITE_BOOTS')
  )
  foreach(@slot: @item_names in @items_slot) {
    foreach(@item_name in @item_names) {
      if(@item_name == @item['name']) {
        @item_slot = @slot
        break()
      }
    }
  }
  
  @modified_item = array('name': @item['name'], 'qty': @item['qty'], 'meta': array('flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES')))
  if(array_index_exists(@entry, 'display')) {
    @modified_item['meta']['display'] = '§f'.@entry['display']
  }
  if(array_index_exists(@entry, 'model')) {
    @modified_item['meta']['model'] = @entry['model']
  }
  if(array_index_exists(@entry, 'attributes')) {
    @attributes = @entry['attributes']
    @modifiers = array()
    @icon_datas = array()
    @max_icon_amount = 0
    @lore = array()
    foreach(@attribute: @amount in @attributes) {
      switch(@attribute) {
      case 'mining_power':
        @ch_attribute = 'HORSE_JUMP_STRENGTH'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        #갑옷일시, 곡괭이 일시에 따라서 다른 표기
        @lore[] = '§f\ue451 채굴 강도 '.string(round(@final_amount, 2))
      case 'farming_power':
        @ch_attribute = 'GENERIC_FOLLOW_RANGE'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        #갑옷일시, 괭이 일시에 따라서 다른 표기
        @lore[] = '§f\ue452 경작 강도 '.string(round(@final_amount, 2))
      case 'attack_damage':
        @ch_attribute = 'GENERIC_ATTACK_DAMAGE'
        @operation = 'ADD_NUMBER'
        if(@slot == 'WEAPON') {
          @damage_int = 1
          @string = ''
        } else {
          @damage_int = 0
          @string = '+'
        }
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min']) - @damage_int
        } else {
          @final_amount = @amount - @damage_int
        }
        @lore[] = '§f\ue44e 공격 피해 '.@string.string(round(@final_amount + @damage_int, 2))
      case 'attack_speed':
        @ch_attribute = 'GENERIC_ATTACK_SPEED'
        @operation = 'ADD_NUMBER'
        if(@slot == 'WEAPON') {
          @speed_int = 4
          @string = ''
        } else {
          @speed_int = 0
          @string = '+'
        }
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min']) - @speed_int
        } else {
          @final_amount = @amount - @speed_int
        }
        @lore[] = '§f\ue44f 공격 속도 '.@string.string(round(@final_amount + @speed_int, 2))
      case 'max_health':
        @ch_attribute = 'GENERIC_MAX_HEALTH'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @lore[] = '§7ㅁ 최대 체력 +'.string(round(@final_amount, 2))
      case 'knockback_resistance':
        @ch_attribute = 'GENERIC_KNOCKBACK_RESISTANCE'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @lore[] = '§7ㅁ 밀치기 저항 '.string(round(@final_amount, 2))
      case 'luck':
        @ch_attribute = 'GENERIC_LUCK'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @lore[] = '§7ㅁ 행운 +'.string(round(@final_amount, 2))
      case 'movement_speed':
        @ch_attribute = 'GENERIC_MOVEMENT_SPEED'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @lore[] = '§7ㅁ 속도 증가 +'.string(round(@final_amount, 2)) ### 나누기 50 한거 보여주기..?
      case 'armor':
        @ch_attribute = 'GENERIC_ARMOR'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @lore[] = '§7\ue453 방어 '.string(round(@final_amount, 2))
      case 'armor_toughness':
        @ch_attribute = 'GENERIC_ARMOR_TOUGHNESS'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @lore[] = '§7\ue454 방어 강도 '.string(round(@final_amount, 2))
      default:
        broadcast('알수 없는 어트리뷰트를 발견하였습니다. 즉시 수정하세요.', '*')
      }
      @modifiers[] = array(
        'attribute': @ch_attribute,
        'operation': @operation,
        'amount': @final_amount,
        'slot': @item_slot
      )
    }
    @modified_item['meta']['modifiers'] = @modifiers
    @modified_item['meta']['lore'] = @lore
  }
  return(@modified_item)
}

## Bind
bind('inventory_click', array('id': 'crafting'), array('slottype': 'RESULT'), @event, @craftings) {
  if(@event['inventorytype'] == 'WORKBENCH') {
    @player = @event['player']
    @uuid = puuid(@player)
    @inventory = get_inventory(@uuid)
    array_remove(@inventory, 36)
    array_remove(@inventory, 37)
    array_remove(@inventory, 38)
    array_remove(@inventory, 39)
    array_remove(@inventory, 40)
    @result_item = @event['slotitem'] #조합결과 템
    if(!is_null(@result_item) && !is_null(@result_item['meta']) && array_index_exists(@result_item['meta'], 'display')) {
      @crafting = @craftings[strip_colors(@result_item['meta']['display'])]
      @recipe = @crafting['recipe']
      @ranking_craftable = false
      if(!is_null(@event['cursoritem'])) {
        if(array_contains(array('SHIFT_LEFT', 'SHIFT_RIGHT'), @event['clicktype']) && array_contains(@inventory, null)) {
          cancel()
        } else if(array_contains(array('DROP', 'CONTROL_DROP'), @event['clicktype'])) {
          @ranking_craftable = false
        } else {
          @ranking_craftable = false
        }
      } else {
        if(array_contains(array('SHIFT_LEFT', 'SHIFT_RIGHT'), @event['clicktype']) && array_contains(@inventory, null)) {
            cancel()
        } else if(array_contains(array('DROP', 'CONTROL_DROP'), @event['clicktype'])) {
          @ranking_craftable = true
        } else if(array_contains(array('LEFT', 'RIGHT'), @event['clicktype'])) {
          @ranking_craftable = true
        } else if(@event['clicktype'] == 'NUMBER_KEY') {
          @button = @event['hotbarbutton']
          @hotbar = array(0: @inventory[0], 1: @inventory[1], 2: @inventory[2], 3: @inventory[3], 4: @inventory[4], 5: @inventory[5], 6: @inventory[6], 7: @inventory[7], 8: @inventory[8])
          if(is_null(@hotbar[@event['hotbarbutton']])) {
            @ranking_craftable = true
          } else {
            @ranking_craftable = false
          }
        }
      }
      if(@ranking_craftable) {
        @ingredient_items = array()
        foreach(@key: @ingredient_item in @event['inventory']) {
          if(@key != 0 && !is_null(@ingredient_item)) {
            @ingredient_items[] = @ingredient_item
          }
        }
        @result_item_rank = _get_result_item_rank(@recipe['ingredients_weight'], @ingredient_items) //레시피에 포함된 재료템들 등급에 따라 결과물 등급"수치" 결정
        @luck = entity_attribute_value(puuid(@player), 'GENERIC_LUCK') //제작 스킬 생길시 제작 스킬에 따른 럭 보너스 더하기
        @first_entry = @crafting['pool']
        if(array_index_exists(@first_entry, 'type')) {
          @final_entry = _get_final_entry_from_first_entry(@first_entry, @result_item_rank, @luck)
          @modified_item = _get_modified_item(@final_entry, @result_item)
          modify_event('slotitem', @modified_item)
        } else {
          broadcast('잘못된 json!', '*') #타입을 작성하지 않음
        }
      }
    }
  }
}

## additional recipes
@triming_small_fish = array(
  'key': 'triming_small_fish',
  'type': 'SHAPELESS',
  'result': array( 'name': 'COD' ),
  'ingredients': array('COD')
)
add_recipe(@triming_small_fish)
@triming_big_fish = array(
  'key': 'triming_big_fish',
  'type': 'SHAPELESS',
  'result': array( 'name': 'SALMON' ),
  'ingredients': array('SALMON')
)
add_recipe(@triming_big_fish)
