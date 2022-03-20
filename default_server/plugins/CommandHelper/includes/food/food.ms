@food_datas = array()
@files = list_files('foods')
foreach(@file in @files) {
  @file_path = "foods/@file"
  @file_name_and_extension = _get_file_name_and_extension(@file)
  @file_name = @file_name_and_extension[0]
  @file_extension = @file_name_and_extension[1]
  if(@file_extension == 'json') {
    async_read_file(@file_path, closure(@content) {
      foreach(@food_name: @food_data in json_decode(@content)) {
        //@namespace = "@file_name:@food_name"
        @food_datas[@food_name] = @food_data
      }
    })
  }
}


proc _add_health(@player, @amount) {
  @uuid = puuid(@player)
  @max_health = get_max_health(@uuid)
  @new_amount = phealth(@player) + @amount
  if(@new_amount > @max_health) {
    @new_amount = @max_health
  } else if(@new_amount < 0) {
    @new_amount = 0
  }
  set_phealth(@player, @new_amount)
}

proc _add_hunger(@player, @amount) {
  @new_amount = phunger(@player) + @amount
  if(@new_amount > 20) {
    @new_amount = 20
  } else if(@new_amount < 0) {
    @new_amount = 0
  }
  set_phunger(@player, @new_amount)
}

proc _add_saturation(@player, @amount) {
    @new_amount = psaturation(@player) + @amount
  if(@new_amount > 20) {
    @new_amount = 20
  } else if(@new_amount < 0) {
    @new_amount = 0
  }
  set_psaturation(@player, @new_amount)
}

bind('player_interact', null, array('itemname': 'HONEY_BOTTLE', 'button': 'right'), @event, @food_datas) {
  @player = @event['player']
  @uuid = puuid(@player)
  @is_item_available = true
  if(@event['action'] == 'right_click_block') {
    if(material_info(@event['block'], 'isInteractable')) {
      if(!psneaking(@player)) {
        if(@is_item_available) {
          @is_item_available = false
        }
      }
    }
  }
  if(@is_item_available) {
    if(@event['hand'] == 'main_hand') {
      @slot = pheld_slot(@player)
    } else {
      @slot = 40
    }
    unbind("eat.@uuid")
    bind('player_consume', array('id': "eat.@uuid"), array('itemname': 'HONEY_BOTTLE'), @event, @player, @uuid, @slot, @food_datas) {
      if(@player == @event['player']) {
        @item = get_inventory_item(@uuid, @slot)
        cancel()
        if(array_index_exists(@item, 'meta', 'display')) {
          @itemname = strip_colors(@item['meta']['display'])
          if(array_index_exists(@food_datas, @itemname)) {
            @food_data = @food_datas[@itemname]
            if(array_index_exists(@food_data, 'health')) {
              _add_health(@player, @food_data['health'])
            }
            if(array_index_exists(@food_data, 'hunger')) {
              _add_hunger(@player, @food_data['hunger'])
            }
            if(array_index_exists(@food_data, 'saturation')) {
              _add_saturation(@player, @food_data['saturation'])
            }
            if(array_index_exists(@food_data, 'cooldown')) {
              set_pcooldown(@player, 'HONEY_BOTTLE', @food_data['cooldown'])
            }
          }
        }
        if(pmode(@player) != 'CREATIVE') {
          @item['qty'] -= 1
          set_inventory_item(@uuid, @slot, @item)
        }
        unbind()
      }
    }
  }
}

bind('entity_regain_health', null, null, @event) {
  if(@event['reason'] == 'SATIATED') {
    cancel()
  } else if(@event['reason'] == 'MAGIC' && @event['amount'] == 0) {
    modify_event('amount', 0.125)
  }
}