# 데스패널티 저장
@files = list_files('death_penalties')
foreach(@file in @files) {
  @file_path = "death_penalties/@file"
  @file_name_and_extension = _get_file_name_and_extension(@file)
  @file_name = @file_name_and_extension[0]
  @file_extension = @file_name_and_extension[1]
  if(@file_extension == 'json') {
    async_read_file(@file_path, closure(@content) {
      @death_penalties_multiply[@file_name] = json_decode(@content)
    })
  }
}

proc _apply_death_penalty(@player, @uuid, @death_penalties_multiply, @players_data, @server) {
  @death_penalties_multiply = array_deep_clone(@death_penalties_multiply)
  @inventory = get_inventory(@uuid)
  modify_event('death_message', null)
  if(array_index_exists(@players_data, @uuid)) {
    if(@server == 'over') {
      @player_data = @players_data[@uuid]
      @skill_manager = @player_data['skill_manager']
      @level = @skill_manager[0]
      if(@level < 5) {
        @level_disadvantage = @level * 0.2
      } else {
        @level_disadvantage = 1.0
      }
    } else {
      @level_disadvantage = 1.0
    }
  } else {
    @level_disadvantage = 0
  }
  if(@server != 'main') {
    if(array_index_exists(@players_data, @uuid, 'item', 'enchantments', 'armor') && @players_data[@uuid]['item']['enchantments']['armor'] == '귀속') {
      tmsg(@player, '💀 §7데스패널티로 약 '.integer(round(((1 - @death_penalties_multiply[@server]['default']['multiply']) * 50) * @level_disadvantage)).'%의 아이템이 소실되었습니다..')
    } else {
      tmsg(@player, '💀 §7데스패널티로 약 '.integer(round(((1 - @death_penalties_multiply[@server]['default']['multiply']) * 100) * @level_disadvantage)).'%의 아이템이 소실되었습니다..')
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
      @death_penalty_multiply['deviation'] *= @level_disadvantage
      @death_penalty_multiply['multiply'] = 1 - (1 - @death_penalty_multiply['multiply']) * @level_disadvantage
      
      if(@death_penalty_multiply['multiply'] >= 1) {
        @death_penalty_multiply['multiply'] = 1
        @death_penalty_multiply['deviation'] = 0
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

// 사망시 추가적으로 프로시저 사용시 event.ms로 옮겨야 함
bind('player_death', null, null, @event, @death_penalties_multiply, @players_data, @server) {
  @player = @event['player']
  @uuid = puuid(@player)
  _apply_death_penalty(@player, @uuid, @death_penalties_multiply, @players_data, @server)
}

# 필드 효과, 마법경험치 획득 조정 등
# 특정 월드에서 발생하는것 처리

if(@server == 'nether') {
  bind('block_dispense', null, null, @event, @server) {
    @item = @event['item']
    if(is_array(@item)) {
      if(@server == 'nether' && array_contains(array('PUFFERFISH_BUCKET', 'SALMON_BUCKET', 'COD_BUCKET', 'TROPICAL_FISH_BUCKET', 'AXOLOTL_BUCKET', 'WATER_BUCKET', 'POWDER_SNOW_BUCKET'), @item['name'])) {
        cancel()
      }
      if(@item['name'] == 'EGG') {
        cancel()
      }
    }
  }

  bind('block_explode', null, null, @event) {
    _debugmsg(@event)
  }
  
}


//bind('item_spawn', null, null, @event) {
  //@location = @event['location']
  //broadcast(entities_in_radius(@location, 1, 'CHICKEN'))
  //if(@event['type'] == 'DROPPED_ITEM') {
    //broadcast(@event)
  //}
//}