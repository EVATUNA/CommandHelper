@smoker_interact_items = array(
  'default': array(
    'empty_slot': array(
      'recipe_unchosen': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f선택된 레시피 없음',
          'lore': array(
            '§7클릭시, 레시피 북을 펼쳐',
            '§7요리하려는 음식을 선택할 수 있습니다.',
            '§7(선택된 레시피가 없을 땐 요리가 진행되지 않습니다.)',
            '',
            '§f \ue002 레시피 선택 '
          ),
          'model': 112
        )
      ),
      'recipe_choosing': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f선택된 레시피 없음',
          'lore': array(
            '§7우측의 레시피 목록에서',
            '§7요리하려는 음식을 선택하세요.',
            '§7(선택된 레시피가 없을 땐 요리가 진행되지 않습니다.)',
            '',
            '§f \ue002 레시피 선택 취소'
          ),
          'model': 112
        )
      ),
      'ingredient': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§7요리 재료',
          'model': 1
        )
      ),
      'result': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§7요리 결과',
          'model': 1
        )
      ),
      'fuel': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§7연료',
          'lore': array(
            '§7불이 필요한 요리의 경우,',
            '§7연료가 필요합니다.'
          ),
          'model': 113
        )
      )
    )
  ),
  'recipe': array(
    'category': array(
      'everything': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f모든 요리 레시피',
          'model': 1
        )
      ),
      'simple_cooking': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f단순 조리 및 손질 레시피',
          'model': 1
        )
      ),
      'need_fire': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f불이 필요한 요리 레시피',
          'model': 1
        )
      )
    ),
    'button': array(
      'show_all': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f재료 준비 여부와 상관 없이 모든 레시피 표시 중',
          'model': 107
        )
      ),
      'show_ready': array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f재료가 준비된 레시피만 표시 중',
          'model': 108
        )
      )
    )
  )
)
export('smoker_interact_items', @smoker_interact_items)

@cooking_recipes = array()
@files = list_files('recipe_tables')
foreach(@file in @files) {
  @file_path = "recipe_tables/@file"
  @file_name_and_extension = _get_file_name_and_extension(@file)
  @file_name = @file_name_and_extension[0]
  @file_extension = @file_name_and_extension[1]
  if(@file_extension == 'json') {
    async_read_file(@file_path, closure(@content) {
      foreach(@food_name: @cooking_recipe in json_decode(@content)) {
        //@namespace = "@file_name:@food_name"
        @cooking_recipes[@food_name] = @cooking_recipe
      }
    })
  }
}
export('cooking_recipes', @cooking_recipes)

@cooking_tasks = array()
export('cooking_tasks', @cooking_tasks)

# 훈연기 블럭 nbt getter/setter
proc _get_smoker_data(@smoker_location) {
  if(get_block(@smoker_location) == 'SMOKER') {
    @smoker_data_string = get_block_lock(@smoker_location)
    if(@smoker_data_string == '') {
      @smoker_data = array(
        'viewer': null,
        'gui_id': null,
        'selected_recipe': null,
        'recipe_book': array(
          'enable': false,
          'category': 'everything',
          'show_ready': false,
          'page': 0,
          'shown_recipes': array()
        ),
        'ingredients': array(0: null, 1: null, 2: null, 3: null, 4: null, 5: null, 6: null, 7: null, 8: null, 9: null),
        'results': array(0: null, 1: null, 2: null, 3: null, 4: null, 5: null, 6: null, 7: null, 8: null, 9: null)
      )
      _set_smoker_data(@smoker_location, @smoker_data)
    } else {
      @smoker_data = json_decode(@smoker_data_string)
    }
    return(@smoker_data)
  } else {
    return(null)
  }
}
proc _set_smoker_data(@smoker_location, @smoker_data) {
  if(get_block(@smoker_location) == 'SMOKER') {
    set_block_lock(@smoker_location, json_encode(@smoker_data))
    return(true)
  } else {
    return(false)
  }
}

# gui 이름 뽑기
proc _get_cooking_table_gui_id(@smoker_location) {
  @gui_id = 'cooking_table_'.@smoker_location['x'].'_'.@smoker_location['y'].'_'.@smoker_location['z'].'_'.@smoker_location['world']
  return(@gui_id)
}
# gui 결과 아이템 추가
proc _add_to_result_inventory(@smoker_location, @smoker_data, @item) {
  @results = @smoker_data['results']
  @empty_slot = -1
  @item_need_to_add = true
  @item_copy = @item[]
  array_remove(@item_copy, 'qty')
  foreach(@result_key: @result_item in @smoker_data['results']) {
    if(is_null(@result_item)) { // 빈칸 일 경우
      if(@empty_slot == -1) { @empty_slot = @result_key }
    } else { // 아이템 있을 경우
      if(!array_index_exists(@result_item, 'qty')) { @result_item['qty'] = 1 }
      if(@result_item['qty'] < max_stack_size(@result_item)) {
        @result_item_copy = @result_item[]
        array_remove(@result_item_copy, 'qty')
        if(@item_copy == @result_item_copy) {
          @result_item['qty']++
          @item_need_to_add = false
          break()
        }
      }
    }
  }
  if(@item_need_to_add) {
    if(@empty_slot > -1) { // 빈 공간 있음 (결과칸 업뎃)
      @smoker_data['results'][@empty_slot] = @item
    } else { // 꽉참 (아이템 드랍)
      @item_drop_location = @smoker_location[]
      @item_drop_location['x'] += 0.5
      @item_drop_location['z'] += 0.5
      @item_drop_location['y'] += 1
      drop_item(@item_drop_location, @item, false)
    }
  }
}

# 요리 처리
proc _check_ingredient(@require_item, @checking_item) {
  if(
    @require_item['name'] == @checking_item['name'] &&
    (
      (!array_index_exists(@require_item, 'rank_contribution') && @require_item['meta']['model'] == @checking_item['meta']['model']) || //랭크 반영 x
      ( array_index_exists(@require_item, 'rank_contribution') && @require_item['meta']['model'] == integer(@checking_item['meta']['model'] / 5) * 5) //랭크 반영 o
    )
  ) {
    return(true)
  } else {
    return(false)
  }
}
proc _set_item_model(@item) {
  if(!array_index_exists(@item, 'meta') || !is_array(@item['meta'])) { // 메타가 없거나 null인 경우
    @item['meta'] = array('model': 0)
  } else if(!array_index_exists(@item['meta'], 'model') || is_null(@item['meta']['model'])) { // 모델이 없거나 null인 경우
    @item['meta']['model'] = 0
  }
}
proc _get_cookable(@search_items, @cooking_recipe, @get_result) {
  @return_array = array(
    'cookable': false,
    'new_ingredient_items': null,
    'max_quality': 0,
    'accumulated_quality': 0
  )
  // 요리 후 재료템 변화
  @new_ingredient_items = @search_items[]
  // 요구 아이템
  @require_items = @cooking_recipe['ingredients'][]
  foreach(@require_item in @require_items) { _set_item_model(@require_item) }
  // 재료 아이템
  @search_items = @search_items[]
  foreach(@search_item in @search_items) { if(is_array(@search_item)) { _set_item_model(@search_item) } }
  // 요리 재료별 포리치
  foreach(@require_item_slot: @require_item in @require_items) {
    @matched_items_slot_and_qty = array()
    // 아이템 비교 후 매치된 아이템 저장
    @active_while = false
    foreach(@search_item_slot: @search_item in @search_items) {
      if(is_array(@search_item) && _check_ingredient(@require_item, @search_item)) {
        @matched_items_slot_and_qty[] = array('slot': @search_item_slot, 'qty': @search_item['qty'])
        if(!@active_while) {@active_while = true}
      }
    }
    while(@active_while) {
      @min_qty = 0
      @matched_items_size = array_size(@matched_items_slot_and_qty)
      if(@matched_items_size > 0) {
        // 해당 반복에서의 최소 일괄 처리 횟수 구하기 
        foreach(@matched_item_index: @matched_item_slot_and_qty in @matched_items_slot_and_qty) {
          @matched_item_qty = @matched_item_slot_and_qty['qty']
          if(@min_qty == 0 || @matched_item_qty < @min_qty) { @min_qty = @matched_item_qty }
        }
        @batch_processing_times = integer(@require_item['qty'] / @matched_items_size) // 최대 일괄 처리 횟수
        if(@batch_processing_times > @min_qty) { @batch_processing_times = @min_qty } // 실제 일괄 처리 횟수 설정
        if(@batch_processing_times > 0) { // 일괄 처리 횟수 만큼 매치된 아이템 제거
          foreach(@matched_item_index: @matched_item_slot_and_qty in @matched_items_slot_and_qty) {
            @matched_item_slot_and_qty['qty'] -= @batch_processing_times
            if(@get_result) {
              if(array_index_exists(@require_item, 'rank_contribution')) {
                @new_ingredient_item = @new_ingredient_items[@matched_item_slot_and_qty['slot']]
                @rank = 0.5
                if(array_index_exists(@new_ingredient_item, 'meta', 'model') && !is_null(@new_ingredient_item['meta']['model'])) {
                  @rank = @new_ingredient_item['meta']['model'] % 5 + 0.5
                }
                @return_array['accumulated_quality'] += @rank * @require_item['rank_contribution'] * @batch_processing_times
                @return_array['max_quality'] += 3 * @require_item['rank_contribution'] * @batch_processing_times
              }
              @new_ingredient_items[@matched_item_slot_and_qty['slot']]['qty'] -= @batch_processing_times
              if(@new_ingredient_items[@matched_item_slot_and_qty['slot']]['qty'] <= 0) { @new_ingredient_items[@matched_item_slot_and_qty['slot']] = null }
            }
            if(@matched_item_slot_and_qty['qty'] <= 0) { array_remove(@matched_items_slot_and_qty, @matched_item_index) }
          }
          // 일괄 처리 횟수 x 검색된 같은템 갯수 만큼 재료 아이템에서 제거
          @require_item['qty'] -= @batch_processing_times * @matched_items_size
          // 요구아이템 모두 만족시 배열에서 제거
          if(@require_item['qty'] <= 0) {
            array_remove(@require_items, @require_item_slot)
            break()
          }
        } else { // 남은 갯수 만큼 제거
          @i = 0
          foreach(@matched_item_index: @matched_item_slot_and_qty in @matched_items_slot_and_qty) {
            if(@i++ < @require_item['qty'] % @matched_items_size) {
              @matched_item_slot_and_qty['qty'] -= 1
              if(@get_result) {
                if(array_index_exists(@require_item, 'rank_contribution')) {
                  @new_ingredient_item = @new_ingredient_items[@matched_item_slot_and_qty['slot']]
                  @rank = 0.5
                  if(array_index_exists(@new_ingredient_item, 'meta', 'model') && !is_null(@new_ingredient_item['meta']['model'])) {
                    @rank = @new_ingredient_item['meta']['model'] % 5 + 0.5
                  }
                  @return_array['accumulated_quality'] += @rank * @require_item['rank_contribution']
                  @return_array['max_quality'] += 3 * @require_item['rank_contribution']
                }
                @new_ingredient_items[@matched_item_slot_and_qty['slot']]['qty'] -= 1
                if(@new_ingredient_items[@matched_item_slot_and_qty['slot']]['qty'] <= 0) { @new_ingredient_items[@matched_item_slot_and_qty['slot']] = null }
              }
              if(@matched_item_slot_and_qty['qty'] <= 0) { array_remove(@matched_items_slot_and_qty, @matched_item_index) }
            }
          }
          // 남은 갯수 만큼 요구 갯수 빼기
          @require_item['qty'] -= @i
          if(@require_item['qty'] <= 0) {
            array_remove(@require_items, @require_item_slot)
            break()
          }
          break()
        }
      } else {
        break()
      }
    }
  }
  if(array_size(@require_items) == 0) {
    @return_array['cookable'] = true
    if(@get_result) {
      @return_array['new_ingredient_items'] = @new_ingredient_items
    }
  }
  
  return(@return_array)
}

# 플레이어 인벤에서 재료 검색 
proc _update_paged_showen_recipes(@player_inventory, @smoker_data, @cooking_recipes) {
  # 검색용 인벤 세팅
  @search_inventory = array()
  foreach(@index: @item in @player_inventory) {
    if(@index < 36) { // 36~40: 갑옷, 왼손
      @search_inventory[@index] = @item
    }
  }
  # 검색 된 레시피 목록
  @shown_recipes = array()
  # 전체 레시피 포리치
  foreach(@food_name: @cooking_recipe in @cooking_recipes) {
    # 카테고리 구분
    if(@smoker_data['recipe_book']['category'] == 'need_fire' && @cooking_recipe['category'] != 'need_fire') {
      continue()
    } else if(@smoker_data['recipe_book']['category'] == 'simple_cooking' && @cooking_recipe['category'] != 'simple_cooking') {
      continue()
    }
    # 재료 준비 구분
    if(!@smoker_data['recipe_book']['show_ready'] || _get_cookable(@search_inventory, @cooking_recipe, false)['cookable']) {
      @shown_recipes[] = @food_name
    }
  }
  # 페이징
  @paged_shown_recipes = array()
  if(array_size(@shown_recipes) > 0) {
    @paged_shown_recipes = _paging(@shown_recipes, 20)
  }
  # 업데이트
  @smoker_data['recipe_book']['shown_recipes'] = @paged_shown_recipes
}

# 레시피북 GUI 아이템 세팅
proc _update_recipe_book_inventory(@inventory, @page, @smoker_data, @cooking_recipes) {
  @max_page = array_size(@smoker_data['recipe_book']['shown_recipes']) - 1
  // 레시피 인벤 빈칸 세팅
  for(@key = 0, @key < 20, @key++) {
    @line = floor(@key / 5)
    @slot = @line * 9 + 22 + @key % 5
    @inventory[@slot] = array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': ' ',
        'model': 1
      )
    )
  }
  if(@max_page >= 0) {
    // 페이지 예외 세팅
    if(@page < 0) {@page = 0}
    if(@page > @max_page) {@page = @max_page}
    @smoker_data['recipe_book']['page'] = @page
    // 레시피 인벤 해당 페이지 레시피들로 세팅
    foreach(@key: @paged_shown_recipe in @smoker_data['recipe_book']['shown_recipes'][@page]) {
      @line = floor(@key / 5)
      @slot = @line * 9 + 22 + @key % 5
      @item = @cooking_recipes[@paged_shown_recipe]['result']['item'][]
      @item['meta']['modifiers'] = array(
        array(
          'attribute': 'HORSE_JUMP_STRENGTH',
          'operation': 'ADD_NUMBER',
          'amount': @key,
          'name': @paged_shown_recipe
        )
      )
      @item['meta']['flags'] = array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES', 'HIDE_UNBREAKABLE', 'HIDE_DESTROYS', 'HIDE_PLACED_ON', 'HIDE_POTION_EFFECTS', 'HIDE_DYE')
      @item['meta']['lore'][] = '§f재료:'
      foreach(@ingredient_item in @cooking_recipes[@paged_shown_recipe]['ingredients']) {
        @item['meta']['lore'][] = '§f'.@ingredient_item['name'].' x'.@ingredient_item['qty']
        @inventory[@slot] = @item
      }
      @item['meta']['lore'][] = ''
      @item['meta']['lore'][] = '§f \ue002 레시피 선택 '
    }
    // 페이지에 따라 버튼 배치
    if(@page != 0) {
      @inventory[14] = array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f이전 페이지',
          'model': 105
        )
      )
    }
    if(@page != @max_page) {
      @inventory[16] = array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': '§f다음 페이지',
          'model': 106
        )
      )
    }
  }
}

proc _start_cooking(@smoker_location, @cooking_recipe, @force_start) {
  @cooking_tasks = import('cooking_tasks')
  @string_location = @smoker_location['x'].'_'.@smoker_location['y'].'_'.@smoker_location['z'].'_'.@smoker_location['world']
  
  if(@force_start || !array_index_exists(@cooking_tasks, @string_location)) {
    @cooking_task = array(
      'location': @smoker_location,
      'task': 0,
      'max_task': @cooking_recipe['max_task']
    )
    @cooking_tasks[@string_location] = @cooking_task
    broadcast('요리 시작')
  }
}

proc _stop_cooking(@smoker_location) {
  @cooking_tasks = import('cooking_tasks')
  @string_location = @smoker_location['x'].'_'.@smoker_location['y'].'_'.@smoker_location['z'].'_'.@smoker_location['world']

  if(array_index_exists(@cooking_tasks, @string_location)) {
    array_remove(@cooking_tasks, @string_location)
    broadcast('요리 끝')
  }
}

proc _task_cooking(@cooking_task) {
  @smoker_location = @cooking_task['location']
  if(get_block(@cooking_task['location']) == 'SMOKER') {
    if(@cooking_task['task'] < @cooking_task['max_task']) {
      @cooking_task['task']++ // 스킬, gui 보고 있는지 여부 등에 따라 진행도 조절
      // gui 세팅
      @smoker_data = _get_smoker_data(@smoker_location)
      @player = @smoker_data['viewer']
      if(!is_null(@player) && ponline(@player) && pinventory_holder(@player) == @smoker_data['gui_id'] && !@smoker_data['recipe_book']['enable']) {

      }

      return(true)
    } else {
      @cooking_recipes = import('cooking_recipes')
      @cooking_task['task'] = 0
      @smoker_data = _get_smoker_data(@smoker_location)
      @cooking_recipe = @cooking_recipes[@smoker_data['selected_recipe']]
      if(@cooking_recipe['category'] == 'need_fire' && !get_blockdata(@smoker_location)['lit']) {
        return(false)
      }
      @cooking_result_data = _get_cookable(@smoker_data['ingredients'], @cooking_recipe, true)
      if(@cooking_result_data['cookable']) { // 요리 가능할 시
        @smoker_data['ingredients'] = @cooking_result_data['new_ingredient_items'] // 재료 템 소모
        // 요리 결과아이템
        @result_item = @cooking_recipe['result']['item'][]
        if(@cooking_recipe['result']['is_ranked'] && array_index_exists(@result_item, 'meta', 'model') && !is_null(@result_item['meta']['model'])) {
          @result_item['meta']['model'] -= @result_item['meta']['model'] % 5
          @rank = integer((@cooking_result_data['accumulated_quality'] / @cooking_result_data['max_quality'] - (rand() * 0.4 - 0.2)) * 3)
          if(@rank < 0) {@rank = 0} else if(@rank > 2) {@rank = 2}
          @result_item['meta']['model'] += @rank
        } 
        _add_to_result_inventory(@smoker_location, @smoker_data, @result_item)
        _set_smoker_data(@smoker_location, @smoker_data)
        // gui 세팅
        @player = @smoker_data['viewer']
        if(!is_null(@player) && ponline(@player) && pinventory_holder(@player) == @smoker_data['gui_id'] && !@smoker_data['recipe_book']['enable']) {
          @smoker_interact_items = import('smoker_interact_items')
          @inventory = get_inventory(@smoker_data['gui_id'])
          foreach(@ingredient_key: @ingredient_item in @smoker_data['ingredients']) {
            if(@ingredient_key < 5) { @ingredient_slot = @ingredient_key + 4 } else { @ingredient_slot = @ingredient_key + 8 }
            if(is_array(@ingredient_item)) {
              @inventory[@ingredient_slot] = @ingredient_item
            } else {
              @inventory[@ingredient_slot] = @smoker_interact_items['default']['empty_slot']['ingredient']
            }
          }
          foreach(@result_key: @result_item in @smoker_data['results']) {
            if(@result_key < 5) { @result_slot = @result_key + 40 } else { @result_slot = @result_key + 44 }
            if(is_array(@result_item)) {
              @inventory[@result_slot] = @result_item
            } else {
              @inventory[@result_slot] = @smoker_interact_items['default']['empty_slot']['result']
            }
          }
          set_inventory(@smoker_data['gui_id'], @inventory)
        }
        // 다음 요리 가능 여부 체크 하여 요리 가능 여부 리턴
        @cooking_result_data = _get_cookable(@smoker_data['ingredients'], @cooking_recipe, false)
        if(@cooking_result_data['cookable']) {
          return(true)
        } else {
          return(false)
        }
      } else {
        return(false)
      }
    }
  } else {
    return(false)
  }
}

// 쿠킹 테이블 gui 열기
proc _open_cooking_table(@player, @uuid, @smoker_location, @text) {
  @smoker_data = _get_smoker_data(@smoker_location)
  if(@smoker_data) {
    @gui_id = _get_cooking_table_gui_id(@smoker_location)
    @old_viewer = @smoker_data['viewer']
    if(!is_null(@old_viewer) && @old_viewer != @player && ponline(@old_viewer) && string_starts_with(pinventory_holder(@old_viewer), "@old_viewer.@gui_id")) {
      // 타 플레이어가 gui 열고 있을시 열 수 없다는 알림
      @prefix = @text['prefix']['failure']
      _send_instance_tooltip_msg(@player, @uuid, @prefix '다른 플레이어가 작업하고 있습니다.')
    } else {
      @is_gui_update = array(false)
      @cooking_recipes = import('cooking_recipes')
      ### gui 세팅 ###
      // 아이템
      @inventory = array()
      for(@index = 0, @index < 54, @index++) {
        @inventory[@index] = array(
          'name': 'STRUCTURE_VOID',
          'meta': array(
            'display': ' ',
            'model': 1
          )
        )
      }
      // 고정템 프리셋
      @smoker_interact_items = import('smoker_interact_items')
      // 타이틀
      @background_text_main = _color('#ffffff').@text['space_fonts']['space.-8'].'\ue9dd'.@text['space_fonts']['space.-169']._color('#404040').'요리 작업대'
      @background_text_default = _color('#ffffff').@text['space_fonts']['space.22'].'\ue9de'.@text['space_fonts']['space.-97']._color('#404040').'요리 재료/결과'
      @background_text_recipe = _color('#ffffff').@text['space_fonts']['space.22'].'\ue9df'.@text['space_fonts']['space.-97']._color('#404040').'요리 레시피 선택'
      // 연료 동기화
      @smoker_inventory = get_inventory(@smoker_location)
      if(is_array(@smoker_inventory[1])) {
        @inventory[37] = @smoker_inventory[1]
      } else {
        @inventory[37] = @smoker_interact_items['default']['empty_slot']['fuel']
      }
      // 훈연기 연소 여부
      if(get_blockdata(@smoker_location)['lit']) {
        @inventory[48]['meta']['model'] = 111
      } else {
        @inventory[48]['meta']['model'] = 110
      }
      // gui 연 경우 기본 상태 세팅
      if(is_null(@smoker_data['viewer'])) {
        @smoker_data['recipe_book']['category'] = 'everything'
        @smoker_data['recipe_book']['show_ready'] = false
        @smoker_data['recipe_book']['page'] = 0
      }
      // 레시피 모드에 따른 세팅
      if(@smoker_data['recipe_book']['enable']) { // 레시피 선택 모드 일시
        // 레시피 gui 타이틀
        @texture_layer = @background_text_main.@background_text_recipe
        // 레시피 선택 여부에 따른 아이템 세팅
        if(is_null(@smoker_data['selected_recipe'])) { // 레시피 선택 o
          @inventory[10] = @smoker_interact_items['default']['empty_slot']['recipe_choosing']
        } else { // 레시피 선택 x
          @cooking_recipe = @cooking_recipes[@smoker_data['selected_recipe']]
          @inventory[10] = @cooking_recipe['result']['item'][]
          @inventory[10]['meta']['lore'][] = '§f재료:'
          foreach(@ingredient_item in @cooking_recipe['ingredients']) {
            @inventory[10]['meta']['lore'][] = '§f'.@ingredient_item['name'].' x'.@ingredient_item['qty']
          }
          @inventory[10]['meta']['lore'][] = ''
          @inventory[10]['meta']['lore'][] = '§f \ue002 레시피 교체 취소 '
          @inventory[10]['meta']['lore'][] = '§f \ue003 레시피 선택 초기화 '
          // 요리 테스크 처리
          if(!(@cooking_recipe['category'] == 'need_fire' && !get_blockdata(@smoker_location)['lit'])) {
            @cooking_result_data = _get_cookable(@smoker_data['ingredients'], @cooking_recipe, false)
            if(@cooking_result_data['cookable']) { // 요리 가능할 시
              _start_cooking(@smoker_location, @cooking_recipe, false) // 시작 안되있을 경우 시작
            } else { // 요리 불가능일시
              _stop_cooking(@smoker_location)
            }
          }
        }
        // 카테고리
        @inventory[5] = @smoker_interact_items['recipe']['category']['everything']
        @inventory[6] = @smoker_interact_items['recipe']['category']['simple_cooking']
        @inventory[7] = @smoker_interact_items['recipe']['category']['need_fire']
        switch(@smoker_data['recipe_book']['category']) {
        case 'everything':
          @inventory[17]['meta']['model'] = 100
          break()
        case 'simple_cooking':
          @inventory[17]['meta']['model'] = 101
          break()
        case 'need_fire':
          @inventory[17]['meta']['model'] = 102
          break()
        }
        // 레시피 모두보기 요리가능만 보기 버튼
        if(@smoker_data['recipe_book']['show_ready']) {
          @inventory[13] = @smoker_interact_items['recipe']['button']['show_ready']
        } else {
          @inventory[13] = @smoker_interact_items['recipe']['button']['show_all']
        }
        // 레시피 목록 업데이트
        _update_paged_showen_recipes(get_inventory(@uuid), @smoker_data, @cooking_recipes)
        _set_smoker_data(@smoker_location, @smoker_data)
        // 레시피 목록으로 레시피북 세팅
        _update_recipe_book_inventory(@inventory, 0, @smoker_data, @cooking_recipes)
      } else { // 일반 모드 일시
        // 레시피 gui 타이틀
        @texture_layer = @background_text_main.@background_text_default
        // 레시피 선택 여부에 따른 아이템 세팅
        if(is_null(@smoker_data['selected_recipe'])) { // 레시피 선택 x
          @inventory[10] = @smoker_interact_items['default']['empty_slot']['recipe_unchosen']
        } else { // 레시피 선택 o
          @cooking_recipe = @cooking_recipes[@smoker_data['selected_recipe']]
          @inventory[10] = @cooking_recipe['result']['item'][]
          @inventory[10]['meta']['lore'][] = '§f재료:'
          foreach(@ingredient_item in @cooking_recipe['ingredients']) {
            @inventory[10]['meta']['lore'][] = '§f'.@ingredient_item['name'].' x'.@ingredient_item['qty']
          }
          if(@cooking_recipe['category'] == 'need_fire') {
            @inventory[10]['meta']['lore'][] = '§f불 필요'
          }
          @inventory[10]['meta']['lore'][] = ''
          @inventory[10]['meta']['lore'][] = '§f \ue002 레시피 교체 '
          @inventory[10]['meta']['lore'][] = '§f \ue003 레시피 선택 초기화 '
          // 요리 테스크 처리
          if(!(@cooking_recipe['category'] == 'need_fire' && !get_blockdata(@smoker_location)['lit'])) {
            @cooking_result_data = _get_cookable(@smoker_data['ingredients'], @cooking_recipe, false)
            if(@cooking_result_data['cookable']) { // 요리 가능할 시
              _start_cooking(@smoker_location, @cooking_recipe, false) // 시작 안되있을 경우 시작
            } else { // 요리 불가능일시
              _stop_cooking(@smoker_location)
            }
          }
        }
        // 재료칸 세팅
        foreach(@ingredient_key: @ingredient_item in @smoker_data['ingredients']) {
          if(@ingredient_key < 5) { @ingredient_slot = @ingredient_key + 4 } else { @ingredient_slot = @ingredient_key + 8 }
          if(is_array(@ingredient_item)) {
            @inventory[@ingredient_slot] = @ingredient_item
          } else {
            @inventory[@ingredient_slot] = @smoker_interact_items['default']['empty_slot']['ingredient']
          }
        }
        // 결과칸 세팅
        foreach(@result_key: @result_item in @smoker_data['results']) {
          if(@result_key < 5) { @result_slot = @result_key + 40 } else { @result_slot = @result_key + 44 }
          if(is_array(@result_item)) {
            @inventory[@result_slot] = @result_item
          } else {
            @inventory[@result_slot] = @smoker_interact_items['default']['empty_slot']['result']
          }
        }
      }

      @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @smoker_location, @smoker_data, @cooking_recipes, @is_gui_update, @text) {
        @smoker_data['viewer'] = @player
        @smoker_data['gui_id'] = @id
        _set_smoker_data(@smoker_location, @smoker_data)
        @fuel = array(
          'LAVA_BUCKET',
          'COAL_BLOCK',
          'COAL',
          'DRIED_KELP_BLOCK',
          'BLAZE_ROD',
          'CHARCOAL',
          'SCAFFOLDING',
          'CHISELED_BOOKSHELF',
          'MANGROVE_ROOTS',
          'LADDER',
          'CRAFTING_TABLE',
          'CARTOGRAPHY_TABLE',
          'FLETCHING_TABLE',
          'SMITHING_TABLE',
          'LOOM',
          'BOOKSHELF',
          'LECTERN',
          'CHEST',
          'TRAPPED_CHEST',
          'BARREL',
          'DAYLIGHT_DETECTOR',
          'JUCKBOX',
          'NOTE_BLOCK',
          'CROSSBOW',
          'BOW',
          'FISHING_ROD',
          'BOWL',
          'STICK',
          'WOODEN_PICKAXE',
          'WOODEN_SHOVEL',
          'WOODEN_HOE',
          'WOODEN_AXE',
          'WOODEN_SWORD',
          'AZALEA',
          'FLOWING_AZALEA',

          'OAK_LOG',
          'OAK_WOOD',
          'STRIPPED_OAK_LOG',
          'STRIPPED_OAK_WOOD',
          'OAK_PLANKS',
          'OAK_STAIRS',
          'OAK_SLAB',
          'OAK_FENCE',
          'OAK_FENCE_GATE',
          'OAK_DOOR',
          'OAK_TRAPDOOR',
          'OAK_PRESSURE_PLATE',
          'OAK_BUTTON',
          'OAK_SAPLING',
          'OAK_SIGN',
          'OAK_HANGING_SIGN',
          'OAK_BOAT',
          'OAK_CHEST_BOAT',
          
          'SPRUCE_LOG',
          'SPRUCE_WOOD',
          'STRIPPED_SPRUCE_LOG',
          'STRIPPED_SPRUCE_WOOD',
          'SPRUCE_PLANKS',
          'SPRUCE_STAIRS',
          'SPRUCE_SLAB',
          'SPRUCE_FENCE',
          'SPRUCE_FENCE_GATE',
          'SPRUCE_DOOR',
          'SPRUCE_TRAPDOOR',
          'SPRUCE_PRESSURE_PLATE',
          'SPRUCE_BUTTON',
          'SPRUCE_SAPLING',
          'SPRUCE_SIGN',
          'SPRUCE_HANGING_SIGN',
          'SPRUCE_BOAT',
          'SPRUCE_CHEST_BOAT',
          
          'BIRCH_LOG',
          'BIRCH_WOOD',
          'STRIPPED_BIRCH_LOG',
          'STRIPPED_BIRCH_WOOD',
          'BIRCH_PLANKS',
          'BIRCH_STAIRS',
          'BIRCH_SLAB',
          'BIRCH_FENCE',
          'BIRCH_FENCE_GATE',
          'BIRCH_DOOR',
          'BIRCH_TRAPDOOR',
          'BIRCH_PRESSURE_PLATE',
          'BIRCH_BUTTON',
          'BIRCH_SAPLING',
          'BIRCH_SIGN',
          'BIRCH_HANGING_SIGN',
          'BIRCH_BOAT',
          'BIRCH_CHEST_BOAT',
          
          'JUNGLE_LOG',
          'JUNGLE_WOOD',
          'STRIPPED_JUNGLE_LOG',
          'STRIPPED_JUNGLE_WOOD',
          'JUNGLE_PLANKS',
          'JUNGLE_STAIRS',
          'JUNGLE_SLAB',
          'JUNGLE_FENCE',
          'JUNGLE_FENCE_GATE',
          'JUNGLE_DOOR',
          'JUNGLE_TRAPDOOR',
          'JUNGLE_PRESSURE_PLATE',
          'JUNGLE_BUTTON',
          'JUNGLE_SAPLING',
          'JUNGLE_SIGN',
          'JUNGLE_HANGING_SIGN',
          'JUNGLE_BOAT',
          'JUNGLE_CHEST_BOAT',
          
          'ACACIA_LOG',
          'ACACIA_WOOD',
          'STRIPPED_ACACIA_LOG',
          'STRIPPED_ACACIA_WOOD',
          'ACACIA_PLANKS',
          'ACACIA_STAIRS',
          'ACACIA_SLAB',
          'ACACIA_FENCE',
          'ACACIA_FENCE_GATE',
          'ACACIA_DOOR',
          'ACACIA_TRAPDOOR',
          'ACACIA_PRESSURE_PLATE',
          'ACACIA_BUTTON',
          'ACACIA_SAPLING',
          'ACACIA_SIGN',
          'ACACIA_HANGING_SIGN',
          'ACACIA_BOAT',
          'ACACIA_CHEST_BOAT',
          
          'DARK_OAK_LOG',
          'DARK_OAK_WOOD',
          'STRIPPED_DARK_OAK_LOG',
          'STRIPPED_DARK_OAK_WOOD',
          'DARK_OAK_PLANKS',
          'DARK_OAK_STAIRS',
          'DARK_OAK_SLAB',
          'DARK_OAK_FENCE',
          'DARK_OAK_FENCE_GATE',
          'DARK_OAK_DOOR',
          'DARK_OAK_TRAPDOOR',
          'DARK_OAK_PRESSURE_PLATE',
          'DARK_OAK_BUTTON',
          'DARK_OAK_SAPLING',
          'DARK_OAK_SIGN',
          'DARK_OAK_HANGING_SIGN',
          'DARK_OAK_BOAT',
          'DARK_OAK_CHEST_BOAT',
          
          'MANGROVE_LOG',
          'MANGROVE_WOOD',
          'STRIPPED_MANGROVE_LOG',
          'STRIPPED_MANGROVE_WOOD',
          'MANGROVE_PLANKS',
          'MANGROVE_STAIRS',
          'MANGROVE_SLAB',
          'MANGROVE_FENCE',
          'MANGROVE_FENCE_GATE',
          'MANGROVE_DOOR',
          'MANGROVE_TRAPDOOR',
          'MANGROVE_PRESSURE_PLATE',
          'MANGROVE_BUTTON',
          'MANGROVE_PROPAGULE',
          'MANGROVE_SIGN',
          'MANGROVE_HANGING_SIGN',
          'MANGROVE_BOAT',
          'MANGROVE_CHEST_BOAT',
          
          'BAMBOO',
          'BAMBOO_BLOCK',
          'STRIPPED_BAMBOO_BLOCK',
          'BAMBOO_PLANKS',
          'BAMBOO_STAIRS',
          'BAMBOO_SLAB',
          'BAMBOO_MOSAIC_PLANKS',
          'BAMBOO_MOSAIC_STAIRS',
          'BAMBOO_MOSAIC_SLAB',
          'BAMBOO_FENCE',
          'BAMBOO_FENCE_GATE',
          'BAMBOO_DOOR',
          'BAMBOO_TRAPDOOR',
          'BAMBOO_PRESSURE_PLATE',
          'BAMBOO_BUTTON',
          '_SAPLING',
          'BAMBOO_SIGN',
          'BAMBOO_HANGING_SIGN',
          'BAMBOO_BOAT',
          'BAMBOO_CHEST_BOAT',

          'WHITE_BANNER',
          'LIGHT_GRAY_BANNER',
          'GRAY_BANNER',
          'BLACK_BANNER',
          'BROWN_BANNER',
          'RED_BANNER',
          'ORANGE_BANNER',
          'YELLOW_BANNER',
          'LIME_BANNER',
          'GREEN_BANNER',
          'CYAN_BANNER',
          'LIGHT_BLUE_BANNER',
          'BLUE_BANNER',
          'PURPLE_BANNER',
          'MEGENTA_BANNER',
          'PINK_BANNER',

          'WHITE_WOOL',
          'LIGHT_GRAY_WOOL',
          'GRAY_WOOL',
          'BLACK_WOOL',
          'BROWN_WOOL',
          'RED_WOOL',
          'ORANGE_WOOL',
          'YELLOW_WOOL',
          'LIME_WOOL',
          'GREEN_WOOL',
          'CYAN_WOOL',
          'LIGHT_BLUE_WOOL',
          'BLUE_WOOL',
          'PURPLE_WOOL',
          'MEGENTA_WOOL',
          'PINK_WOOL',

          'WHITE_CARPET',
          'LIGHT_GRAY_CARPET',
          'GRAY_CARPET',
          'BLACK_CARPET',
          'BROWN_CARPET',
          'RED_CARPET',
          'ORANGE_CARPET',
          'YELLOW_CARPET',
          'LIME_CARPET',
          'GREEN_CARPET',
          'CYAN_CARPET',
          'LIGHT_BLUE_CARPET',
          'BLUE_CARPET',
          'PURPLE_CARPET',
          'MEGENTA_CARPET',
          'PINK_CARPET'
        )
        bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @id, @texture_layer, @message, @smoker_location, @cooking_recipes, @is_gui_update, @fuel, @text) {
          @smoker_interact_items = import('smoker_interact_items')
          @player_data = import('players_data')[@uuid]
          @smoker_data = _get_smoker_data(@smoker_location)
          @rawslot = @event['rawslot']
          @action = @event['action']
          @cursor_item = @event['cursoritem']
          if(@rawslot >= 0 && @rawslot <= 53) {
            cancel()
            @slot_item = @event['inventory'][@rawslot]
            @play_sound = false
            if(@rawslot % 9 < 3) { // 좌측 gui
              switch(@rawslot) {
              case 10:
                if(@event['clicktype'] == 'LEFT' && (@action == 'PICKUP_ALL' || @action == 'SWAP_WITH_CURSOR')) {
                  if(@smoker_data['recipe_book']['enable']) {
                    @smoker_data['recipe_book']['enable'] = false
                  } else {
                    @smoker_data['recipe_book']['enable'] = true
                  }
                  @play_sound = true
                  _set_smoker_data(@smoker_location, @smoker_data)
                  @is_gui_update[0] = true
                  _open_cooking_table(@player, @uuid, @smoker_location, @text) // 레시피 모드가 클릭시 바뀌므로 gui 새로 열기
                }
                if(@event['clicktype'] == 'RIGHT' && (@action == 'PICKUP_HALF' || @action == 'SWAP_WITH_CURSOR')) {
                  if(@slot_item['meta']['display'] != '§f선택된 레시피 없음') {
                    if(@smoker_data['recipe_book']['enable']) {
                      set_inventory_item(@id, 10, @smoker_interact_items['default']['empty_slot']['recipe_choosing'])
                    } else {
                      set_inventory_item(@id, 10, @smoker_interact_items['default']['empty_slot']['recipe_unchosen'])
                    }
                    @play_sound = true
                    @smoker_data['selected_recipe'] = null
                    _set_smoker_data(@smoker_location, @smoker_data)
                    // 요리 테스크 처리
                    _stop_cooking(@smoker_location)
                  }
                }
                break()
              case 37:
                @fuel_item_at_that_time = get_inventory_item(@smoker_location, 1)
                if(!is_null(@fuel_item_at_that_time)) {
                  modify_event('slotitem', @fuel_item_at_that_time)
                }
                if(is_null(@slot_item)) {
                  if(is_null(@fuel_item_at_that_time)) {
                    modify_event('slotitem', @smoker_interact_items['default']['empty_slot']['fuel'])
                  } else {
                    modify_event('slotitem', @fuel_item_at_that_time)
                  }
                  cancel()
                } else {
                  @fuel_being_empty = false
                  switch(@action) {
                  // 핫바에 있는 아이템과 바꿀려 하는 경우
                  case 'HOTBAR_MOVE_AND_READD':
                    if(is_null(@cursor_item)) {
                      @swapslot = @event['hotbarbutton']
                      if(@event['hotbarbutton'] == -1 ) { @swapslot = 40 }
                      @swap_item = get_inventory_item(@uuid, @swapslot)
                      if(array_contains(@fuel, @swap_item['name'])) {
                        cancel(false)
                        if(is_null(@fuel_item_at_that_time)) { // 아이템을 넣은 경우
                          modify_event('slotitem', null) // 연료 칸 비어있는 것처럼 세팅
                        }
                      }
                    }
                    break()
                  // 커서에 있는 아이템과 바꿀려 하는 경우
                  case 'SWAP_WITH_CURSOR':
                    if(array_contains(@fuel, @cursor_item['name'])) {
                      cancel(false)
                      if(is_null(@fuel_item_at_that_time)) { // 아이템을 넣은 경우
                        modify_event('slotitem', null) // 연료 칸 비어있는 것처럼 세팅
                      }
                    }
                    break()
                  // 아이템 칸 비워질 시
                  case 'HOTBAR_SWAP':
                  case 'DROP_ALL_SLOT':
                  case 'PICKUP_ALL':
                    if(is_array(@fuel_item_at_that_time)) {
                      cancel(false)
                      @fuel_being_empty = true
                    }
                    break()
                  // 아이템 칸 비워질수도 안 비워질 수도 있을 시 (기존 아이템이 하나일 경우 비워질 수 있음)  
                  case 'DROP_ONE_SLOT':
                  case 'PICKUP_HALF':
                    if(is_array(@fuel_item_at_that_time)) {
                      cancel(false)
                      if(@fuel_item_at_that_time['qty'] == 1) {
                        @fuel_being_empty = true
                      }
                    }
                    break()
                  // 같은 아이템 재료 추가시
                  case 'PLACE_ONE':
                  case 'PLACE_SOME':
                  case 'PLACE_ALL':
                    if(is_array(@fuel_item_at_that_time)) {
                      cancel(false)
                    }
                    break()
                  // 쉬프트 클릭
                  case 'MOVE_TO_OTHER_INVENTORY':
                    @fuel_item_at_that_time_copy = null
                    if(is_array(@fuel_item_at_that_time)) {
                      cancel(false)
                      @pinventory = pinv(@player)
                      @fuel_item_at_that_time_copy = array_deep_clone(@fuel_item_at_that_time)
                      array_remove(@fuel_item_at_that_time_copy, 'qty')
                      @max_qty = max_stack_size(@fuel_item_at_that_time)
                      @my_qty = @fuel_item_at_that_time['qty']
                      @empty_key = -1
                      @indexes = array(8,7,6,5,4,3,2,1,0,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9)
                      foreach(@key in @indexes) {
                        @inventory_item = @pinventory[@key]
                        if(is_array(@inventory_item)) {
                          @inventory_item_copy = array_deep_clone(@inventory_item)
                          array_remove(@inventory_item_copy, 'qty')
                          if(@inventory_item_copy == @fuel_item_at_that_time_copy) {                      
                            @remaining_qty = @max_qty - @inventory_item['qty'] // 빈공간
                            if(@remaining_qty < @my_qty) { // 인벤칸 아이템 남은 갯수 < 넣을려는 갯수
                              @my_qty -= @remaining_qty
                            } else { // 인벤칸 아이템 남은 갯수 < 넣을려는 갯수
                              @my_qty = 0
                            }
                          }
                        } else {
                          if(@empty_key == -1) {
                            @empty_key = @key
                          }
                        }
                      }
                      if(@my_qty > 0 && @empty_key >= 0) { // 여유 공간 있을 경우
                        @my_qty = 0
                      }
                      if(@my_qty == 0) {
                        @fuel_being_empty = true
                      }
                    }
                    break()
                  }
                  @fuel_being_change = !is_cancelled()
                  set_timeout(0, closure() {
                    @fuel_item = get_inventory_item(@id, 37)
                    if(@fuel_being_empty) {
                      set_inventory_item(@id, 37, @smoker_interact_items['default']['empty_slot']['fuel'])
                      @fuel_item = null
                    }
                    if(@fuel_being_change) {
                      //@lit = get_blockdata(@smoker_location)['lit']
                      set_inventory_item(@smoker_location, 1, @fuel_item)
                    
                      set_timeout(0, closure() {
                        if(get_blockdata(@smoker_location)['lit']) {
                          set_inventory_item(@id, 48, array(
                            'name': 'STRUCTURE_VOID',
                            'meta': array(
                              'display': ' ',
                              'model': 111
                            )
                          ))
                        } else {
                          set_inventory_item(@id, 48, array(
                            'name': 'STRUCTURE_VOID',
                            'meta': array(
                              'display': ' ',
                              'model': 110
                            )
                          ))
                        }
                      })
                    }
                  })
                }
                break()
              }
            } else { // 우측 gui
              if(@smoker_data['recipe_book']['enable']) { // 레시피 선택 모드
                if(@event['clicktype'] == 'LEFT' && (@action == 'PICKUP_ALL' || @action == 'SWAP_WITH_CURSOR')) {
                  @recipebook_update = false
                  @inventory = get_inventory(@id)
                  switch(@rawslot) {
                  case 5: // 모든 카테고리
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      if(@smoker_data['recipe_book']['category'] != 'everything') {
                        @smoker_data['recipe_book']['category'] = 'everything'
                        @inventory[17]['meta']['model'] = 100
                        @play_sound = true
                        @recipebook_update = true
                        // 레시피 목록 업데이트
                        _update_paged_showen_recipes(get_inventory(@uuid), @smoker_data, @cooking_recipes)
                        _set_smoker_data(@smoker_location, @smoker_data)
                        // 레시피 목록으로 레시피북 세팅
                        _update_recipe_book_inventory(@inventory, 0, @smoker_data, @cooking_recipes)
                      }
                    }
                    break()
                  case 6: // 단순 조리 및 손질 카테고리
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      if(@smoker_data['recipe_book']['category'] != 'simple_cooking') {
                        @smoker_data['recipe_book']['category'] = 'simple_cooking'
                        @inventory[17]['meta']['model'] = 101
                        @play_sound = true
                        @recipebook_update = true
                        // 레시피 목록 업데이트
                        _update_paged_showen_recipes(get_inventory(@uuid), @smoker_data, @cooking_recipes)
                        _set_smoker_data(@smoker_location, @smoker_data)
                        // 레시피 목록으로 레시피북 세팅
                        _update_recipe_book_inventory(@inventory, 0, @smoker_data, @cooking_recipes)
                      }
                    }
                    break()
                  case 7: // 불 사용 카테고리
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      if(@smoker_data['recipe_book']['category'] != 'need_fire') {
                        @smoker_data['recipe_book']['category'] = 'need_fire'
                        @inventory[17]['meta']['model'] = 102
                        @play_sound = true
                        @recipebook_update = true
                        // 레시피 목록 업데이트
                        _update_paged_showen_recipes(get_inventory(@uuid), @smoker_data, @cooking_recipes)
                        _set_smoker_data(@smoker_location, @smoker_data)
                        // 레시피 목록으로 레시피북 세팅
                        _update_recipe_book_inventory(@inventory, 0, @smoker_data, @cooking_recipes)
                      }
                    }
                    break()
                  case 13: // 모두 보기 여부
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      if(@smoker_data['recipe_book']['show_ready']) {
                        @smoker_data['recipe_book']['show_ready'] = false
                        @inventory[13] = @smoker_interact_items['recipe']['button']['show_all']
                      } else {
                        @smoker_data['recipe_book']['show_ready'] = true
                        @inventory[13] = @smoker_interact_items['recipe']['button']['show_ready']
                      }
                      @play_sound = true
                      @recipebook_update = true
                      // 레시피 목록 업데이트
                      _update_paged_showen_recipes(get_inventory(@uuid), @smoker_data, @cooking_recipes)
                      _set_smoker_data(@smoker_location, @smoker_data)
                      // 레시피 목록으로 레시피북 세팅
                      _update_recipe_book_inventory(@inventory, 0, @smoker_data, @cooking_recipes)
                    }
                    break()
                  case 14: // 이전 페이지
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      // 버튼 활성화 되있을 시
                      @play_sound = true
                      @recipebook_update = true
                      // 페이지 업데이트 및 레시피 목록으로 레시피북 세팅
                      @smoker_data['recipe_book']['page']--
                      _update_recipe_book_inventory(@inventory, @smoker_data['recipe_book']['page'], @smoker_data, @cooking_recipes)
                    }
                    break()
                  case 16: // 다음 페이지
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      // 버튼 활성화 되있을 시
                      @play_sound = true
                      @recipebook_update = true
                      // 페이지 업데이트 및 레시피 목록으로 레시피북 세팅
                      @smoker_data['recipe_book']['page']++
                      _update_recipe_book_inventory(@inventory, @smoker_data['recipe_book']['page'], @smoker_data, @cooking_recipes)
                    }
                    break()
                  case 22..26:
                  case 31..35:
                  case 40..44:
                  case 49..53: // 레시피 선택
                    // 아이템에서 레시피 이름 구하기
                    @selected_recipe = null
                    if(array_index_exists(@slot_item, 'meta', 'modifiers', 0)) { @selected_recipe = @slot_item['meta']['modifiers'][0]['name'] }
                    // 레시피 있을 시 레시피 선택
                    if(!is_null(@selected_recipe)) {
                      @smoker_data['selected_recipe'] = @selected_recipe
                      @smoker_data['recipe_book']['enable'] = false
                      @play_sound = true
                      _set_smoker_data(@smoker_location, @smoker_data)
                      // 요리 테스크 취소
                      _stop_cooking(@smoker_location)
                      // 취소만 해도 다시 gui 열때 요리 가능할 경우 요리 시작됨
                      @is_gui_update[0] = true
                      _open_cooking_table(@player, @uuid, @smoker_location, @text)
                    }
                    break()
                  }
                  if(@recipebook_update) {
                    set_inventory(@id, @inventory)
                  }
                }
              } else { // 일반모드
                switch(@rawslot) {
                case 4..8:
                case 13..17:
                  @ingredient_being_empty = false
                  if(@rawslot < 9) { @ingredient_key = @rawslot - 4 } else { @ingredient_key = @rawslot - 8 }
                  @ingredient_item = @smoker_data['ingredients'][@ingredient_key]
                  switch(@action) {
                  // 핫바에 있는 아이템과 바꿀려 하는 경우
                  case 'HOTBAR_MOVE_AND_READD':
                    if(is_null(@cursor_item)) {
                      cancel(false)
                      if(is_null(@ingredient_item)) { // 아이템을 넣은 경우
                        modify_event('slotitem', null) // 재료 칸 비어있는 것처럼 세팅
                      }
                    }
                    break()
                  // 커서에 있는 아이템과 바꿀려 하는 경우
                  case 'SWAP_WITH_CURSOR':
                    cancel(false)
                    if(is_null(@ingredient_item)) { // 아이템을 넣은 경우
                      modify_event('slotitem', null) // 재료 칸 비어있는 것처럼 세팅
                    }
                    break()
                  // 아이템 칸 비워질 시
                  case 'HOTBAR_SWAP':
                  case 'DROP_ALL_SLOT':
                  case 'PICKUP_ALL':
                    if(is_array(@ingredient_item)) {
                      cancel(false)
                      @ingredient_being_empty = true
                    }
                    break()
                  // 아이템 칸 비워질수도 안 비워질 수도 있을 시 (기존 아이템이 하나일 경우 비워질 수 있음)  
                  case 'DROP_ONE_SLOT':
                  case 'PICKUP_HALF':
                    if(is_array(@ingredient_item)) {
                      cancel(false)
                      if(@ingredient_item['qty'] == 1) {
                        @ingredient_being_empty = true
                      }
                    }
                    break()
                  // 같은 아이템 재료 추가시
                  case 'PLACE_ONE':
                  case 'PLACE_SOME':
                  case 'PLACE_ALL':
                    if(is_array(@ingredient_item)) {
                      cancel(false)
                    }
                    break()
                  // 쉬프트 클릭
                  case 'MOVE_TO_OTHER_INVENTORY':
                    @ingredient_item_copy = null
                    if(is_array(@ingredient_item)) {
                      cancel(false)
                      @pinventory = pinv(@player)

                      @ingredient_item_copy = array_deep_clone(@ingredient_item)
                      array_remove(@ingredient_item_copy, 'qty')
                    
                      @max_qty = max_stack_size(@ingredient_item)
                      @my_qty = @ingredient_item['qty']
                      @empty_key = -1
                      
                      @indexes = array(8,7,6,5,4,3,2,1,0,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9)
                      foreach(@key in @indexes) {
                        @inventory_item = @pinventory[@key]
                        if(is_array(@inventory_item)) {
                          @inventory_item_copy = array_deep_clone(@inventory_item)
                          array_remove(@inventory_item_copy, 'qty')
                          
                          if(@inventory_item_copy == @ingredient_item_copy) {                      
                            @remaining_qty = @max_qty - @inventory_item['qty'] // 빈공간
                            if(@remaining_qty < @my_qty) { // 인벤칸 아이템 남은 갯수 < 넣을려는 갯수
                              @my_qty -= @remaining_qty
                            } else { // 인벤칸 아이템 남은 갯수 < 넣을려는 갯수
                              @my_qty = 0
                            }
                          }
                        } else {
                          if(@empty_key == -1) {
                            @empty_key = @key
                          }
                        }
                      }

                      if(@my_qty > 0 && @empty_key >= 0) { // 여유 공간 있을 경우
                        @my_qty = 0
                      }
                      if(@my_qty == 0) {
                        @ingredient_being_empty = true
                      }
                    }
                    break()
                  }
                  // 클릭 완료후 상태에 따른 처리
                  @ingredient_being_change = !is_cancelled()
                  set_timeout(0, closure() {
                    @new_ingredient_item = get_inventory_item(@id, @rawslot)
                    if(@ingredient_being_empty) {
                      set_inventory_item(@id, @rawslot, @smoker_interact_items['default']['empty_slot']['ingredient'])
                      @new_ingredient_item = null
                    }
                    if(@ingredient_being_change) {
                      @smoker_data['ingredients'][@ingredient_key] = @new_ingredient_item
                      _set_smoker_data(@smoker_location, @smoker_data)
                      // 요리 테스크 처리
                      if(!is_null(@smoker_data['selected_recipe'])) {
                        @cooking_recipe = @cooking_recipes[@smoker_data['selected_recipe']]
                        if(!(@cooking_recipe['category'] == 'need_fire' && !get_blockdata(@smoker_location)['lit'])) {
                          @cooking_result_data = _get_cookable(@smoker_data['ingredients'], @cooking_recipe, false)
                          if(@cooking_result_data['cookable']) { // 요리 가능할 시
                            _start_cooking(@smoker_location, @cooking_recipe, false) // 시작 안되있을 경우 시작
                          } else { // 요리 불가능할 시
                            _stop_cooking(@smoker_location)
                          }
                        } else {
                          _stop_cooking(@smoker_location)
                        }
                      }
                    }
                  })
                  break()
                case 40..44:
                case 49..53:
                  @result_being_empty = false
                  if(@rawslot < 45) { @result_key = @rawslot - 40 } else { @result_key = @rawslot - 44 }
                  @result_item = @smoker_data['results'][@result_key]
                  if(is_array(@result_item) && !array_index_exists(@result_item, 'qty')) { @result_item['qty'] = 1 }
                  switch(@action) {
                  // 핫바에 있는 아이템과 바꿀려 하는 경우 (불가능)
                  case 'HOTBAR_MOVE_AND_READD':
                    break()
                  // 커서에 있는 아이템과 바꿀려 하는 경우 (불가능)
                  case 'SWAP_WITH_CURSOR':
                    break()
                  // 아이템 칸 비워질 시
                  case 'HOTBAR_SWAP':
                  case 'DROP_ALL_SLOT':
                  case 'PICKUP_ALL':
                    if(is_array(@result_item)) {
                      cancel(false)
                      @result_being_empty = true
                    }
                    break()
                  // 아이템 칸 비워질수도 안 비워질 수도 있을 시 (기존 아이템이 하나일 경우 비워질 수 있음)  
                  case 'DROP_ONE_SLOT':
                  case 'PICKUP_HALF':
                    if(is_array(@result_item)) {
                      cancel(false)
                      if(@result_item['qty'] == 1) {
                        @result_being_empty = true
                      }
                    }
                    break()
                  // 같은 아이템 결과 추가시 (불가능)
                  case 'PLACE_ONE':
                  case 'PLACE_SOME':
                  case 'PLACE_ALL':
                    break()
                  // 쉬프트 클릭
                  case 'MOVE_TO_OTHER_INVENTORY':
                    @result_item_copy = null
                    if(is_array(@result_item)) {
                      cancel(false)
                      @pinventory = pinv(@player)

                      @result_item_copy = array_deep_clone(@result_item)
                      array_remove(@result_item_copy, 'qty')
                    
                      @max_qty = max_stack_size(@result_item)
                      @my_qty = @result_item['qty']
                      @empty_key = -1
                      
                      @indexes = array(8,7,6,5,4,3,2,1,0,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9)
                      foreach(@key in @indexes) {
                        @inventory_item = @pinventory[@key]
                        if(is_array(@inventory_item)) {
                          @inventory_item_copy = array_deep_clone(@inventory_item)
                          array_remove(@inventory_item_copy, 'qty')
                          
                          if(@inventory_item_copy == @result_item_copy) {                      
                            @remaining_qty = @max_qty - @inventory_item['qty'] // 빈공간
                            if(@remaining_qty < @my_qty) { // 인벤칸 아이템 남은 갯수 < 넣을려는 갯수
                              @my_qty -= @remaining_qty
                            } else { // 인벤칸 아이템 남은 갯수 < 넣을려는 갯수
                              @my_qty = 0
                            }
                          }
                        } else {
                          if(@empty_key == -1) {
                            @empty_key = @key
                          }
                        }
                      }

                      if(@my_qty > 0 && @empty_key >= 0) { // 여유 공간 있을 경우
                        @my_qty = 0
                      }
                      if(@my_qty == 0) {
                        @result_being_empty = true
                      }
                    }
                    break()
                  }

                  @result_being_change = !is_cancelled()
                  set_timeout(0, closure() {
                    @new_result_item = get_inventory_item(@id, @rawslot)
                    if(@result_being_empty) {
                      set_inventory_item(@id, @rawslot, @smoker_interact_items['default']['empty_slot']['result'])
                      @new_result_item = null
                    }
                    if(@result_being_change) {
                      @smoker_data['results'][@result_key] = @new_result_item
                      _set_smoker_data(@smoker_location, @smoker_data)
                    }
                  })
                  break()
                }
              }
            }
            if(@play_sound) {
              play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
            }
          } else if(54 <= @rawslot && @rawslot <= 89) {
            @slot = @event['slot']
            @inventory = get_inventory(@id)
            @pinventory = pinv(@player)
            @slot_item = @pinventory[@slot]

            @fuel_being_empty = false
            @fuel_being_change = false

            switch(@action) {
            case 'MOVE_TO_OTHER_INVENTORY':
              @fuel_item_at_that_time = get_inventory_item(@smoker_location, 1)
              @fuel_item_at_that_time_copy = null
              if(is_array(@fuel_item_at_that_time)) {
                @fuel_item_at_that_time_copy = array_deep_clone(@fuel_item_at_that_time)
                array_remove(@fuel_item_at_that_time_copy, 'qty')
              }
              @slot_item_copy = null
              if(is_array(@slot_item)) {
                @slot_item_copy = array_deep_clone(@slot_item)
                array_remove(@slot_item_copy, 'qty')
              }
              if(@smoker_data['recipe_book']['enable']) { // 레시피 모드
                if(is_array(@fuel_item_at_that_time)) { // 이미 연료 있을시
                  if(@fuel_item_at_that_time_copy == @slot_item_copy) { // 같은 연료 템을 추가로 넣는 경우
                    @max_qty = max_stack_size(@fuel_item_at_that_time)
                    if(@fuel_item_at_that_time['qty'] < @max_qty) { // 연료 꽉차있지 않으면
                      @fuel_being_change = true // 동기화
                    }
                  }
                } else {
                  if(array_contains(@fuel, @slot_item['name'])) { // 연료 하나도 없으면
                    @fuel_being_change = true
                    set_inventory_item(@id, 37, null) // 가상 gui 빈칸으로 만들어서 템 들어가게 하기
                  }
                }
              } else { // 요리 모드
                @max_qty = max_stack_size(@slot_item)
                @my_qty = @slot_item['qty']
                @empty_key = -1
                // 재료 처리
                foreach(@key: @ingredient_item in @smoker_data['ingredients']) {
                  if(is_array(@ingredient_item)) {
                    @ingredient_item_copy = array_deep_clone(@ingredient_item)
                    array_remove(@ingredient_item_copy, 'qty')
                    if(@ingredient_item_copy == @slot_item_copy) {
                      @remaining_qty = @max_qty - @ingredient_item['qty']
                      if(@remaining_qty < @my_qty) { // 재료칸 아이템 남은 갯수보다 넣을려는 갯수가 많을경우
                        @smoker_data['ingredients'][@key]['qty'] = @max_qty
                        @my_qty -= @remaining_qty
                      } else { // 재료칸 아이템 남은 갯수보다 넣을려는 갯수가 적거나 같을경우
                        @smoker_data['ingredients'][@key]['qty'] += @my_qty
                        @my_qty = 0
                      }
                    }
                  } else {
                    if(@empty_key == -1) {
                      @empty_key = @key
                    }
                  }
                }
                // 연료 처리
                if(is_array(@fuel_item_at_that_time)) { // 이미 연료 있을시
                  if(@fuel_item_at_that_time_copy == @slot_item_copy) { // 같은 연료 템을 추가로 넣는 경우
                    @remaining_qty = @max_qty - @fuel_item_at_that_time['qty']
                    if(@remaining_qty < @my_qty) { // 연료칸 아이템 남은 갯수보다 넣을려는 갯수가 많을경우
                      @fuel_being_change = true
                      @my_qty -= @remaining_qty
                    } else { // 연료칸 아이템 남은 갯수보다 넣을려는 갯수가 적거나 같을경우
                      @fuel_being_change = true
                      @my_qty = 0
                    }
                  }
                } else { // 연료 하나도 없을시
                  if(array_contains(@fuel, @slot_item['name']) && !array_contains(array('STICK', 'BOWL'), @slot_item['name'])) {
                    set_inventory_item(@id, 37, null) // 가상 gui 빈칸으로 만들어서 템 들어가게 하기
                    @fuel_being_change = true
                    @my_qty = 0
                  }
                }
                // 오버 된 경우 처리
                if(@my_qty > 0) {
                  if(@empty_key >= 0) {
                    if(@empty_key < 5) { @empty_slot = @empty_key + 4 } else { @empty_slot = @empty_key + 8 }
                    set_inventory_item(@id, @empty_slot, null)
                    @smoker_data['ingredients'][@empty_key] = @slot_item
                    @smoker_data['ingredients'][@empty_key]['qty'] = @my_qty
                  }
                }
                _set_smoker_data(@smoker_location, @smoker_data)
                // 요리 테스크 처리
                if(!is_null(@smoker_data['selected_recipe'])) {
                  @cooking_recipe = @cooking_recipes[@smoker_data['selected_recipe']]
                  if(!(@cooking_recipe['category'] == 'need_fire' && !get_blockdata(@smoker_location)['lit'])) {
                    @cooking_result_data = _get_cookable(@smoker_data['ingredients'], @cooking_recipe, false)
                    if(@cooking_result_data['cookable']) { // 요리 가능해졌을 시
                      _start_cooking(@smoker_location, @cooking_recipe, false) // 시작 안되있을 경우 시작
                    }
                  }
                }
              }
              break()
            case 'COLLECT_TO_CURSOR':
              @fuel_item_at_that_time = get_inventory_item(@smoker_location, 1)
              @fuel_item_at_that_time_copy = null
              if(is_array(@fuel_item_at_that_time)) {
                @fuel_item_at_that_time_copy = array_deep_clone(@fuel_item_at_that_time)
                array_remove(@fuel_item_at_that_time_copy, 'qty')
              }
              @cursor_item_copy = null
              if(is_array(@cursor_item)) {
                @cursor_item_copy = array_deep_clone(@cursor_item)
                array_remove(@cursor_item_copy, 'qty')
              }
              if(@smoker_data['recipe_book']['enable']) { // 레시피 모드
                if(@fuel_item_at_that_time_copy == @cursor_item_copy) {
                  @max_qty = max_stack_size(@cursor_item)
                  if(@cursor_item['qty'] < @max_qty) {
                    @fuel_being_change = true
                  }
                  if(@cursor_item['qty'] + @fuel_item_at_that_time['qty'] <= @max_qty) { // 다 꺼냇을 경우
                    @fuel_being_empty = true
                  }
                }
              } else { // 요리 모드
                set_timeout(0, closure() {
                  @new_inventory = get_inventory(@id)
                  // 재료
                  @new_ingredients = array()
                  @is_ingredients_changed = false
                  for(@index = 0, @index < 10, @index++) {
                    if(@index < 5) { @key = @index + 4 } else { @key = @index + 8 }
                    if(is_null(@new_inventory[@key])) {
                      @new_ingredients[@index] = null
                      set_inventory_item(@id, @key, @smoker_interact_items['default']['empty_slot']['ingredient'])
                    } else if(@new_inventory[@key]['name'] == 'STRUCTURE_VOID') {
                      @new_ingredients[@index] = null
                    } else {
                      @new_ingredients[@index] = @new_inventory[@key]
                    }
                    if(!@is_ingredients_changed && @new_ingredients[@index] != @smoker_data['ingredients'][@index]) {
                      @is_ingredients_changed = true
                    }
                  }
                  if(@is_ingredients_changed) {
                    @smoker_data['ingredients'] = @new_ingredients
                    _set_smoker_data(@smoker_location, @smoker_data)
                    // 요리 테스크 처리
                    if(!is_null(@smoker_data['selected_recipe'])) {
                      @cooking_recipe = @cooking_recipes[@smoker_data['selected_recipe']]
                      if(!(@cooking_recipe['category'] == 'need_fire' && !get_blockdata(@smoker_location)['lit'])) {
                        @cooking_result_data = _get_cookable(@smoker_data['ingredients'], @cooking_recipe, false)
                        if(!@cooking_result_data['cookable']) { // 요리 불가능해졌을 시
                          _stop_cooking(@smoker_location)
                        }
                      } else {
                        _stop_cooking(@smoker_location)
                      }
                    }
                  }
                  // 연료
                  if(is_null(@new_inventory[37])) {
                    @new_fuel_item = null
                    set_inventory_item(@id, 37, @smoker_interact_items['default']['empty_slot']['fuel'])
                  } else if(@new_inventory[37]['name'] == 'STRUCTURE_VOID') {
                    @new_fuel_item = null
                  } else {
                    @new_fuel_item = @new_inventory[37]
                  }
                  if(@fuel_item_at_that_time != @new_fuel_item) {
                    set_inventory_item(@smoker_location, 1, @new_fuel_item)
                  }
                })
              }
              break()
            }
            set_timeout(0, closure() {
              @fuel_item = get_inventory_item(@id, 37)
              if(@fuel_being_empty) {
                set_inventory_item(@id, 37, @smoker_interact_items['default']['empty_slot']['fuel'])
                @fuel_item = null
              }
              if(@fuel_being_change) {
                set_inventory_item(@smoker_location, 1, @fuel_item)
              }
              // 인벤토리 수정된 이후 타임아웃 하고나서의 인벤 기준 레시피 북 세팅
              if(@smoker_data['recipe_book']['enable'] && !array_contains(array('NOTHING', 'HOTBAR_SWAP', 'MOVE_TO_OTHER_INVENTORY'), @action)) {
                // 레시피 목록 업데이트
                _update_paged_showen_recipes(get_inventory(@uuid), @smoker_data, @cooking_recipes)
                _set_smoker_data(@smoker_location, @smoker_data)
                // 레시피 목록으로 레시피북 세팅
                _update_recipe_book_inventory(@inventory, @smoker_data['recipe_book']['page'], @smoker_data, @cooking_recipes)
                // 인벤토리 최종 업뎃
                set_inventory(@id, @inventory)
              }
            })
          }
        }

        bind('inventory_close', array('id': "close.@id"), array('virtual': true), @event, @player, @uuid, @id, @smoker_location, @is_gui_update) {
          if(@event['player'] == @player && @id == @event['holder'] && !@is_gui_update[0]) {
            @smoker_data = _get_smoker_data(@smoker_location)
            @smoker_data['viewer'] = null
            @smoker_data['gui_id'] = null
            _set_smoker_data(@smoker_location, @smoker_data)
          }
        }
      }
      _show_gui(@player, @gui_id, 54, @texture_layer, '', @inventory, @closure, @smoker_location, @smoker_data, @cooking_recipes, @is_gui_update, @text)
    }
  } else {
    close_pinv(@player)
  }
}


bind('tuna_furnace_burn_event', null, null, @event) {
  if(@event['fuel'] == 'SMOKER') {
    @smoker_location = array('x': @event['x'], 'y': @event['y'], 'z': @event['z'], 'world': @event['world'])
    @smoker_data = _get_smoker_data(@smoker_location)

    if(!is_null(@smoker_data['selected_recipe'])) {
      @cooking_recipe = @cooking_recipes[@smoker_data['selected_recipe']]
      if(@cooking_recipe['category'] == 'need_fire') {
        @cooking_result_data = _get_cookable(@smoker_data['ingredients'], @cooking_recipe, false)
        if(@cooking_result_data['cookable']) { // 요리 가능할 시
          _start_cooking(@smoker_location, @cooking_recipe, false) // 시작 안되있을 경우 시작
        }
      }
    }

    set_timeout(0, closure() {
      @smoker_data = _get_smoker_data(@smoker_location)
      @id = @smoker_data['gui_id']
      @viewer = @smoker_data['viewer']
      if(!is_null(@id) && !is_null(@viewer)) {
        set_inventory_item(@id, 48, array( // gui 불 붙은 훈연기 이미지
          'name': 'STRUCTURE_VOID',
          'meta': array(
            'display': ' ',
            'model': 111
          )
        ))
        @fuel_item = get_inventory_item(@smoker_location, 1)
        if(is_array(@fuel_item)) {
          set_inventory_item(@id, 37, @fuel_item)
        } else {
          set_inventory_item(@id, 37, array(
            'name': 'STRUCTURE_VOID',
            'meta': array(
              'display': '§7연료',
              'lore': array(
                '§7불이 필요한 요리의 경우,',
                '§7연료가 필요합니다.'
              ),
              'model': 113
            )
          ))
        }
      }
    })

    set_timeout(@event['burnTime'] * 50, closure() {
      @fuel_item = get_inventory_item(@smoker_location, 1)
      if(!is_array(@fuel_item)) {
        @smoker_data = _get_smoker_data(@smoker_location)
        @id = @smoker_data['gui_id']
        @viewer = @smoker_data['viewer']
        if(!get_blockdata(@smoker_location)['lit']) {
          _stop_cooking(@smoker_location) // 요리 종료
          if(!is_null(@id) && !is_null(@viewer)) {
            set_inventory_item(@id, 48, array( // gui 불 꺼진 훈연기 이미지
              'name': 'STRUCTURE_VOID',
              'meta': array(
                'display': ' ',
                'model': 110
              )
            ))
          }
        }
      }
    })

  }
}

bind('tuna_furnace_smelt_event', null, null, @event) {
  @smoker_location = array('x': @event['x'], 'y': @event['y'], 'z': @event['z'], 'world': @event['world'])
  if(get_block(@smoker_location) == 'SMOKER') {
    cancel()
  }
}

bind('block_place', null, array('block': 'SMOKER'), @event) {
  if(!is_cancelled()) {
    set_inventory_item(@event['location'], 0, array(
      'name': 'STRUCTURE_VOID',
      'meta': array(
        'display': ' ',
        'model': 1
      )
    ))
  }
}

bind('block_break', null, array('block': 'SMOKER'), @event) {
  if(!is_cancelled()) {
    @smoker_location = @event['location']
    set_inventory_item(@smoker_location, 0, null) // 공허 구조 아이템 생성되지 않도록 제거
    @smoker_data = _get_smoker_data(@smoker_location)
    @smoker_location['x'] += 0.5
    @smoker_location['y'] += 0.5
    @smoker_location['z'] += 0.5
    foreach(@ingredient_item in @smoker_data['ingredients']) {
      if(is_array(@ingredient_item)) {
        drop_item(@smoker_location, @ingredient_item, false)
      }
    }
    foreach(@result_item in @smoker_data['results']) {
      if(is_array(@result_item)) {
        drop_item(@smoker_location, @result_item, false)
      }
    }
  }
}