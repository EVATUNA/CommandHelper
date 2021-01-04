## Gameplay
console('EvaGameplay loaded')

## Data
@essences = array()

## Include
include('crafting/main.ms')
include('enchant/main.ms')
include('skill/main.ms')

## Enchant Management
bind('inventory_click', null, null, @event, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  @held_slot = pheld_slot(@player)
  @clicked_slot = @event['slot']
  #broadcast(@held_slot @event)
  switch(@event['action']) {
  case 'HOTBAR_SWAP':
    @button = @event['hotbarbutton']
    if(@button == @held_slot && @button != @clicked_slot && @button != -1) {
      @hand_item = get_inventory_item(@uuid, @clicked_slot)
      @players_item[@uuid]['hand'] = @hand_item
      #broadcast('인첸트 설정') #인첸트 적용, 액션메시지 적용
    } else if(@clicked_slot == @held_slot && @button != @clicked_slot  && @button != -1) {
      @hand_item = get_inventory_item(@uuid, @button)
      @players_item[@uuid]['hand'] = @hand_item
      #broadcast('인첸트 설정') #인첸트 적용, 액션메시지 적용
    } else if(@clicked_slot == @held_slot && @button == -1) {
      @hand_item = get_inventory_item(@uuid, 40)
      @players_item[@uuid]['hand'] = @hand_item
      #broadcast('인첸트 설정') #인첸트 적용, 액션메시지 적용
    }
    break()
  case 'MOVE_TO_OTHER_INVENTORY':
    if(@clicked_slot == @held_slot) {
      set_timeout(0, closure() {
        @hand_item = get_inventory_item(@uuid, @clicked_slot)
        if(is_null(@hand_item)) {
          @players_item[@uuid]['hand'] = @hand_item
          #broadcast('인첸트 설정')
          #인첸트 적용, 액션메시지 적용
        }
      })
    }
    break()
  case 'PICKUP_HALF':
  case 'PICKUP_ALL':
    if(@clicked_slot == @held_slot) {
      set_timeout(0, closure() {
        @hand_item = get_inventory_item(@uuid, @clicked_slot)
        if(is_null(@hand_item)) {
          @players_item[@uuid]['hand'] = @hand_item
          #broadcast('인첸트 설정')
          #인첸트 적용, 액션메시지 적용
        }
      })
    }
    break()
  case 'PLACE_ONE':
  case 'PLACE_ALL':
  case 'SWAP_WITH_CURSOR':
    if(@clicked_slot == @held_slot) {
      set_timeout(0, closure() {
        @hand_item = get_inventory_item(@uuid, @clicked_slot)
        @players_item[@uuid]['hand'] = @hand_item
        #broadcast('인첸트 설정')
        #인첸트 적용, 액션메시지 적용
      })
    }
    break()
  }
  #broadcast(@players_item)
}

bind('inventory_close', null, null, @event, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  @hand_item = get_inventory_item(@uuid, pheld_slot(@player))
  @armor_item = get_inventory_item(@uuid, 37)
  @players_item[@uuid]['hand'] = @hand_item
  @players_item[@uuid]['armor'] = @armor_item
  #broadcast('인첸트 설정')
  #인첸트 적용, 액션메시지 적용
}

bind('item_held', null, null, @event, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  @hand_item = get_inventory_item(@uuid, @event['to'])
  @players_item[@uuid]['hand'] = @hand_item
  #broadcast('인첸트 설정')
  #인첸트 적용, 액션메시지 적용
}

bind('item_swap', null, null, @event, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  @hand_item = get_inventory_item(@uuid, 40)
  @players_item[@uuid]['hand'] = @hand_item
  #broadcast(@players_item)
  #broadcast('인첸트 설정')
  #인첸트 적용, 액션메시지 적용
}

bind('item_drop', null, null, @event, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
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
  if(array_contains(@weapons, @event['item']['name']) && !is_null(@players_item[@uuid]['hand']) && @players_item[@uuid]['hand']['name'] == @event['item']['name']) {
    @hand_item = get_inventory_item(@uuid, pheld_slot(@player))
    @players_item[@uuid]['hand'] = @hand_item
    #broadcast(@players_item)
    #broadcast('인첸트 설정')
    #인첸트 적용, 액션메시지 적용
  }
}

bind('item_pickup', null, null, @event, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  @old_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
  set_timeout(0, closure() {
    @new_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
    if(@old_hand_item != @new_hand_item) {
      @players_item[@uuid]['hand'] = @new_hand_item
      #broadcast('인첸트 설정')
      #인첸트 적용, 액션메시지 적용
    }
  })
}

bind('item_damage', null, null, @event) {
  @max_damages = array(
    'wooden_tools': 59,
    'stone_tools': 131,
    'golden_tools': 32,
    'iron_tools': 250,
    'diamond_tools': 1601,
    'netherite_tools': 2031,
    'trident': 250,
    'bow': 384,
    'cross_bow': 326,
    'shield': 336
  )
  #broadcast(@event)
}

## Gui Management
bind('player_interact', null, array('hand': 'main_hand', 'button': 'right'), @event, @essences, @text) {
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
                  if(!is_null(@enchanting_item) && array_contains(array('IRON_SWORD'), @enchanting_item['name'])) {
                    @essence_name = strip_colors(@cursor_item['meta']['display'])
                    if(array_index_exists(@essences, @essence_name)) {
                      @entries = @essences[@essence_name]['entries']
                      @enchanted_item = _get_enchanted_item(@enchanting_item, @entries, 0)
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
    #broadcast(@players_item[@puuid])
  } else { //엔티티가 타격시

  }
}