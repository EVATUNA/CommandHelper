proc _get_result_item_rank(@rankable_ingredient_items, @ingredient_items) { #등급있는 재료아이템 종류, 실제 조합하는 재료 아이템들
  @ingredient_item_ranks = array()
  foreach(@ingredient_item in @ingredient_items) {
    if(array_contains(@rankable_ingredient_items, @ingredient_item['name'])) {###등급광석이 있을 시
      @ingredient_item_rank = 0.2
      if(is_array(@ingredient_item['meta']) && array_index_exists(@ingredient_item['meta'], 'model')) {
        switch(@ingredient_item['meta']['model']) {
        case 1:
          @ingredient_rank = 0.2
        case 2:
          @ingredient_item_rank = 0.4
        case 3:
          @ingredient_item_rank = 0.6
        case 4:
          @ingredient_item_rank = 0.8
        default:
          @ingredient_item_rank = 0.2
        }
      }
      @ingredient_item_ranks[] = @ingredient_item_rank
    }
  }
  @ingredient_item_average_rank = average(@ingredient_item_ranks)
  @result_item_rank = round(@ingredient_item_average_rank + rand() * 0.4 - 0.2, 5)
  return(@result_item_rank)
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
    'WEAPON': array('IRON_SWORD', 'IRON_PICKAXE', 'IRON_AXE', 'DIAMOND_SWORD', 'DIAMOND_PICKAXE', 'DIAMOND_AXE', 'NETHERITE_SWORD', 'NETHERITE_PICKAXE', 'NETHERITE_AXE', 'TRIDENT'),
    'BOOTS': array('IRON_BOOTS', 'DIAMOND_BOOTS', 'NETHERITE_BOOTS'),
    'LEGGINGS': array('IRON_LEGGINGS', 'DIAMOND_LEGGINGS', 'NETHERITE_LEGGINGS'),
    'CHESTPLATE': array('IRON_CHESTPLATE', 'DIAMOND_CHESTPLATE', 'NETHERITE_CHESTPLATE'),
    'HELMET': array('IRON_HELMET', 'DIAMOND_HELMET', 'NETHERITE_HELMET')
  ) #하드코딩 ㅎㅎ 이정도는..
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
    @modified_item['meta']['display'] = '§r'.@entry['display']
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
        if(@final_amount > 0) {
          @icon = ''
        } else {
          @icon = ''
        }
        @icon_amount = abs(integer(round(@final_amount / 2)))
        if(@icon_amount <= 0 ) {
          @icon_amount = 1
        }
        @icon_data = array(
          'icon': @icon,
          'amount': @icon_amount,
          'rounded_amount': round(@final_amount, 2)
        )
        if(@icon_data['amount'] > @max_icon_amount) {
          @max_icon_amount = @icon_data['amount']
        }
        @icon_datas[] = @icon_data
      case 'attack_damage':
        @ch_attribute = 'GENERIC_ATTACK_DAMAGE'
        @operation = 'ADD_NUMBER'
        if(@slot == 'WEAPON') {
          @damage_int = 1
        } else {
          @damage_int = 0
        }
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min']) - @damage_int
        } else {
          @final_amount = @amount - @damage_int
        }
        @icon_data = array(
          'icon': '',
          'amount': integer(round((@final_amount + @damage_int) / 2)),
          'rounded_amount': round(@final_amount + @damage_int, 2)
        )
        if(@icon_data['amount'] > @max_icon_amount) {
          @max_icon_amount = @icon_data['amount']
        }
        @icon_datas[] = @icon_data
      case 'attack_speed':
        @ch_attribute = 'GENERIC_ATTACK_SPEED'
        @operation = 'ADD_NUMBER'
        if(@slot == 'WEAPON') {
          @speed_int = 4
        } else {
          @speed_int = 0
        }
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min']) - @speed_int
        } else {
          @final_amount = @amount - @speed_int
        }
        @icon_data = array(
          'icon': '',
          'amount': integer(round((@final_amount + @speed_int) * 2)),
          'rounded_amount': round(@final_amount + @speed_int, 2)
        )
        if(@icon_data['amount'] > @max_icon_amount) {
          @max_icon_amount = @icon_data['amount']
        }
        @icon_datas[] = @icon_data
      case 'max_health':
        @ch_attribute = 'GENERIC_MAX_HEALTH'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        if(@final_amount > 0) {
          @icon = ''
        } else {
          @icon = ''
        }
        @icon_amount = abs(integer(round(@final_amount / 2)))
        if(@icon_amount <= 0) {
          @icon_amount = 1
        }
        @icon_data = array(
          'icon': @icon,
          'amount': @icon_amount,
          'rounded_amount': round(@final_amount, 2)
        )
        if(@icon_amount > @max_icon_amount) {
          @max_icon_amount = @icon_amount
        }
        @icon_datas[] = @icon_data
      case 'knockback_resistance':
        @ch_attribute = 'GENERIC_KNOCKBACK_RESISTANCE'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        if(@final_amount > 0) {
          @icon = '?'
        } else {
          @icon = '?'
        }
        @icon_amount = abs(integer(round(@final_amount / 2)))
        if(@icon_amount <= 0) {
          @icon_amount = 1
        }
        @icon_data = array(
          'icon': @icon,
          'amount': @icon_amount,
          'rounded_amount': round(@final_amount, 2)
        )
        if(@icon_amount > @max_icon_amount) {
          @max_icon_amount = @icon_amount
        }
        @icon_datas[] = @icon_data
      case 'luck':
        @ch_attribute = 'GENERIC_LUCK'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        if(@final_amount > 0) {
          @icon = ''
        } else {
          @icon = ''
        }
        @icon_amount = abs(integer(round(@final_amount * 2)))
        if(@icon_amount <= 0) {
          @icon_amount = 1
        }
        @icon_data = array(
          'icon': @icon,
          'amount': @icon_amount,
          'rounded_amount': round(@final_amount, 2)
        )
        if(@icon_amount > @max_icon_amount) {
          @max_icon_amount = @icon_amount
        }
        @icon_datas[] = @icon_data
      case 'movement_speed':
        @ch_attribute = 'GENERIC_MOVEMENT_SPEED'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        if(@final_amount > 0) {
          @icon = ''
        } else {
          @icon = ''
        }
        @icon_amount = abs(integer(round(@final_amount / 50)))
        if(@icon_amount <= 0) {
          @icon_amount = 1
        }
        @icon_data = array(
          'icon': @icon,
          'amount': @icon_amount,
          'rounded_amount': round(@final_amount, 3)
        )
        if(@icon_amount > @max_icon_amount) {
          @max_icon_amount = @icon_amount
        }
        @icon_datas[] = @icon_data
      case 'armor':
        @ch_attribute = 'GENERIC_ARMOR'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        if(@final_amount > 0) {
          @icon = ''
        } else {
          @icon = ''
        }
        @icon_amount = abs(integer(round(@final_amount / 2)))
        if(@icon_amount <= 0) {
          @icon_amount = 1
        }
        @icon_data = array(
          'icon': @icon,
          'amount': @icon_amount,
          'rounded_amount': round(@final_amount, 2)
        )
        if(@icon_amount > @max_icon_amount) {
          @max_icon_amount = @icon_amount
        }
        @icon_datas[] = @icon_data
      case 'armor_toughness':
        @ch_attribute = 'GENERIC_ARMOR_TOUGHNESS'
        @operation = 'ADD_NUMBER'
        if(is_array(@amount)) {
          @final_amount = @amount['min'] + rand() * (@amount['max'] - @amount['min'])
        } else {
          @final_amount = @amount
        }
        if(@final_amount > 0) {
          @icon = ''
        } else {
          @icon = ''
        }
        @icon_amount = abs(integer(round(@final_amount / 2)))
        if(@icon_amount <= 0) {
          @icon_amount = 1
        }
        @icon_data = array(
          'icon': @icon,
          'amount': @icon_amount,
          'rounded_amount': round(@final_amount, 2)
        )
        if(@icon_amount > @max_icon_amount) {
          @max_icon_amount = @icon_amount
        }
        @icon_datas[] = @icon_data
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
    @lore = array()
    @lore[] = '§f'.string_multiply('', @max_icon_amount + 1).''
    foreach(@icon_data in @icon_datas) {
      #broadcast(@icon_data['icon'])
      @lore[] = '§f'.string_multiply('', @max_icon_amount + 1).string_multiply('', @max_icon_amount + 1).string_multiply(''.@icon_data['icon'], @icon_data['amount']).string_multiply('', @max_icon_amount + 1 - @icon_data['amount']).' §8+'.string(@icon_data['rounded_amount'])
    }
    @lore[] = '§f'.string_multiply('', @max_icon_amount).''
    @lore[] = '§f'.string_multiply('', @max_icon_amount).''
    @modified_item['meta']['lore'] = @lore
  }
  return(@modified_item)
}