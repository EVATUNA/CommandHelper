## Crafting Data Load
@craftings = array()
foreach(@file in list_files('recipe_tables')) {
  @item = replace(@file, '.json', '')
  async_read('recipe_tables/'.@file, closure(@data) {
    @craftings[@item] = json_decode(@data)
    @recipe = @craftings[@item]['recipe']
    @converted_result = @ch_items['crafting'][@recipe['result']]
    @recipe['result'] = @converted_result
    if(array_index_exists(@recipe, 'key')) {
      add_recipe(@recipe)
    }
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

proc _get_final_entry_from_entries(@entry, @result_item_rank, @luck) {
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
          @return = _get_final_entry_from_entries(@entry, @result_item_rank, @luck)
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
          @return = _get_final_entry_from_entries(@entry, @result_item_rank, @luck)
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

      'BUCKET',
      'SHIELD',
      
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
  
  if(array_index_exists(@entry, 'alt_name')) {
    @modified_item['name'] = @entry['alt_name']
  }
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
      case 'defense_recovery':
        @ch_attribute = 'HORSE_JUMP_STRENGTH'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @string_amount = string(round(@final_amount, 2))
        @lore[] = "§f\ue454§7 @string_amount 방어 회복"
      case 'capacity':
        @ch_attribute = 'HORSE_JUMP_STRENGTH'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = integer(@amount['min'] + rand() * (@amount['max'] - @amount['min']))
        } else {
          @final_amount = integer(@amount)
        }
        @string_amount = string(@final_amount)
        @lore[] = "§f\ue451§7 @string_amount 용량"
      case 'mining_power':
        @ch_attribute = 'HORSE_JUMP_STRENGTH'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        #갑옷일시, 곡괭이 일시에 따라서 다른 표기
        @string_amount = string(round(@final_amount, 2))
        @lore[] = "§f\ue451§7 @string_amount 채굴 강도"
      case 'farming_power':
        @ch_attribute = 'GENERIC_FOLLOW_RANGE'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        #갑옷일시, 괭이 일시에 따라서 다른 표기
        @string_amount = string(round(@final_amount, 2))
        @lore[] = "§f\ue452§7 @string_amount 경작 강도"
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
        @string_amount = @string.string(round(@final_amount + @damage_int, 2))
        @lore[] = "§f\ue44e§7 @string_amount 공격 피해"
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
        @string_amount = @string.string(round(@final_amount + @speed_int, 2))
        @lore[] = "§f\ue44f§7 @string_amount 공격 속도"
      case 'max_health':
        @ch_attribute = 'GENERIC_MAX_HEALTH'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @string_amount = string(round(@final_amount, 2))
        @lore[] = "§fㅁ§7 + @string_amount 최대 체력"
      case 'knockback_resistance':
        @ch_attribute = 'GENERIC_KNOCKBACK_RESISTANCE'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @string_amount = string(round(@final_amount, 2))
        @lore[] = "§fㅁ§7 @string_amount 밀치기 저항"
      case 'luck':
        @ch_attribute = 'GENERIC_LUCK'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @string_amount = string(round(@final_amount, 2))
        @lore[] = "§fㅁ§7 + @string_amount 행운"
      case 'movement_speed':
        @ch_attribute = 'GENERIC_MOVEMENT_SPEED'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @string_amount = string(round(@final_amount, 2)) ### 나누기 50 한거 보여주기..?
        @lore[] = "§fㅁ§7 @string_amount 속도 증가"
      case 'armor':
        @ch_attribute = 'GENERIC_ARMOR'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @string_amount = string(round(@final_amount, 2))
        @lore[] = "§f\ue453§7 @string_amount 방어"
      case 'armor_toughness':
        @ch_attribute = 'GENERIC_ARMOR_TOUGHNESS'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        @string_amount = string(round(@final_amount, 2))
        @lore[] = "§f\ue454§7 @string_amount 방어 강도"
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
bind('inventory_click', array('priority': 'LOWEST', 'id': 'crafting'), array('slottype': 'RESULT'), @event, @craftings) {
  if(@event['inventorytype'] == 'WORKBENCH') {
    @player = @event['player']
    @uuid = puuid(@player)

    @inventory = get_inventory(@uuid)
    array_remove(@inventory, 36)
    array_remove(@inventory, 37)
    array_remove(@inventory, 38)
    array_remove(@inventory, 39)
    array_remove(@inventory, 40)

    @result_item = @event['slotitem']

    if(is_array(@result_item)) {
      if(array_index_exists(@result_item, 'meta', 'display')) {
        @result_item_name = strip_colors(@result_item['meta']['display'])
      } else {
        @result_item_name = @result_item['name']
      }
      if(array_index_exists(@craftings, @result_item_name)) {
        @crafting = @craftings[@result_item_name]

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
          @entries = @crafting['pool']
          if(array_index_exists(@entries, 'type')) {
            @final_entry = _get_final_entry_from_entries(@entries, @result_item_rank, @luck)
            if(array_index_exists(@final_entry, 'broadcast') && @final_entry['broadcast']) {
              @message = @player.'님께서 '.strip_colors(@final_entry['display']).'를 조합하셨습니다.'
              @prefix = '🎉'
              _send_instance_tooltip_system_broadcast(@player, @uuid, @prefix, @message, 5, 6)
            }
            @modified_item = _get_modified_item(@final_entry, @result_item)
            modify_event('slotitem', @modified_item)
          } else {
            broadcast('잘못된 json!', '*') #타입을 작성하지 않음
          }
        }
      }
    }

    /*
      if(!is_null(@result_item) && array_index_exists(@result_item, 'meta', 'display')) {
        @item_display = strip_colors(@result_item['meta']['display'])
        if(array_index_exists(@craftings, @item_display)) {
          @max_stack_size = max_stack_size(@result_item)
          # 재료 배열 만들기, 쉬프트 조합, 컨트롤 버리기 조합시 최대 갯수 지정
          @max_craftable_qty = 64
          @ingredient_items = array()
          foreach(@key: @ingredient_item in @event['inventory']) {
            if(@key != 0) {
              @ingredient_items[] = @ingredient_item
              if(is_array(@ingredient_item) && @ingredient_item['qty'] < @max_craftable_qty) {
                @max_craftable_qty = @ingredient_item['qty']
              }
            }
          }

          //broadcast(@ingredient_items @max_craftable_qty)
            //broadcast(@event['inventory'])
          if(is_null(@event['cursoritem'])) {
            @result_item['meta']['lore'][] = 'asdf'
            modify_event('slotitem', @result_item)
            cancel()

            //broadcast(@result_item)
            //modify_event('cursoritem', array(
            //  'name': 'STONE'
            //))
          } else {
            if(array_contains(array('SHIFT_LEFT', 'SHIFT_RIGHT'), @event['clicktype'])) {
              //modify_event('slotitem', array(name: STONE))
              //@crafted_qty = 0
              //for(@i = 0, @i < @max_craftable_qty, @i++) {
              //  @is_space_left = !pgive_item(@player, array(name: 'AIR'))
              //  if(@is_space_left) {
              //    pgive_item(@player, array(name: 'STONE_SWORD')) // 조합아이템 주는걸로 바꾸기
              //  } else {
              //    break()
              //  }
              //  @crafted_qty++
              //}
              //foreach(@index: @ingredient_item in @ingredient_items) {
              //  if(is_array(@ingredient_items[@index])) {
              //    @ingredient_items[@index]['qty'] -= @crafted_qty
              //    if(@ingredient_items[@index]['qty'] <= 0) {
              //      @ingredient_items[@index] = null
              //    }
              //  }
              //}
              //broadcast(@ingredient_items)
              //broadcast(@inventory)
              @inventory = get_inventory(pinventory_holder(@player))
              array_remove(@inventory, 36)
              array_remove(@inventory, 37)
              array_remove(@inventory, 38)
              array_remove(@inventory, 39)
              array_remove(@inventory, 40)
              broadcast(@inventory)
              //broadcast(A)
            } else if(array_contains(array('DROP', 'CONTROL_DROP'), @event['clicktype'])) {
              @ranking_craftable = false
              cancel()
              broadcast(B)
            } else {
              @ranking_craftable = false
              cancel()
            }
          }
        }
      }


    */
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