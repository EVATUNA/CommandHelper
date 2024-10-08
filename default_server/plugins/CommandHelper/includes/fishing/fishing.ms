@fishing_table = json_decode(comp_read("fishing.json"))
export('fishing_table', @fishing_table)

@fishing_tasks = array()
export('fishing_tasks', @fishing_tasks)

@fishing_hooks = array()
export('fishing_hooks', @fishing_hooks)

proc _choose_fish(@player, @uuid, @hook) {
  // 물고기 선정 및 @fishing_data 세팅
  @lure_item = json_decode(get_inventory_item(puuid(@player), pheld_slot(@player))['meta']['modifiers'][0]['name'])
  if(@lure_item['name'] == 'STRUCTURE_VOID') { @lure_item = null }
  // 파일 읽은거 불러오기
  @fishing_table = array_deep_clone(import('fishing_table'))
  // 스킬, 기타 버프 읽기
  @fish_quality_multiply = 0 // 희귀 물고기 낚을 확률 보너스
  @rank_quality_multiply = 0 // 물고기 등급 확률 보너스
  // 물고기 선택
  @fish_entries = @fishing_table['fishs']
  @fish_total_weight = 0
  foreach(@key: @fish_entry in @fish_entries) {
    @fish_entries[@key]['weight'] += @fish_entry['quality'] * @fish_quality_multiply
    @fish_total_weight += @fish_entry['weight']
  }
  @fish_result_weight = @fish_total_weight * round(rand(), 5)
  @fish_min_weight = 0
  @fish_entry = null
  foreach(@fish_entry in @fish_entries) {
    @fish_max_weight = @fish_min_weight + @fish_entry['weight']
    if(@fish_max_weight > @fish_result_weight) {
      break()
    } else {
      @fish_min_weight = @fish_max_weight
    }
  }
  if(is_array(@fish_entry)) {
    // 미끼 사이즈
    @lure_size = 1
    if(is_array(@lure_item) && is_array(@lure_item['meta']) && is_array(@lure_item['meta']['modifiers']) && array_size(@lure_item['meta']['modifiers']) > 0 && @lure_item['meta']['modifiers'][0]['name'] == 'size') {
      @lure_size = @lure_item['meta']['modifiers'][0]['amount'] // 포리치문 사용해서 검색하는 방식으로 바꿔야 할 수도 있음 중요
    }
    // 물고기 사이즈
    @fish_size = @fish_entry['size']["min"] + (@fish_entry['size']["max"] - @fish_entry['size']["min"]) * round(rand(), 5)
    if(@lure_size ** 0.5 < @fish_size && @fish_size < @lure_size ** 1.5 + 5 + @lure_size * 1.25) { //크기 허용 범위 일시 // 수정 필요
      // 물고기 아이템 이름, 로어 등 설정 및 사이즈까지 반영
      @fish_item = array(
        'name': @fish_entry['item_name'],
        'meta': @fish_entry['item_meta']
      )
      @fish_item['meta']['flags'] = array(
        'HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE'
      )
      @fish_item['meta']['modifiers'] = array(
        array(
          'attribute': 'HORSE_JUMP_STRENGTH',
          'operation': 'ADD_NUMBER',
          'amount': @fish_size,
          'name': 'size'
        )
      )
      
      // 등급 선택
      @rank_entries = @fishing_table['rank_table']
      @rank_total_weight = 0
      foreach(@key: @rank_entry in @rank_entries) {
        // condition에 따라 조건 맞으면 토탈에 계산
        // 조건에 안맞으면 배열에서 아예 제거 시켜서 이후 랜덤 돌렸을떄 안뽑히게 해야함
        @rank_entries[@key]['weight'] += @rank_entry['quality'] * @rank_quality_multiply
        @rank_total_weight += @rank_entry['weight']
      }
      @rank_result_weight = @rank_total_weight * round(rand(), 5)
      @rank_min_weight = 0
      @rank_entry = null
      foreach(@rank_entry in @rank_entries) {
        @rank_max_weight = @rank_min_weight + @rank_entry['weight']
        if(@rank_max_weight > @rank_result_weight) {
          break()
        } else {
          @rank_min_weight = @rank_max_weight
        }
      }
      if(is_array(@rank_entry)) {
        if(!is_null(@fish_item['meta']['display'])) {
          @fish_item['meta']['display'] = @rank_entry['rank']['display'].' '.@fish_item['meta']['display']
        }
        if(!is_null(@fish_item['meta']['model'])) {
          @fish_item['meta']['model'] += @rank_entry['rank']['adding_model']
        }
      }
      @fish_item['meta']['lore'][] = '§7'.round(@fish_size, 2).'cm'

      // 미끼에 따른 진행도 수정
      if(!is_array(@lure_item)) {
        @progress = 20.0
        @location = 0.0
      } else {
        if(is_array(@lure_item['meta']) && !is_null(@lure_item['meta']['model'])) {
          @model = @lure_item['meta']['model'] % 3
        } else {
          @model = 0
        }
        switch(@model) {
        case 0:
          @progress = 25.0
          @location = 15.0
          break()
        case 1:
          @progress = 30.0
          @location = 30.0
          break()
        case 2:
          @progress = 35.0
          @location = 45.0
          break()
        }
      }

      // 물고기 스펙
      @fishing_data = array(
        'hook': @hook,
        'fish': @fish_item,
        'progress': @progress,
        'location': @location,
        'moving_speed': @fish_entry['spec']['moving_speed'], // 움직임에 영향 (초록색에 있을수록 강하게 움직이거나 진행도가 높을수록 많이 움직인다거나)
        'power': @fish_entry['spec']['power'] // 진행도에 영향 (빨강에 있을수록 진행도가 빨리 닳음)
      )
      _update_tag(@hook, @fishing_data)
      return(@fishing_data)

    } else {
      return(null)
    }
  } else {
    return(null)
  }
}

proc _fishing_start(@player, @uuid, @hook, @fishing_hooks, @fishing_tasks, @text, @server) {
  // 물고기 선정
  @fishing_data = _choose_fish(@player, @uuid, @hook)
  if(@fishing_data) { // 물고기 선정이 올바르게 되었을 시
    // 낚시 시작 사운드, 파티클
    @hloc = entity_loc(@hook)
    play_named_sound(@hloc, array('sound': 'minecraft:entity.generic.splash', 'category': 'AMBIENT', 'volume': 0.2, 'pitch': 0.9 + rand() * 0.6))
    play_named_sound(@hloc, array('sound': 'minecraft:entity.fishing_bobber.splash', 'category': 'AMBIENT', 'volume': 0.2, 'pitch': 0.9 + rand() * 0.6))
    @pos = array(
      'x': @hloc['x'],
      'y': @hloc['y'],
      'z': @hloc['z'],
    )
    mom_playerparticle(@uuid, 'WATER_BUBBLE', @pos['x'], @pos['y'], @pos['z'], rand(1,3), 0.2, 0.0, 0.2, 0.0)
    @pos['y'] += 0.2
    mom_playerparticle(@uuid, 'WATER_SPLASH', @pos['x'], @pos['y'], @pos['z'], rand(1,3), 0.2, 0.0, 0.2, 0.0)
    // interval 동작
    @progress_bars = array('\ueb20', '\ueb21', '\ueb22', '\ueb23', '\ueb24', '\ueb25', '\ueb26', '\ueb27', '\ueb28', '\ueb29', '\ueb2a', '\ueb2b', '\ueb2c', '\ueb2d', '\ueb2e', '\ueb2f', '\ueb30', '\ueb31', '\ueb32', '\ueb33', '\ueb34')
    @task_id = set_interval(100, closure() {
      if(entity_exists(@hook)) {
        @fishing_data = _get_tag(@hook)
        
        if(@fishing_data['location'] < 60) {
          @fishing_data['progress'] += @fishing_data['power']['less']
          @deviation_multiply_by_location = @fishing_data['moving_speed']['deviation']['multiply_by_location']['less']
        } else if(@fishing_data['location'] < 90) {
          @fishing_data['progress'] += @fishing_data['power']['match']
          @deviation_multiply_by_location = @fishing_data['moving_speed']['deviation']['multiply_by_location']['match']
        } else {
          @fishing_data['progress'] += @fishing_data['power']['over']
          @deviation_multiply_by_location = @fishing_data['moving_speed']['deviation']['multiply_by_location']['over']
        }
        
        if(@fishing_data['progress'] > 100) {
          @size = 0
          if(array_index_exists(@fishing_data['fish'], 'meta', 'modifiers', 0) && @fishing_data['fish']['meta']['modifiers'][0]['name'] == 'size') {
            @size = round(@fishing_data['fish']['meta']['modifiers'][0]['amount'], 2)
          }
          tmsg(@player, '잡음')
          pgive_item(@player, @fishing_data['fish'])
          _fishing_end(@player, @uuid, @fishing_data, @fishing_hooks, @fishing_tasks, @text)
          _logging('fish', time(), @server, ploc(@player), @player, @uuid, @fishing_data['fish'], @size)
        } else if(@fishing_data['progress'] < 0) {
          tmsg(@player, '놓침')
          _fishing_end(@player, @uuid, @fishing_data, @fishing_hooks, @fishing_tasks, @text)
        } else {
          @location_index = integer(@fishing_data['location'] * 0.5)
          @progress_index = integer(@fishing_data['progress'] * 0.2)
          @location_space = -62 + @location_index
          @progress_bar = @progress_bars[@progress_index]
          _set_sidebar(@uuid, 4, color('#fc8080').@text['space_fonts']['space.-32'].'\ue3f9'.@text['space_fonts']['space.'.@location_space].'\ue3fa'.@text['space_fonts']['space.-19'].@progress_bar, @text)
          
          @deviation = @fishing_data['moving_speed']['deviation']['default'] + @fishing_data['moving_speed']['deviation']['multiply_by_progress'] * @fishing_data['progress'] * 0.01 + @deviation_multiply_by_location
          if(@deviation < 0) { @deviation = 0}

          @moving_speed = @fishing_data['moving_speed']['default'] + @deviation * (1 - 2 * rand())
          //@moving_speed = @fishing_data['moving_speed']['min'] + (@fishing_data['moving_speed']['max'] - @fishing_data['moving_speed']['min']) * rand()
          if(@moving_speed < 0) {@moving_speed = 0}

          @fishing_data['location'] -= @moving_speed
          if(@fishing_data['location'] < 0) {@fishing_data['location'] = 0}

          _update_tag(@hook, @fishing_data)
        }
      } else {
        _fishing_end(@player, @uuid, @fishing_data, @fishing_hooks, @fishing_tasks, @text)
      }
    })
    @fishing_data['task_id'] = @task_id
    _update_tag(@hook, @fishing_data)

    @fishing_tasks[@uuid] = @task_id
  } else {
    cancel()
  }
}

proc _fishing_end(@player, @uuid, @fishing_data, @fishing_hooks, @fishing_tasks, @text) {
  // 낚싯찌 처리
  @hook = @fishing_data['hook']
  if(entity_exists(@hook)) { entity_remove(@hook) }
  if(array_index_exists(@fishing_hooks, @uuid)) { array_remove(@fishing_hooks, @uuid) }
  // task 처리
  @task_id = @fishing_data['task_id']
  clear_task() //clear_task(@task_id)
  array_remove_values(@fishing_tasks, @task_id)
  // 플레이어 UI 처리, 아이템 처리
  _set_sidebar(@uuid, 4, '', @text)
  set_pcooldown(@player, 'FISHING_ROD', 20)
}

proc _reel_in(@player, @uuid, @hook, @fishing_data, @fishing_hooks, @fishing_tasks, @text) {
  @fishing_data['location'] += 10
  if(@fishing_data['location'] > 100) {@fishing_data['location'] = 100}
  _update_tag(@hook, @fishing_data)
  set_entity_velocity(@hook, array(0, 0.01, 0))
  // 위치 선언
  @hloc = entity_loc(@hook)
  @ploc = ploc(@player)
  // 사운드
  if(rand() < 0.25) {
    play_named_sound(@hloc, array('sound': 'minecraft:entity.generic.splash', 'category': 'AMBIENT', 'volume': 0.2, 'pitch': 0.9 + rand() * 0.6))
  }
  if(rand() < 0.125) {  
    play_named_sound(@hloc, array('sound': 'minecraft:entity.fishing_bobber.splash', 'category': 'AMBIENT', 'volume': 0.2, 'pitch': 0.9 + rand() * 0.6))
  }
  play_named_sound(@ploc, array('sound': 'minecraft:item.crossbow.loading_start', 'category': 'PLAYERS', 'volume': 1, 'pitch': 1.15 + rand() * 0.1))
  play_named_sound(@ploc, array('sound': 'minecraft:item.crossbow.loading_middle', 'category': 'PLAYERS', 'volume': 0.5, 'pitch': 1.15 + rand() * 0.1))
  // 파티클
  @pos = array(
    'x': @hloc['x'],
    'y': @hloc['y'],
    'z': @hloc['z'],
  )
  mom_playerparticle(@uuid, 'WATER_BUBBLE', @pos['x'], @pos['y'], @pos['z'], rand(1,3), 0.2, 0.0, 0.2, 0.0)
  @pos['y'] += 0.2
  mom_playerparticle(@uuid, 'WATER_SPLASH', @pos['x'], @pos['y'], @pos['z'], rand(1,3), 0.2, 0.0, 0.2, 0.0)
}

bind('player_fish', null, null, @event, @players_data, @fishing_hooks, @fishing_tasks, @text, @server) {
  @player = @event['player']
  @uuid = puuid(@player)
  @hook = @event['hook']
  if(entity_exists(@hook)) {
    @is_fishing = false
    @fishing_data = _get_tag(@hook)
    if(!is_null(@fishing_data)) {
      @task_id = @fishing_data['task_id']
      if(array_contains(@fishing_tasks, @task_id)) {
        @is_fishing = true
      }
    }
    if(@event['state'] == 'FISHING') {
      @fishing_hooks[@uuid] = @hook
    } else if(!@is_fishing && @event['state'] == 'BITE') {
      //cancel()
      //broadcast(@event['caught'])
      _fishing_start(@player, @uuid, @hook, @fishing_hooks, @fishing_tasks, @text, @server)
    } else if(@is_fishing && (@event['state'] == 'REEL_IN' || @event['state'] == 'CAUGHT_FISH')) {
      cancel()
      //broadcast(entity_spec(@event['caught']))
      _reel_in(@player, @uuid, @hook, @fishing_data, @fishing_hooks, @fishing_tasks, @text)
    } else if(!@is_fishing && @event['state'] == 'REEL_IN') {
      if(array_index_exists(@fishing_hooks, @uuid)) { array_remove(@fishing_hooks, @uuid) }
    }
  }
  
  //broadcast(@event)
  //if(@event['state'] == 'CAUGHT_FISH') {
  //  @player = @event['player']
  //  @uuid = puuid(@player)
  //  if(array_index_exists(@players_data, @uuid)) {
  //    @player_data = @players_data[@uuid]
  //    @xp = integer(@event['xp'] / 2)
  //    modify_event('xp', @xp)
  //    _give_tunalevel_random_experience(@uuid, @player_data, 0, @event['xp'] / 3, @text)
  //  }
  //}
}

proc _open_fishing_rod(@player, @uuid, @bag_item, @bag_slot, @text) {
  if(is_array(@bag_item['meta']) && array_index_exists(@bag_item['meta'], 'modifiers') && array_size(@bag_item['meta']['modifiers']) == 1) {
    @lure_slot_item = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': '§7미끼를 넣어주세요',
        'model': 15
      )
    )
    # GUI 내용물
    @inventory = array()
    for(@index = 0, @index < 9, @index++) {
      @inventory[@index] = array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': ' ',
          'model': 1
        )
      )
    }
    @inventory[4] = json_decode(@bag_item['meta']['modifiers'][0]['name'])
    # GUI 백그라운드 세팅
    @texture_layer = @text['space_fonts']['space.-8'].'\ue3fb'.@text['space_fonts']['space.-169']
    # GUI 이름 세팅
    @message = '낚싯대'
    if(array_index_exists(@bag_item['meta'], 'display') && !is_null(@bag_item['meta']['display'])) {
      @message = strip_colors(@bag_item['meta']['display'])
    }
    # 열고 있는 가방 뷰어
    @bag_item['meta']['model'] = integer(@bag_item['meta']['model'] / 2) * 2 + 1
    set_inventory_item(@uuid, @bag_slot, @bag_item)
    # 가방 화리/블리 불러오기
    @allowed_items = array('SALMON', 'TROPICAL_FISH', 'PUFFERFISH') // 미끼템
    @unallowed_items = array('TRAPPED_CHEST', 'SHULKER_BOX', 'WHITE_SHULKER_BOX', 'ORANGE_SHULKER_BOX', 'MAGENTA_SHULKER_BOX', 'LIGHT_BLUE_SHULKER_BOX', 'YELLOW_SHULKER_BOX', 'LIME_SHULKER_BOX', 'PINK_SHULKER_BOX', 'GRAY_SHULKER_BOX', 'LIGHT_GRAY_SHULKER_BOX', 'CYAN_SHULKER_BOX', 'PURPLE_SHULKER_BOX', 'BLUE_SHULKER_BOX', 'BROWN_SHULKER_BOX', 'GREEN_SHULKER_BOX', 'RED_SHULKER_BOX', 'BLACK_SHULKER_BOX')
    # GUI 시스템
    @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @uuid, @bag_item, @bag_slot, @allowed_items, @lure_slot_item, @text) {
      bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @id, @bag_item, @bag_slot, @allowed_items, @unallowed_items, @lure_slot_item, @text) {
        // 가방용 함수 (넣을수 있는 템인지)
        proc _is_allowed_item(@item, @allowed_items, @unallowed_items) {
          if((array_size(@allowed_items) != 0 && is_array(@item) && !array_contains(@allowed_items, @item['name'])) || (array_size(@allowed_items) == 0 && is_array(@item) && array_contains(@unallowed_items, @item['name']))) {
            return(false)
          } else {
            return(true)
          }
        }
        //
        @rawslot = @event['rawslot']
        @slot_item = @event['slotitem']
        @cursor_item = @event['cursoritem']
        //
        @is_bag_click = false
        //
        if((is_array(@slot_item) && @slot_item['name'] == 'STRUCTURE_VOID' && is_array(@slot_item['meta']) && @slot_item['meta']['model'] == 1) || @event['slot'] == @bag_slot && @event['slot'] != @rawslot) {
          cancel()
        } else {
          if(0 <= @rawslot && @rawslot < 9) {
            switch(@event['action']) {
            case 'SWAP_WITH_CURSOR':
              @cursor_item_copy = array_deep_clone(@cursor_item)
              if(_is_allowed_item(@cursor_item, @allowed_items, @unallowed_items)) {
                if(@slot_item['name'] == 'STRUCTURE_VOID') {
                  if(!is_cancelled()) {
                    @is_bag_click = true
                    @cursor_item['qty'] = 1
                    @cursor_item_copy['qty'] = 63
                    modify_event('slotitem', @cursor_item_copy)
                    set_timeout(1, closure() {
                      set_inventory_item(@id, @rawslot, @cursor_item)
                    })
                  }
                } else {
                  if(@cursor_item['qty'] == 1) {
                    @is_bag_click = true
                  } else {
                    cancel()
                  }
                }
              } else {
                cancel()
              }
              break()
            case 'PLACE_ALL':
            case 'PLACE_ONE':
              @cursor_item_copy = array_deep_clone(@cursor_item)
              if(@slot_item['name'] == @cursor_item['name'] && @slot_item['meta'] == @cursor_item['meta']) {
                if(@cursor_item['qty'] < 64) {
                  @is_bag_click = true
                  @cursor_item_copy['qty'] += 1
                  modify_event('cursoritem', null)
                  modify_event('slotitem', @cursor_item_copy)
                  set_timeout(1, closure() {
                    set_inventory_item(@id, @rawslot, @lure_slot_item)
                  })
                } else {
                  cancel()
                }
              } else {
                cancel()
              }
              break()
            case 'PICKUP_ALL':
            case 'PICKUP_HALF':
              if(_is_allowed_item(@slot_item, @allowed_items, @unallowed_items)) {
                @is_bag_click = true
                set_timeout(1, closure() {
                  set_inventory_item(@id, @rawslot, @lure_slot_item)
                })
              } else {
                cancel()
              }
              break()
            case 'DROP_ONE_SLOT':
            case 'DROP_ALL_SLOT':
              if(is_null(@cursor_item)) {
                if(_is_allowed_item(@slot_item, @allowed_items, @unallowed_items)) {
                  @is_bag_click = true
                  set_timeout(1, closure() {
                    set_inventory_item(@id, @rawslot, @lure_slot_item)
                  })
                } else {
                  cancel()
                }
              } else {
                cancel()
              }
              break()
            case 'HOTBAR_SWAP':
            case 'HOTBAR_MOVE_AND_READD':
              if(is_null(@cursor_item)) {
                @swapslot = @event['hotbarbutton']
                if(@event['hotbarbutton'] == -1 ) { @swapslot = 40 }
                @swap_item = get_inventory_item(@uuid, @swapslot)
                if(_is_allowed_item(@slot_item, @allowed_items, @unallowed_items)) {
                  if(is_array(@swap_item)) {
                    if(_is_allowed_item(@swap_item, @allowed_items, @unallowed_items)) {
                      if(@swap_item['qty'] == 1) {
                        if(@slot_item['name'] == @swap_item['name'] && @slot_item['meta'] == @swap_item['meta']) {
                          @is_bag_click = true
                          cancel()
                          @swap_item_copy = array_deep_clone(@swap_item)
                          @swap_item_copy['qty'] += 1
                          set_inventory_item(@id, @rawslot, @lure_slot_item)
                          set_inventory_item(@uuid, @swapslot, @swap_item_copy)
                        } else {
                          @is_bag_click = true
                        }
                      } else if(@swap_item['qty'] < 64) {
                        if(@slot_item['name'] == @swap_item['name'] && @slot_item['meta'] == @swap_item['meta']) {
                          @is_bag_click = true
                          cancel()
                          @swap_item_copy = array_deep_clone(@swap_item)
                          @swap_item_copy['qty'] += 1
                          set_inventory_item(@id, @rawslot, @lure_slot_item)
                          set_inventory_item(@uuid, @swapslot, @swap_item_copy)
                        } else {
                          cancel()
                        }
                      } else {
                        cancel()
                      }
                    } else {
                      cancel()
                    }
                  } else {
                    @is_bag_click = true
                    cancel()
                    set_inventory_item(@id, @rawslot, @lure_slot_item)
                    set_inventory_item(@uuid, @swapslot, @slot_item)
                  }
                } else {
                  if(is_array(@swap_item)) {
                    if(_is_allowed_item(@swap_item, @allowed_items, @unallowed_items)) {
                      if(@swap_item['qty'] == 1) {
                        @is_bag_click = true
                        cancel()
                        set_inventory_item(@id, @rawslot, @swap_item)
                        set_inventory_item(@uuid, @swapslot, null)
                      } else {
                        @is_bag_click = true
                        cancel()
                        @swap_item['qty'] -= 1
                        @swap_item_copy = array_deep_clone(@swap_item)
                        @swap_item_copy['qty'] = 1
                        set_inventory_item(@id, @rawslot, @swap_item_copy)
                        set_inventory_item(@uuid, @swapslot, @swap_item)
                      }
                    } else {
                      cancel()
                    }
                  } else {
                    cancel()
                  }
                }
              }
              break()
            case 'MOVE_TO_OTHER_INVENTORY':
              if(_is_allowed_item(@slot_item, @allowed_items, @unallowed_items)) {
                @is_bag_click = true
                set_timeout(1, closure() {
                  set_inventory_item(@id, @rawslot, @lure_slot_item)
                })
              } else {
                cancel()
              }
              break()
            default:
              cancel()
              break()
            }
          } else {
            if(_is_allowed_item(@slot_item, @allowed_items, @unallowed_items)) {
              if(@event['action'] == 'MOVE_TO_OTHER_INVENTORY') {
                if(is_array(@event['inventory'][4]) && @event['inventory'][4]['name'] == 'STRUCTURE_VOID') {
                  @is_bag_click = true
                  cancel()
                  @slot_item_copy = array_deep_clone(@slot_item)
                  @slot_item['qty'] -= 1
                  @slot_item_copy['qty'] = 1
                  set_inventory_item(@id, 4, @slot_item_copy)
                  set_inventory_item(@uuid, @event['slot'], @slot_item)
                } else {
                  cancel()
                }
              } else if(@event['action'] == 'COLLECT_TO_CURSOR') {
                if(_is_allowed_item(@cursor_item, @allowed_items, @unallowed_items)) {
                  if(@event['inventory'][4]['name'] == @cursor_item['name'] && @event['inventory'][4]['meta'] == @cursor_item['meta']) {
                    @is_bag_click = true
                    set_timeout(1, closure() {
                      set_inventory_item(@id, 4, @lure_slot_item)
                    })
                  }
                }
              }
            }
          }
        }
        if(@is_bag_click) {
          set_timeout(0, closure() {
            @bag_item['meta']['modifiers'][0]['name'] = json_encode(get_inventory(@id)[4])
            set_inventory_item(@uuid, @bag_slot, @bag_item)
          })
        }
      }
      bind('inventory_drag', array('id': "drag.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @bag_item, @bag_slot, @allowed_items, @unallowed_items, @text) {
        if(@event['player'] == @player) {
          @indexs = array_keys(@event['newitems'])
          foreach(@index in @indexs) {
            if(@index < 9) {
              cancel()
            }
          }
        }
      }
      bind('inventory_close', array('id': "close.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @bag_item, @bag_slot, @allowed_items, @text) {
        if(@event['player'] == @player) {
          if(is_array(@event['inventory'][4])) {
            @bag_item['meta']['modifiers'][0]['name'] = json_encode(@event['inventory'][4])
          } else {
            @bag_item['meta']['modifiers'][0]['name'] = json_encode(array('name': 'AIR'))
          }
          @bag_item['meta']['model'] = integer(@bag_item['meta']['model'] / 2) * 2
          set_inventory_item(@uuid, @bag_slot, @bag_item)
        }
      }
    }
    # GUI 보여주기
    close_pinv(@player)
    _show_gui(@player, 'fishing_rod', 9, @texture_layer, @message, @inventory, @closure, @uuid, @bag_item, @bag_slot, @allowed_items, @lure_slot_item, @text)
  }
}


bind('inventory_click', null, array('slotitem': 'FISHING_ROD', 'clicktype': 'SHIFT_RIGHT'), @event, @players_data, @fishing_hooks, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!is_cancelled() && array_index_exists(@players_data, @uuid)) {
    @container_slot = @event['rawslot'] - @event['inventorysize']
    if(@event['inventorytype'] == 'CRAFTING') {@container_slot -= 4}
    if(@container_slot >= 0 && @container_slot < 36) {
      @bag_item = @event['slotitem']
      @bag_slot = @event['slot']
      if(is_array(@bag_item['meta']) && !is_null(@bag_item['meta']['model'])) {
        cancel()
        _open_fishing_rod(@player, @uuid, @bag_item, @bag_slot, @text)
      }
    } else {
      // 해당 칸에서는 가방 열수 없다는 메시지
    }
  }
}