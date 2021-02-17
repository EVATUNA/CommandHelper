## Gameplay
console('EvaGameplay loaded')

## Include
include('crafting/main.ms')
include('enchant/main.ms')
include('skill/main.ms')

## Item Management
@effective_items = array(
  'armor': array(
    'LEATHER_CHESTPLATE',
    'CHAINMAIL_CHESTPLATE',
    'IRON_CHESTPLATE',
    'GOLDEN_CHESTPLATE',
    'DIAMOND_CHESTPLATE',
    'NETHERITE_CHESTPLATE'
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
    'SHIELD'
  )
)

bind('inventory_click', null, null, @event, @players_item, @effective_items) {
  @player = @event['player']
  @uuid = puuid(@player)
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
    if(@clicked_slot == 38) {
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
          if(@clicked_slot == 38) {
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
          } else if(is_null(get_inventory_item(@uuid, 38))) {
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
          } else if(@held_slot == @clicked_slot && !is_null(@players_item[@uuid]['main_hand'])) {
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
          } else if(@held_slot == @clicked_slot && !is_null(@players_item[@uuid]['main_hand']) && array_contains(@other_inventory, null)) {
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
        } else if(@held_slot == @clicked_slot && !is_null(@players_item[@uuid]['main_hand']) && array_contains(@other_inventory, null)) {
          @items['main_hand'] = null
        }
      }
    }
    break()
  case 'PICKUP_HALF':
  case 'PICKUP_ALL':
    if(@clicked_slot == @held_slot && !is_null(@players_item[@uuid]['main_hand'])) {
      @items['main_hand'] = null
    }
    if(pinventory_holder(@player) == @uuid && @clicked_slot == 40 && !is_null(@players_item[@uuid]['off_hand'])) {
      broadcast(A)
      @items['off_hand'] = null
    }
    if(pinventory_holder(@player) == @uuid && @clicked_slot == 38 && !is_null(@players_item[@uuid]['armor'])) {
      @items['armor'] = null
    }
    break()
  case 'PLACE_ONE':
  case 'PLACE_ALL':
  case 'SWAP_WITH_CURSOR':
    @cursor_item = @event['cursoritem']
    if(@clicked_slot == @held_slot && !is_null(@cursor_item) && array_contains(@effective_items['weapon'], @cursor_item['name'])) {
      @items['main_hand'] = @cursor_item
    }
    if(pinventory_holder(@player) == @uuid && @clicked_slot == 40 && !is_null(@cursor_item) && array_contains(@effective_items['weapon'], @cursor_item['name'])) {
      @items['off_hand'] = @cursor_item
    }
    if(pinventory_holder(@player) == @uuid && @clicked_slot == 38 && !is_null(@cursor_item) && array_contains(@effective_items['armor'], @cursor_item['name'])) {
      @items['armor'] = @cursor_item
    }
    break()
  case 'DROP_ALL_SLOT':
  case 'DROP_ONE_SLOT':
    if(!@players_item[@uuid]['is_inv_open']) {
      @players_item[@uuid]['is_inv_open'] = true
    }
    if(@clicked_slot == @held_slot && array_contains(@effective_items['weapon'], @slot_item['name'])) {
      @items['main_hand'] = null
    }
    if(pinventory_holder(@player) == @uuid && @clicked_slot == 40 && array_contains(@effective_items['weapon'], @slot_item['name'])) {
      @items['off_hand'] = null
    }
    if(pinventory_holder(@player) == @uuid && @clicked_slot == 38 && array_contains(@effective_items['armor'], @slot_item['name'])) {
      @items['armor'] = null
    }
    break()
  }
  if(array_size(@items) > 0) {
    _update_item(@player, @uuid, @items, @players_item)
  }
}

bind('inventory_open', null, null, @event, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  @players_item[@uuid]['is_inv_open'] = true
}

bind('inventory_close', null, null, @event, @players_item, @effective_items) {
  @player = @event['player']
  @uuid = puuid(@player)
  @players_item[@uuid]['is_inv_open'] = false
  @items = array()
  @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
  if(!is_null(@main_hand_item) && array_contains(@effective_items['weapon'], @main_hand_item['name'])) {
    @items['main_hand'] = @main_hand_item
  } else {
    @items['main_hand'] = null
  }
  @off_hand_item = get_inventory_item(@uuid, 40)
  if(!is_null(@off_hand_item) && array_contains(@effective_items['weapon'], @off_hand_item['name'])) {
    @items['main_hand'] = @off_hand_item
  } else {
    @items['main_hand'] = null
  }
  @armor_item = get_inventory_item(@uuid, 38)
  if(!is_null(@armor_item) && array_contains(@effective_items['armor'], @armor_item['name'])) {
    @items['armor'] = @armor_item
  } else {
    @items['armor'] = null
  }
  if(array_size(@items) > 0) {
    _update_item(@player, @uuid, @items, @players_item)
  }
}

bind('item_held', null, null, @event, @players_item, @effective_items) {
  @player = @event['player']
  @uuid = puuid(@player)
  @held_item = get_inventory_item(@uuid, @event['to'])
  if(!is_null(@held_item) && array_contains(@effective_items['weapon'], @held_item['name'])) {
    _update_item(@player, @uuid, array('main_hand': @held_item), @players_item)
  } else if(!is_null(@players_item[@uuid]['main_hand'])) {
    _update_item(@player, @uuid, array('main_hand': null), @players_item)
  }
}

bind('item_swap', null, null, @event, @players_item, @effective_items) {
  @player = @event['player']
  @uuid = puuid(@player)
  @items = array()
  @off_hand_item = get_inventory_item(@uuid, 40)
  if(!is_null(@off_hand_item) && array_contains(@effective_items['weapon'], @off_hand_item['name'])) {
    @items['main_hand'] = @off_hand_item
  } else if(!is_null(@players_item[@uuid]['main_hand'])) {
    @items['main_hand'] = null
  }
  @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
  if(!is_null(@main_hand_item) && array_contains(@effective_items['weapon'], @main_hand_item['name'])) {
    @items['off_hand'] = @main_hand_item
  } else if(!is_null(@players_item[@uuid]['off_hand'])) {
    @items['off_hand'] = null
  }
  if(array_size(@items) > 0) {
    _update_item(@player, @uuid, @items, @players_item)
  }
}

bind('item_drop', null, null, @event, @players_item, @effective_items) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!@players_item[@uuid]['is_inv_open']) {
    @held_item = @event['item']
    if(array_contains(@effective_items['weapon'], @held_item['name'])) {
      _update_item(@player, @uuid, array('main_hand': null), @players_item)
    }
  }
}

bind('item_pickup', null, null, @event, @players_item, @effective_items) {
  @player = @event['player']
  @uuid = puuid(@player)
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
      _update_item(@player, @uuid, array('main_hand': @event['item']), @players_item)
    }
  }
}

bind('item_damage', null, null, @event, @players_item, @effective_items) {
  @player = @event['player']
  @uuid = puuid(@player)
  @item = @event['item']
  @max_durability = material_info(@item['name'], 'maxDurability')
  if(is_null(@item['meta'])) {
    @durability = @event['damage']
  } else {
    @durability = @item['meta']['damage'] + @event['damage']
  }
  if(@durability >= @max_durability) {
    if(array_contains(@effective_items['armor'], @item['name'])) {
      _update_item(@player, @uuid, array('armor': null), @players_item)
    } else if(array_contains(@effective_items['weapon'], @item['name'])) {
      @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
      @off_hand_item = get_inventory_item(@uuid, 40)
      if(@item == @main_hand_item) {
        _update_item(@player, @uuid, array('main_hand': null), @players_item)
      } else if(@item == @off_hand_item) {
        _update_item(@player, @uuid, array('off_hand': null), @players_item)
      }
    }
  }
}

## Gui Management

bind('player_interact', null, array('main_hand': 'main_main_hand', 'button': 'right'), @event, @essences, @text) {
  if(is_cancelled()) {

  } else {
    @player = @event['player']
    if(!psneaking(@player)) {
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
                  'x': sprintf('%.5f', round((@location['x'] - @pos['x']) / 2, 5)),
                  'y': sprintf('%.5f', round((@location['y'] - @pos['y']) / 2, 5)),
                  'z': sprintf('%.5f', round((@location['z'] - @pos['z']) / 2, 5))
                )
                _particle(@player, 'minecraft:totem_of_undying', @pos, @delta, 1, 0)
                @task['tick'] -= 1
              } else {
                clear_task()
                play_named_sound(@location, array('sound': 'minecraft:block.enchantment_table.use', 'category': 'NEUTRAL', 'volume': 1, 'pitch': 1))
                set_plevel(@player, plevel(@player) - 30)
                @essence_name = array_rand(array('희미한 마법의 정수', '미약한 마법의 정수', '농축된 마법의 정수', '강력한 마법의 정수', '찬란한 마법의 정수'), 1, false)[0]
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
              @enchantable_armors = array(
                'LEATHER_CHESTPLATE': 1.5,
                'CHAINMAIL_CHESTPLATE': 0.5,
                'IRON_CHESTPLATE': 0.9,
                'GOLDEN_CHESTPLATE': 2.5,
                'DIAMOND_CHESTPLATE': 1.0,
                'NETHERITE_CHESTPLATE': 1.5
              )
              @enchantable_weapons = array(
                'WOODEN_SWORD': 1.0,
                'WOODEN_SHOVEL': 1.0,
                'WOODEN_PICKAXE': 1.0,
                'WOODEN_AXE': 1.0,
                'WOODEN_HOE': 1.0,
                'STONE_SWORD': 0.9,
                'STONE_SHOVEL': 0.9,
                'STONE_PICKAXE': 0.9,
                'STONE_AXE': 0.9,
                'STONE_HOE': 0.9,
                'IRON_SWORD': 1.4,
                'IRON_SHOVEL': 1.4,
                'IRON_PICKAXE': 1.4,
                'IRON_AXE': 1.4,
                'IRON_HOE': 1.4,
                'GOLDEN_SWORD': 2.2,
                'GOLDEN_SHOVEL': 2.2,
                'GOLDEN_PICKAXE': 2.2,
                'GOLDEN_AXE': 2.2,
                'GOLDEN_HOE': 2.2,
                'DIAMOND_SWORD': 1.0,
                'DIAMOND_SHOVEL': 1.0,
                'DIAMOND_PICKAXE': 1.0,
                'DIAMOND_AXE': 1.0,
                'DIAMOND_HOE': 1.0,
                'NETHERITE_SWORD': 1.5,
                'NETHERITE_SHOVEL': 1.5,
                'NETHERITE_PICKAXE': 1.5,
                'NETHERITE_AXE': 1.5,
                'NETHERITE_HOE': 1.5,
                'TRIDENT': 1.0
              )
              @rawslot = @event['rawslot']
              if(@rawslot >= 0 && @rawslot <= 26) {
                @clicked_item = @event['inventory'][@rawslot]
                if(!is_null(@clicked_item) && @clicked_item['name'] == 'STRUCTURE_VOID') {
                  cancel()
                }
                @cursor_item = @event['cursoritem']
                if(!is_null(@cursor_item) && @cursor_item['name'] == 'ENCHANTED_BOOK' && @rawslot == 22 && @event['action'] == 'SWAP_WITH_CURSOR') {
                  @enchanting_item = @event['inventory'][@rawslot]
                  @enchanted_item = @enchanting_item
                  if(!is_null(@enchanting_item) && array_index_exists(@enchantable_weapons, @enchanting_item['name'])) {
                    @essence_name = strip_colors(@cursor_item['meta']['display'])
                    if(array_index_exists(@essences, @essence_name)) {
                      @entries = @essences[@essence_name]['entries']
                      @enchanted_item = _get_enchanted_item(@enchanting_item, @entries, @enchantable_weapons[@enchanting_item['name']])
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


bind('entity_damage', null, null, @event, @players_item) {
  if(array_index_exists(@event, 'damager') && ponline(@event['damager'])) { //플레이어가 타격시
    @player = @event['damager']
    @puuid = puuid(@player)
    @euuid = @event['id']
    #broadcast(@players_item[@puuid]['enchantments'])
    switch(@players_item[@puuid]['enchantments']['main_hand']) {
    case '전격':

      break()
    case '천둥':
    
      break()
    case '맹독':
      set_mob_effect(@euuid, 'POISON', 3, 1, false, true)
      break()
    case '부식':
      set_mob_effect(@euuid, 'WITHER', 3, 2, false, true)
      break()
    case '약화':
      set_mob_effect(@euuid, 'WEAKNESS', 0, 6, false, true)
      break()
    case '파멸':
      set_mob_effect(@euuid, 'WEAKNESS', 1, 6, false, true)
      if(rand() < 0.1) {
        set_mob_effect(@euuid, 'BLINDNESS', 0, 4, false, true)
      }
      break()
    case '서리':
      set_mob_effect(@euuid, 'SLOWNESS', 1, 6, false, true)
      break()
    case '빙결':
      set_mob_effect(@euuid, 'SLOWNESS', 1, 11, false, true)
      set_mob_effect(@euuid, 'SLOWNESS', 5, 4, false, true)
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
      if(array_contains(@undead_entities, entity_type(@euuid))) {
        set_mob_effect(@euuid, 'INSTANT_HEALTH', 1, 0.1, false, true)
      }
      break()
    default:
      @entity_location = entity_loc(@euuid)
      @ploc = ploc(@player)
      if(get_highest_block_at(@entity_location)['y'] - 1 < @entity_location['y'] || get_block(@entity_location) == 'WATER') {
        #broadcast (A)
      }
      @allowed_entity = array(
        'MAGMA_CUBE',
        'SILVERFISH',
        'MULE',
        'HOGLIN',
        'HUSK',
        'VINDICATOR',
        'PILLAGER',
        'SHULKER_BULLET',
        'VILLAGER',
        'TURTLE',
        'TRADER_LLAMA',
        'CAVE_SPIDER',
        'SLIME',
        'DROWNED',
        'EVOKER',
        'ENDERMITE',
        'PLAYER',
        'SALMON',
        'ZOMBIE',
        'STRIDER',
        'PANDA',
        "OCELOT",
        'ENDERMAN',
        'ZOMBIE_VILLAGER',
        'LLAMA',
        'ENDER_DRAGON',
        'WITCH',
        'WITHER',
        'CREEPER',
        'ILLUSIONER',
        'COD',
        'ZOMBIE_HORSE',
        'RAVAGER',
        'SHULKER',
        'BEE',
        'PHANTOM',
        'BLAZE',
        'SKELETON_HORSE',
        'COW',
        'WANDERING_TRADER',
        'PIG',
        'ZOGLIN',
        'WOLF',
        'IRON_GOLEM',
        'SHEEP',
        'VEX',
        'PIGLIN_BRUTE',
        'POLAR_BEAR',
        'SNOWMAN',
        'SQUID',
        'ELDER_GUARDIAN',
        'HORSE',
        'ARMOR_STAND',
        'PARROT',
        'FOX',
        'STRAY',
        'CAT',
        'RABBIT',
        'DONKEY',
        'ENDER_CRYSTAL',
        'TROPICAL_FISH',
        'SPIDER',
        'SKELETON',
        'WITHER_SKELETON',
        'MUSHROOM_COW',
        'CHICKEN',
        'ZOMBIFIED_PIGLIN',
        'PUFFERFISH',
        'GUARDIAN',
        'PIGLIN',
        'GHAST',
        'BAT',
        'DOLPHIN'
      )

      
      @near_entities = entities_in_radius(@entity_location, 5)
      array_remove_values(@near_entities, @puuid)
      array_remove_values(@near_entities, @euuid)
      @pos = array(
        'x': @entity_location['x'] + rand() / 2 - 0.25,
        'y': @entity_location['y'] + rand() * 1 + 0.5,
        'z': @entity_location['z'] + rand() / 2 - 0.25
      )
      _particle(@player, 'minecraft:firework', @pos, array('x': 0.2, 'y': 0.3, 'z': 0.2), 0.05, 3)
      foreach(@near_entity in @near_entities) {
        @pos = array(
          'x': @entity_location['x'] + rand() / 2 - 0.25,
          'y': @entity_location['y'] + rand() * 1,
          'z': @entity_location['z'] + rand() / 2 - 0.25
        )
        @near_entity_location = entity_loc(@near_entity)
        @near_entity_location['y'] += 0.8
        @delta = array(
          'x': sprintf('%.5f', round((@near_entity_location['x'] - @pos['x']) / 4, 5)),
          'y': sprintf('%.5f', round((@near_entity_location['y'] - @pos['y']) / 4, 5)),
          'z': sprintf('%.5f', round((@near_entity_location['z'] - @pos['z']) / 4, 5))
        )
        _particle(@player, 'minecraft:firework', @pos, @delta, 1, 0)
        damage_entity(@near_entity, 3)
      }

    }
  } else { //엔티티가 타격시

  }
}

bind('exp_change', null, null, @event, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  broadcast(@event)
  foreach(@slot: @enchantment in @players_item[@uuid][['enchantments']]) {
    switch(@enchantment) {
    case '풍요':
    case '치유':
    case '저항':
    case '친수성':
    case '반엔트로피':
    case '용력':
      break()
    default:
      broadcast(A) #/summon minecraft:experience_orb ~ ~ ~ {Value:10}
    }
  }

}