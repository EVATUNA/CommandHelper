






proc _get_empty_inventory(@width, @height) {
  if(@width < 1) {@width = 1}
  if(@width > 5) {@width = 5}
  if(@height < 1) {@height = 1}
  if(@height > 3) {@height = 3}

  @structure_void = array(
    'name': 'STRUCTURE_VOID',
    'meta': array(
      'display': ' ',
      'model': 1
    )
  )
  @air = array(
    'name': 'AIR'
  )

  @set_line = array()
  @empty_line = array()
  for(@index = 0, @index < 9, @index++) {
    if(!(@index > 4 - @width && @index < 4 + @width)) {
      @item = @structure_void
    } else {
      @item = @air
    }
    @set_line[] = @item
    @empty_line[] = @structure_void
  }

  switch(@height) {
  case 1:
    @items = array_merge(@empty_line, @set_line, @empty_line)
    break()
  case 2:
    @items = array_merge(@set_line, @set_line, @empty_line)
    break()
  case 3:
    @items = array_merge(@set_line, @set_line, @set_line)
    break()
  }

  return(@items)
}

proc _open_bag(@player, @uuid, @bag_item, @bag_slot, @text) {
  if(is_array(@bag_item['meta']) && array_index_exists(@bag_item['meta'], 'inventory') && is_array(@bag_item['meta']['inventory'])) {
    # GUI 내용물
    @inventory = @bag_item['meta']['inventory']
    # GUI 백그라운드 세팅
    @texture_layer = @text['space_fonts']['space.-1']
    for(@index = 0, @index < 27, @index++) {
      if(array_index_exists(@inventory, @index) && is_array(@inventory[@index]) && @inventory[@index]['name'] == 'STRUCTURE_VOID') {
        switch(integer(@index / 9)) {
        case 0:
          @texture_layer.= '\ue540'.@text['space_fonts']['space.-1']
          break();
        case 1:
          @texture_layer.= '\ue5a0'.@text['space_fonts']['space.-1']
          break();
        case 2:
          @texture_layer.= '\ue600'.@text['space_fonts']['space.-1']
          break();
        }
      } else {
        @texture_layer.= @text['space_fonts']['space.18']
      }
      if(@index != 1 && (@index + 1) % 9 == 0) {
        @texture_layer.= @text['space_fonts']['space.-162']
      }
    }
    @texture_layer.= @text['space_fonts']['space.1']
    # GUI 이름 세팅
    @message = '§7가방'
    if(array_index_exists(@bag_item['meta'], 'display') && !is_null(@bag_item['meta']['display'])) {
      @message = '§7'.strip_colors(@bag_item['meta']['display'])
    }
    # 열고 있는 가방 뷰어
    @bag_item['meta']['model'] = integer(@bag_item['meta']['model'] / 2) * 2 + 1
    set_inventory_item(@uuid, @bag_slot, @bag_item)
    # 가방 화리/블리 불러오기
    @allowed_items = array('SALMON', 'TROPICAL_FISH', 'PUFFERFISH')
    @unallowed_items = array('TRAPPED_CHEST', 'SHULKER_BOX', 'WHITE_SHULKER_BOX', 'ORANGE_SHULKER_BOX', 'MAGENTA_SHULKER_BOX', 'LIGHT_BLUE_SHULKER_BOX', 'YELLOW_SHULKER_BOX', 'LIME_SHULKER_BOX', 'PINK_SHULKER_BOX', 'GRAY_SHULKER_BOX', 'LIGHT_GRAY_SHULKER_BOX', 'CYAN_SHULKER_BOX', 'PURPLE_SHULKER_BOX', 'BLUE_SHULKER_BOX', 'BROWN_SHULKER_BOX', 'GREEN_SHULKER_BOX', 'RED_SHULKER_BOX', 'BLACK_SHULKER_BOX')
    # GUI 시스템
    @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @bag_item, @bag_slot, @allowed_items, @text) {
      bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @id, @bag_item, @bag_slot, @allowed_items, @unallowed_items, @text) {
        @slot_item = @event['slotitem']
        @clicked_slot = @event['slot']
        @is_bag_click = false
        if((is_array(@slot_item) && @slot_item['name'] == 'STRUCTURE_VOID') || @clicked_slot == @bag_slot) {
          cancel()
        } else {
          switch(@event['action']) {
          case 'HOTBAR_SWAP':
            @button = @event['hotbarbutton']
            if(@button == -1) { @button = 40 }
            @button_item = get_inventory_item(@uuid, @button)
            if(@button == @bag_slot) {
              cancel()
            } else {
              if(@event['rawslot'] < 27) {
                if((array_size(@allowed_items) != 0 && is_array(@button_item) && !array_contains(@allowed_items, @button_item['name'])) || (array_size(@allowed_items) == 0 && is_array(@button_item) && array_contains(@unallowed_items, @button_item['name']))) {
                  cancel()
                } else {
                  @is_bag_click = true
                }
              }
            }
            break()
          case 'MOVE_TO_OTHER_INVENTORY':
            if(@event['rawslot'] >= 27) {
              if((array_size(@allowed_items) != 0 && is_array(@slot_item) && !array_contains(@allowed_items, @slot_item['name'])) || (array_size(@allowed_items) == 0 && is_array(@slot_item) && array_contains(@unallowed_items, @slot_item['name']))) {
                cancel()
              } else {
                @is_bag_click = true
              }
            } else {
              @is_bag_click = true
            }
            break()
          case 'PLACE_ONE':
          case 'PLACE_ALL':
          case 'SWAP_WITH_CURSOR':
            @cursor_item = @event['cursoritem']
            if(@event['rawslot'] < 27) {
              if((array_size(@allowed_items) != 0 && is_array(@cursor_item) && !array_contains(@allowed_items, @cursor_item['name'])) || (array_size(@allowed_items) == 0 && is_array(@cursor_item) && array_contains(@unallowed_items, @cursor_item['name']))) {
                cancel()
              } else {
                @is_bag_click = true
              }
            }
            break()
          case 'PICKUP_HALF':
          case 'PICKUP_ALL':
          case 'DROP_ALL_SLOT':
          case 'DROP_ONE_SLOT':
            if(@event['rawslot'] < 27) {
              @is_bag_click = true
            }
            break()
          case 'COLLECT_TO_CURSOR':
            @cursor_item = @event['cursoritem']
            if((array_size(@allowed_items) != 0 && is_array(@cursor_item) && !array_contains(@allowed_items, @cursor_item['name'])) || (array_size(@allowed_items) == 0 && is_array(@cursor_item) && array_contains(@unallowed_items, @cursor_item['name']))) {
              cancel()
            } else {
              @is_bag_click = true
            }
            break()
          }
        }
        if(@is_bag_click) {
          set_timeout(0, closure() {
            @bag_item['meta']['inventory'] = get_inventory(@id)
            set_inventory_item(@uuid, @bag_slot, @bag_item)
          })
        }
      }
      bind('inventory_drag', array('id': "drag.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @bag_item, @bag_slot, @allowed_items, @unallowed_items, @text) {
        if(@event['player'] == @player) {
          @is_bag_click = false
          @cursor_item = @event['oldcursoritem']
          if((array_size(@allowed_items) != 0 && is_array(@cursor_item) && !array_contains(@allowed_items, @cursor_item['name'])) || (array_size(@allowed_items) == 0 && is_array(@cursor_item) && array_contains(@unallowed_items, @cursor_item['name']))) {
            foreach(@raw_slot in @event['rawslots']) {
              if(@raw_slot < 27) {
                cancel()
                break()
              }
            }
          } else {
            foreach(@raw_slot in @event['rawslots']) {
              if(@raw_slot < 27) {
                @is_bag_click = true
                break()
              }
            }
          }
          if(@is_bag_click) {
            set_timeout(0, closure() {
              @bag_item['meta']['inventory'] = get_inventory(@id)
              set_inventory_item(@uuid, @bag_slot, @bag_item)
            })
          }
        }
      }
      bind('inventory_close', array('id': "close.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @bag_item, @bag_slot, @allowed_items, @text) {
        if(@event['player'] == @player) {
          @bag_item['meta']['inventory'] = @event['inventory']
          @bag_item['meta']['model'] = integer(@bag_item['meta']['model'] / 2) * 2
          set_inventory_item(@uuid, @bag_slot, @bag_item)
        }
      }
    }
    # GUI 보여주기
    close_pinv(@player)
    _show_gui(@player, 'bag', 27, @texture_layer, @message, @inventory, @closure, @uuid, @bag_item, @bag_slot, @allowed_items, @text)

  }

}

bind('inventory_click', null, array('slotitem': 'TRAPPED_CHEST', 'clicktype': 'SHIFT_RIGHT'), @event, @players_data, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid)) {
    cancel()
    @container_slot = @event['rawslot'] - @event['inventorysize']
    if(@event['inventorytype'] == 'CRAFTING') {@container_slot -= 4}
    if(@container_slot >= 0 && @container_slot < 36) {
      @bag_item = @event['slotitem']
      @bag_slot = @event['slot']
      if(is_array(@bag_item['meta']) && !is_null(@bag_item['meta']['model'])) {
        _open_bag(@player, @uuid, @bag_item, @bag_slot, @text)
      }


    } else {
      // 해당 칸의 가방 열수 없다는 메시지
    }
    //  _open_fishing_rod_gui(@player, @@slot = @event['rawslot']uuid, @slot_item, @text)
  }
}