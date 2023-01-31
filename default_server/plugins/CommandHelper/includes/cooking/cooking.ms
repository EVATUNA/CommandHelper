@cooking_tables = array()
@files = list_files('recipe_tables')
foreach(@file in @files) {
  @file_path = "recipe_tables/@file"
  @file_name_and_extension = _get_file_name_and_extension(@file)
  @file_name = @file_name_and_extension[0]
  @file_extension = @file_name_and_extension[1]
  if(@file_extension == 'json') {
    async_read_file(@file_path, closure(@content) {
      foreach(@food_name: @cooking_table in json_decode(@content)) {
        //@namespace = "@file_name:@food_name"
        @cooking_tables[@food_name] = @cooking_table
      }
    })
  }
}
export('cooking_tables', @cooking_tables)

proc _get_cooking_table_data(@smoker_location) {
  if(get_block(@smoker_location) == 'SMOKER') {
    @cooking_table_data_string = get_block_lock(@smoker_location)
    if(@cooking_table_data_string == '') {
      @cooking_table_data = array(
        'viewer': null, // 동시 사용 제한 용도
        'gui_id': null,
        'selected_recipe': null,
        'mode': 'default', // 함수로 옮기고 레시피 모드 여부 저장 안하기?
        'ingredients': array(0: null, 1: null, 2: null, 3: null, 4: null, 5: null, 6: null, 7: null, 8: null, 9: null),
        'results': array(0: null, 1: null, 2: null, 3: null, 4: null, 5: null, 6: null, 7: null, 8: null, 9: null)
      )
      _set_cooking_table_data(@smoker_location, @cooking_table_data)
    } else {
      @cooking_table_data = json_decode(@cooking_table_data_string)
    }
    return(@cooking_table_data)
  } else {
    return(null)
  }
}

proc _set_cooking_table_data(@smoker_location, @cooking_table_data) {
  if(get_block(@smoker_location) == 'SMOKER') {
    set_block_lock(@smoker_location, json_encode(@cooking_table_data))
    return(true)
  } else {
    return(false)
  }
}

proc _get_cooking_table_gui_id(@smoker_location) {
  @gui_id = 'cooking_table_'.@smoker_location['x'].'_'.@smoker_location['y'].'_'.@smoker_location['z'].'_'.@smoker_location['world']
  return(@gui_id)
}

proc _check_ingredients(@checking_item, @requre_item) {
  @checking_item_copy = array_deep_clone(@checking_item)
  @requre_item_copy = array_deep_clone(@requre_item)

  

}

proc _is_cookable(@search_inventory, @cooking_table) {
  @accumulated_quality = 0
  @max_quality = 0
  @return_array = array(
    'cookable': false,
    'max_quality': 0,
    'accumulated_quality': 0
  )
  @cooking_table_copy = array_deep_clone(@cooking_table)
  @search_inventory_copy = array_deep_clone(@search_inventory)
  foreach(@inventory_key: @inventory_item in @search_inventory_copy) {
    if(array_size(@cooking_table_copy['ingredients']) > 0) {
      if(is_array(@inventory_item)) {
        if(is_array(@inventory_item['meta'])) {
          if(is_null(@inventory_item['meta']['model'])) {@inventory_item['meta']['model'] = 0}
        } else {
          @inventory_item['meta'] = array('model': 0)
        }
        //broadcast(@search_inventory_copy)
        //broadcast(@cooking_table_copy['ingredients'])
        foreach(@requre_key: @requre_item in @cooking_table_copy['ingredients']) {
          if(!array_index_exists(@requre_item, 'meta', 'model')) {@requre_item['meta']['model'] = 0}

          if(@requre_item['name'] == @inventory_item['name']) {
            if(!array_index_exists(@requre_item, 'rank_contribution')) { // 랭크 반영 X

              if(@requre_item['meta']['model'] == @inventory_item['meta']['model']) {

                if(@inventory_item['qty'] >= @requre_item['qty']) { // 인벤 템 >= 요구 템
                  @inventory_item['qty'] -= @requre_item['qty']
                  @requre_item['qty'] = 0
                  array_remove(@cooking_table_copy['ingredients'], @requre_key)
                } else {                                            // 인벤 템 < 요구 템
                  @requre_item['qty'] -= @inventory_item['qty']
                  @inventory_item['qty'] = 0
                  array_remove(@search_inventory_copy, @inventory_key)
                }

              }

            } else { // 랭크 반영 O
              if(@requre_item['meta']['model'] == integer(@inventory_item['meta']['model'] / 5) * 5) {

                @quality = @inventory_item['meta']['model'] % 5 + 1 * @requre_item['rank_contribution']
                
                if(@inventory_item['qty'] >= @requre_item['qty']) { // 인벤 템 >= 요구 템
                  @accumulated_quality += @quality * @requre_item['qty']
                  @max_quality += 3 * @requre_item['rank_contribution'] * @requre_item['qty']
                  @inventory_item['qty'] -= @requre_item['qty']
                  @requre_item['qty'] = 0
                  array_remove(@cooking_table_copy['ingredients'], @requre_key)
                } else {                                            // 인벤 템 < 요구 템
                  @accumulated_quality += @quality * @inventory_item['qty']
                  @max_quality += 3 * @requre_item['rank_contribution'] * @inventory_item['qty']
                  @requre_item['qty'] -= @inventory_item['qty']
                  @inventory_item['qty'] = 0
                  array_remove(@search_inventory_copy, @inventory_key)
                }

              }
            }
          }
        }
      }
    } else {
      broadcast('COOKABLE' @accumulated_quality @max_quality)
      @return_array = array(
        'cookable': true,
        'max_quality': @max_quality,
        'accumulated_quality': @accumulated_quality
      )
      return(@return_array)
      break()
    }
  }
  //broadcast(@cooking_table)
  return(@return_array)
}

proc _get_showen_recipes(@player, @uuid, @recipe_book_data) {
  # 검색용 인벤 세팅
  @search_inventory = array()
  foreach(@index: @item in get_inventory(@uuid)) {
    if(@index < 36) { // 36~40: 갑옷, 왼손
      @search_inventory[] = @item
    }
  }
  # 검색 된 레시피 목록
  @shown_recipes = array()
  # 전체 레시피 포리치
  @cooking_tables = import('cooking_tables')
  foreach(@food_name: @cooking_table in @cooking_tables) {
    if(array_index_exists(@recipe_book_data, 'category')) {
      if(@recipe_book_data['category'] == 'need_fire' && @cooking_table['category'] != 'need_fire') {
        continue()
      } else if(@recipe_book_data['category'] == 'simple_cooking' && @cooking_table['category'] != 'simple_cooking') {
        continue()
      }
    }
    # 재료 준비 구분
    if(/*!@recipe_book_data['show_ready'] || */_is_cookable(@search_inventory, @cooking_table)) {
      @shown_recipes[] = @food_name
    }
  }
  return(@shown_recipes)
}

proc _get_paged_recipe_book_inventory(@inventory, @cooking_table_data, @page) {
  @recipe_book_data = @cooking_table_data['recipe_book']
  @shown_recipes = @recipe_book_data['shown_recipes']
  @max_page = _get_max_page(@cooking_table_data)
  if(@page < 0) {@page = 0}
  if(@page > @max_page) {@page = @max_page}
  @recipe_book_data['page'] = @page
  // 페이징
  @paged_shown_recipes = _paging(@shown_recipes, 20)[@page]
  foreach(@key: @paged_shown_recipe in @paged_shown_recipes) {
    @line = floor(@key / 5) + 1
    @index = @line * 9 + 4 + @key % 5
    broadcast(@index @paged_shown_recipe)
    @inventory[@index] = array() // 해당 레시피의 아이템
  }
}

proc _get_max_page(@cooking_table_data) {
  if(array_index_exists(@recipe_book_data, 'recipe_book', 'shown_recipes') && is_array(@cooking_table_data['recipe_book']['shown_recipes'])) {
    @shown_recipes = @cooking_table_data['recipe_book']['shown_recipes']
    if(array_size(@shown_recipes) > 0) {
      return(ceil(array_size(@shown_recipes) / 20) - 1)
    } else {
      return(0)
    }
  } else {
    return(0)
  }
}

// 레시피 북 업데이트
// 래시피 북 페이지

  //@cooking_tables = import('cooking_tables')





// 쿠킹 테이블 gui 열기
proc _open_cooking_table(@player, @uuid, @smoker_location, @text) {
  @cooking_table_data = _get_cooking_table_data(@smoker_location)
  if(@cooking_table_data) {
    @gui_id = _get_cooking_table_gui_id(@smoker_location)
    @old_viewer = @cooking_table_data['viewer']
    if(!is_null(@old_viewer) && @old_viewer != @player && ponline(@old_viewer) && string_starts_with(pinventory_holder(@old_viewer), "@old_viewer.@gui_id")) {
      // 타 플레이어가 gui 열고 있을시 열 수 없다는 알림
      @prefix = @text['prefix']['failure']
      _send_instance_tooltip_msg(@player, @uuid, @prefix '이미 다른 플레이어가 요리하고 있습니다.')
    } else {
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
      @interact_items = array(
        'default': array(
          'empty_slot': array(
            'recipe_unchosen': array(
              'name': 'STRUCTURE_VOID',
              'meta': array(
                'display': '§f레시피 선택',
                'lore': array(
                  '§7클릭시, 레시피 북을 펼쳐',
                  '§7요리하려는 음식을 선택할 수 있습니다.',
                  '',
                  '§7레시피를 선택해야 요리가 가능합니다.'
                ),
                'model': 112
              )
            ),
            'recipe_choosing': array(
              'name': 'STRUCTURE_VOID',
              'meta': array(
                'display': '§f레시피 선택',
                'lore': array(
                  '§7우측의 레시피 목록에서',
                  '§7요리하려는 음식을 선택하세요.',
                  '',
                  '§7레시피를 선택해야 요리가 가능합니다.'
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
          ),
          'button': array(
            'ignite_button_enable': array(
              'name': 'STRUCTURE_VOID',
              'meta': array(
                'display': '§7훈연기 점화',
                'model': 114
              )
            ),
            'ignite_button_disable': array(
              'name': 'STRUCTURE_VOID',
              'meta': array(
                'display': '§7훈연기 점화',
                'model': 1
              )
            ),
            'extinguish_button': array(
              'name': 'STRUCTURE_VOID',
              'meta': array(
                'display': '§7훈연기 소화',
                'model': 115
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
      // 타이틀
      @background_text_main = _color('#ffffff').@text['space_fonts']['space.-8'].'\ue9dd'.@text['space_fonts']['space.-169']._color('#404040').'요리 작업대'
      @background_text_default = _color('#ffffff').@text['space_fonts']['space.22'].'\ue9de'.@text['space_fonts']['space.-97']._color('#404040').'요리 재료/결과'
      @background_text_recipe = _color('#ffffff').@text['space_fonts']['space.22'].'\ue9df'.@text['space_fonts']['space.-97']._color('#404040').'요리 레시피 선택'
      
      // 레시피 업데이트
      // 불여부 고려 X
      
      // 100틱 인터벌 중 해당 훈연기 요리 완료 했을시 재료인벤에 따라
      
      // 인벤 클릭시
      // 아이템 습득시

      // 레시피 gui열었을 시
      // 카테고리 건들 시

      // 페이지 바꿀 시는 페이지만 바꿔서 
      
      ### 레시피북 데이터 플레이어한테 저장 안해도 됨


      # 연료 동기화
      @smoker_inventory = get_inventory(@smoker_location)
      if(is_null(@smoker_inventory[1])) { // 연료 없을시
        @inventory[28] = @interact_items['default']['empty_slot']['fuel']
        @inventory[37] = @interact_items['default']['button']['ignite_button_disable']
      } else { // 연료가 있을 시 연소 작동 여부에 따른 버튼 세팅
        @inventory[28] = @smoker_inventory[1]
        if(is_null(@smoker_inventory[0])) {
          @inventory[37] = @interact_items['default']['button']['ignite_button_enable']
        } else {
          @inventory[37] = @interact_items['default']['button']['extinguish_button']
        }
      }

      # 훈연기 연소 여부에 따른 gui 세팅
      if(get_blockdata(@smoker_location)['lit']) {
        @inventory[48]['meta']['model'] = 111
      } else {
        @inventory[48]['meta']['model'] = 110
      }


      // 레시피 데이터 프리셋
      @recipe_book_data = array(
        'category': 'everything',
        'show_ready': false,
        'page': 0,
        'shown_recipes': array()
      )

      // 레시피 모드에 따른 세팅
      if(@cooking_table_data['mode'] == 'recipe') {
        // 레시피 gui 타이틀
        @texture_layer = @background_text_main.@background_text_recipe

        // 레시피 선택 안되어 있을 시 빈 슬롯 표시
        if(is_null(@cooking_table_data['selected_recipe'])) {
          @inventory[10] = @interact_items['default']['empty_slot']['recipe_choosing']
        }

        # 카테고리
        @inventory[5] = @interact_items['recipe']['category']['everything']
        @inventory[6] = @interact_items['recipe']['category']['simple_cooking']
        @inventory[7] = @interact_items['recipe']['category']['need_fire']
        switch(@recipe_book_data['category']) {
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

        # 레시피 모두보기 요리가능만 보기 버튼
        if(@recipe_book_data['show_ready']) {
          @inventory[13] = @interact_items['recipe']['button']['show_ready']
        } else {
          @inventory[13] = @interact_items['recipe']['button']['show_all']
        }

        # 카테고리랑 버튼에 따라 레시피 목록 보여주기
        @shown_recipes = _get_showen_recipes(@player, @uuid, @recipe_book_data)
        @recipe_book_data['shown_recipes'] = @shown_recipes
        // shown_recipes 페이징 해서 보여주기

        // 페이지에 따라 화살표 버튼 배치

      } else if(@cooking_table_data['mode'] == 'default') {
        // 레시피 gui 타이틀
        @texture_layer = @background_text_main.@background_text_default
        
        // 레시피 선택 안되어 있을 시 빈 슬롯 표시
        if(is_null(@cooking_table_data['selected_recipe'])) {
          @inventory[10] = @interact_items['default']['empty_slot']['recipe_unchosen']
        }

        // 재료칸 세팅
        foreach(@ingredient_key: @ingredient_item in @cooking_table_data['ingredients']) {
          if(@ingredient_key < 5) { @ingredient_slot = @ingredient_key + 4 } else { @ingredient_slot = @ingredient_key + 8 }
          if(is_array(@ingredient_item)) {
            @inventory[@ingredient_slot] = @ingredient_item
          } else {
            @inventory[@ingredient_slot] = @interact_items['default']['empty_slot']['ingredient']
          }
        }
        
        // 결과칸 세팅
        foreach(@result_key: @result_item in @cooking_table_data['results']) {
          if(@result_key < 5) { @result_slot = @result_key + 40 } else { @result_slot = @result_key + 44 }
          if(is_array(@result_item)) {
            @inventory[@result_slot] = @result_item
          } else {
            @inventory[@result_slot] = @interact_items['default']['empty_slot']['result']
          }
        }
      }


      @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @interact_items, @smoker_location, @cooking_table_data, @recipe_book_data, @text) {

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

        bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @id, @texture_layer, @message, @interact_items, @smoker_location, @recipe_book_data, @fuel, @text) {
          @player_data = import('players_data')[@uuid]
          @cooking_table_data = _get_cooking_table_data(@smoker_location)
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
                  if(@cooking_table_data['mode'] == 'recipe') {
                    @cooking_table_data['mode'] = 'default'
                  } else if(@cooking_table_data['mode'] == 'default') {
                    @cooking_table_data['mode'] = 'recipe'
                  }
                  @play_sound = true
                  // 아래 두개 묶어서 gui 업데이트 함수? 같은걸로 만들기
                  _set_cooking_table_data(@smoker_location, @cooking_table_data)
                  _open_cooking_table(@player, @uuid, @smoker_location, @text)
                  //
                }
                break()
              case 28:
                @fuel_item_at_that_time = get_inventory_item(@smoker_location, 1)
                if(!is_null(@fuel_item_at_that_time)) {
                  modify_event('slotitem', @fuel_item_at_that_time)
                }

                if(is_null(@slot_item)) {
                  if(is_null(@fuel_item_at_that_time)) {
                    modify_event('slotitem', @interact_items['default']['empty_slot']['fuel'])
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
                    @fuel_item = get_inventory_item(@id, 28)
                    if(@fuel_being_empty) {
                      set_inventory_item(@id, 28, @interact_items['default']['empty_slot']['fuel'])
                      @fuel_item = null
                    }
                    if(@fuel_being_change) {
                      set_inventory_item(@smoker_location, 1, @fuel_item)
                    }
                  })
                }
                break()
              }
            } else { // 우측 gui
              if(@cooking_table_data['mode'] == 'recipe') { // 레시피 선택 모드
                //ceil(array_size())
                if(@event['clicktype'] == 'LEFT' && (@action == 'PICKUP_ALL' || @action == 'SWAP_WITH_CURSOR')) {
                  @recipebook_update = false
                  @inventory = get_inventory(@id)
                  switch(@rawslot) {
                  case 5: // 모든 카테고리
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      if(@recipe_book_data['category'] != 'everything') {
                        @recipe_book_data['category'] = 'everything'
                        @inventory[17]['meta']['model'] = 100
                        @play_sound = true
                        @recipebook_update = true
                        // 레시피 업데이트
                      }
                    }
                    break()
                  case 6: // 단순 조리 및 손질 카테고리
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      if(@recipe_book_data['category'] != 'simple_cooking') {
                        @recipe_book_data['category'] = 'simple_cooking'
                        @inventory[17]['meta']['model'] = 101
                        @play_sound = true
                        @recipebook_update = true
                        // 레시피 업데이트
                      }
                    }
                    break()
                  case 7: // 불 사용 카테고리
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      if(@recipe_book_data['category'] != 'need_fire') {
                        @recipe_book_data['category'] = 'need_fire'
                        @inventory[17]['meta']['model'] = 102
                        @play_sound = true
                        @recipebook_update = true
                        // 레시피 업데이트
                      }
                    }
                    break()

                  case 13: // 모두 보기 여부
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      if(@recipe_book_data['show_ready']) {
                       @recipe_book_data['show_ready'] = false
                        @inventory[13] = @interact_items['recipe']['button']['show_all']
                      } else {
                        @recipe_book_data['show_ready'] = true
                        @inventory[13] = @interact_items['recipe']['button']['show_ready']
                      }
                      @play_sound = true
                      @recipebook_update = true
                      // 레시피 업데이트
                    }
                    break()
                  case 14:
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      // 버튼 활성화 되있을 시
                      @play_sound = true
                      @recipebook_update = true
                      // 페이지 업데이트
                    }
                    break()
                  case 16:
                    if(@player_data['cache']['gui_click_time'] < time()) {
                      // 버튼 활성화 되있을 시
                      @play_sound = true
                      @recipebook_update = true
                      // 페이지 업데이트
                    }
                    break()
                  case 22..26:
                  case 31..35:
                  case 40..44:
                  case 49..53:
                    // 레시피 있을 시
                    broadcast('a')
                    break()
                  }
                  if(@recipebook_update) {
                    set_inventory(@id, @inventory)
                  }
                }
              } else if(@cooking_table_data['mode'] == 'default') { // 일반모드
                switch(@rawslot) {
                case 4..8:
                case 13..17:
                  @ingredient_being_empty = false
                  if(@rawslot < 9) { @ingredient_key = @rawslot - 4 } else { @ingredient_key = @rawslot - 8 }
                  @ingredient_item = @cooking_table_data['ingredients'][@ingredient_key]
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

                  @ingredient_being_change = !is_cancelled()
                  set_timeout(0, closure() {
                    @new_ingredient_item = get_inventory_item(@id, @rawslot)
                    if(@ingredient_being_empty) {
                      set_inventory_item(@id, @rawslot, @interact_items['default']['empty_slot']['ingredient'])
                      @new_ingredient_item = null
                    }
                    if(@ingredient_being_change) {
                      @cooking_table_data['ingredients'][@ingredient_key] = @new_ingredient_item
                      _set_cooking_table_data(@smoker_location, @cooking_table_data)
                    }
                  })
                  break()
                case 40..44:
                case 49..53:
                  @result_being_empty = false
                  if(@rawslot < 45) { @result_key = @rawslot - 40 } else { @result_key = @rawslot - 44 }
                  @result_item = @cooking_table_data['results'][@result_key]
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
                      set_inventory_item(@id, @rawslot, @interact_items['default']['empty_slot']['result'])
                      @new_result_item = null
                    }
                    if(@result_being_change) {
                      @cooking_table_data['results'][@result_key] = @new_result_item
                      _set_cooking_table_data(@smoker_location, @cooking_table_data)
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

              if(@cooking_table_data['mode'] == 'recipe') { // 레시피 모드
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
                    set_inventory_item(@id, 28, null) // 가상 gui 빈칸으로 만들어서 템 들어가게 하기
                  }
                }

              } else { // 요리 모드
                @max_qty = max_stack_size(@slot_item)
                @my_qty = @slot_item['qty']
                @empty_key = -1

                // 재료 처리
                foreach(@key: @ingredient_item in @cooking_table_data['ingredients']) {
                  if(is_array(@ingredient_item)) {
                    @ingredient_item_copy = array_deep_clone(@ingredient_item)
                    array_remove(@ingredient_item_copy, 'qty')

                    if(@ingredient_item_copy == @slot_item_copy) {                      
                      @remaining_qty = @max_qty - @ingredient_item['qty']
                      if(@remaining_qty < @my_qty) { // 재료칸 아이템 남은 갯수보다 넣을려는 갯수가 많을경우
                        @cooking_table_data['ingredients'][@key]['qty'] = @max_qty
                        @my_qty -= @remaining_qty
                      } else { // 재료칸 아이템 남은 갯수보다 넣을려는 갯수가 적거나 같을경우
                        @cooking_table_data['ingredients'][@key]['qty'] += @my_qty
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
                    set_inventory_item(@id, 28, null) // 가상 gui 빈칸으로 만들어서 템 들어가게 하기
                    @fuel_being_change = true
                    @my_qty = 0
                  }
                }

                if(@my_qty > 0) { // 오버될 경우
                  if(@empty_key >= 0) {
                    if(@empty_key < 5) { @empty_slot = @empty_key + 4 } else { @empty_slot = @empty_key + 8 }
                    set_inventory_item(@id, @empty_slot, null)
                    @cooking_table_data['ingredients'][@empty_key] = @slot_item
                    @cooking_table_data['ingredients'][@empty_key]['qty'] = @my_qty
                  }
                }
                _set_cooking_table_data(@smoker_location, @cooking_table_data)
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

              if(@cooking_table_data['mode'] == 'recipe') { // 레시피 모드
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
                      set_inventory_item(@id, @key, @interact_items['default']['empty_slot']['ingredient'])
                    } else if(@new_inventory[@key]['name'] == 'STRUCTURE_VOID') {
                      @new_ingredients[@index] = null
                    } else {
                      @new_ingredients[@index] = @new_inventory[@key]
                    }
                    if(!@is_ingredients_changed && @new_ingredients[@index] != @cooking_table_data['ingredients'][@index]) {
                      @is_ingredients_changed = true
                    }
                  }
                  if(@is_ingredients_changed) {
                    @cooking_table_data['ingredients'] = @new_ingredients
                    _set_cooking_table_data(@smoker_location, @cooking_table_data)
                  }
                  // 연료
                  if(is_null(@new_inventory[28])) {
                    @new_fuel_item = null
                    set_inventory_item(@id, 28, @interact_items['default']['empty_slot']['fuel'])
                  } else if(@new_inventory[28]['name'] == 'STRUCTURE_VOID') {
                    @new_fuel_item = null
                  } else {
                    @new_fuel_item = @new_inventory[28]
                  }
                  if(@fuel_item_at_that_time != @new_fuel_item) {
                    set_inventory_item(@smoker_location, 1, @new_fuel_item)
                  }
                })
              }
              break()
            }
            set_timeout(0, closure() {
              @fuel_item = get_inventory_item(@id, 28)
              if(@fuel_being_empty) {
                set_inventory_item(@id, 28, @interact_items['default']['empty_slot']['fuel'])
                @fuel_item = null
              }
              if(@fuel_being_change) {
                set_inventory_item(@smoker_location, 1, @fuel_item)
              }
            })
          }
        }

        bind('inventory_close', array('id': "close.@id"), array('virtual': true), @event, @player, @uuid) {
          if(@event['player'] == @player) {
        
          }
        }

      }

      _show_gui(@player, @gui_id, 54, @texture_layer, '', @inventory, @closure, @interact_items, @smoker_location, @cooking_table_data, @recipe_book_data, @text)
    }
  } else {
    close_pinv(@player)
  }
}

bind('tuna_furnace_burn_event', null, null, @event) {
  broadcast(@event 'A-')
}

bind('tuna_furnace_smelt_event', null, null, @event) {
  broadcast(@event 'C')
}

bind('tuna_furnace_start_smelt_event', null, null, @event) {
  broadcast(@event 'D-')
}
/*
broadcast(B)
proc _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text) {
  if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {

    # item return
    if(!@is_refresh) {
      for(@index = 4, @index < 9, @index++) {
        @return_item = @inventory[@index]
        if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
          @return_item['qty'] = pgive_item(@player, @return_item)
          @ploc = ploc(@player)
          @ploc['y'] += 1
          drop_item(@ploc, @return_item, false)
        }
        @inventory[@index] = array(
          'name': 'STRUCTURE_VOID',
          'meta': array(
            'display': ' ',
            'model': 1
          )
        )
      }
      for(@index = 13, @index < 18, @index++) {
        @return_item = @inventory[@index]
        if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
          @return_item['qty'] = pgive_item(@player, @return_item)
          @ploc = ploc(@player)
          @ploc['y'] += 1
          drop_item(@ploc, @return_item, false)
        }
        @inventory[@index] = array(
          'name': 'STRUCTURE_VOID',
          'meta': array(
            'display': ' ',
            'model': 1
          )
        )
      }
      # result item reset
      @inventory[32] =array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': ' ',
          'model': 1
        )
      )
      @inventory[34] = array(
        'name': 'STRUCTURE_VOID',
        'meta': array(
          'display': ' ',
          'model': 1
        )
      )
    }
    # setting
    @ingredient_name = null
    @backgroundtext = @text['space_fonts']['space.-8'].'\uec2e'.@text['space_fonts']['space.-169']
    @open_slot = @text['space_fonts']['space.18']
    @close_slot_1 = @text['space_fonts']['space.-1'].'\ue540'
    @close_slot_2 = @text['space_fonts']['space.-1'].'\ue5a0'
    @line_1_qty = 0
    @line_2_qty = 0
    if(is_null(@inventory[1])) { // 빈칸일시
      @inventory[1] = @repairing_item_slot
    } else if(array_index_exists(@repairable_items, @inventory[1]['name']) && @inventory[1]['meta']['damage'] > 0) { // 아이템이 놓였을 시
      # 아이템에 따른 필요 재료 설정
      @ingredient_slot['meta']['model'] = @repairable_items[@inventory[1]['name']]['model']
      @ingredient_name = @repairable_items[@inventory[1]['name']]['ingredient']
      @line_1_qty = 5
      @line_2_qty = 5
      # 재료칸 세팅
      if(!@is_refresh) {
        for(@index = 4, @index < 9, @index++) {
          @inventory[@index] = @ingredient_slot
        }
        for(@index = 13, @index < 18, @index++) {
          @inventory[@index] = @ingredient_slot
        }
      }

    }
    @line_1 = string_multiply(@open_slot, @line_1_qty).string_multiply(@close_slot_1, 5 - @line_1_qty)
    @line_2 = string_multiply(@open_slot, @line_2_qty).string_multiply(@close_slot_2, 5 - @line_2_qty)
    @title_text = _color('#404040').'수리할 아이템'.@text['space_fonts']['space.22']._color('#404040').'수리 재료'.color('white')
    if(!is_null(@rounded_failure_probability)) {
      if(@is_refresh) {
        @percent_text = @text['space_fonts']['space.-16'].''._replace_repair_percent(@rounded_failure_probability).''.@text['space_fonts']['space.20'].''._replace_repair_percent(@rounded_success_probability)
      } else {
        @percent_text = ''
      }
    } else {
      @percent_text = ''
    }
    @inventory[18]['meta']['model'] = 7
    if(@inventory[37]['meta']['model'] == 1) {
      @inventory[37] = @unactvated_repair_button
    }
    if(@inventory[44]['meta']['model'] == 1) {
      @inventory[44] = @unactvated_refresh_button
    }
    @texture_layer = @backgroundtext.@text['space_fonts']['space.72'].@line_1.@text['space_fonts']['space.-90'].@line_2.@text['space_fonts']['space.-162'].@title_text.@percent_text
    @closure = closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id, @ingredient_name, @repairable_items, @repairing_item_slot, @ingredient_slot, @actvated_repair_button, @unactvated_repair_button, @actvated_refresh_button, @unactvated_refresh_button, @rounded_failure_probability, @rounded_success_probability, @block_location, @text) {
      bind('inventory_click', array('id': "click.@id"), array('player': @player, 'virtual': true), @event, @player, @uuid, @id, @texture_layer, @ingredient_name, @repairable_items, @repairing_item_slot, @ingredient_slot, @actvated_repair_button, @unactvated_repair_button, @actvated_refresh_button, @unactvated_refresh_button, @rounded_failure_probability, @rounded_success_probability, @block_location, @text) {
        @player_data = import('players_data')[@uuid]
        if(@player_data['cache']['gui_click_time'] < time()) {
          @rawslot = @event['rawslot']
          @action = @event['action']
          @cursor_item = @event['cursoritem']
          if(@rawslot >= 0 && @rawslot <= 44) {
            @slot_item = @event['inventory'][@rawslot]
            @return_items = array()
            switch(@rawslot) {
            case 1: // repairing item
              switch(@action) {
              case 'SWAP_WITH_CURSOR':
                if(!is_null(@cursor_item) && array_index_exists(@repairable_items, @cursor_item['name'])) { // 도구를 들고 있을시
                  if(array_index_exists(@repairable_items, @slot_item['name'])) { // 슬롯에 도구가 있었을시
                    @change_gui = true
                    @return_items[] = array_deep_clone(@slot_item)
                    modify_event('slotitem', null)
                  } else { // 슬롯이 빈칸일 시
                    @change_gui = true
                    modify_event('slotitem', null)
                  }
                } else { // 도구를 들고 있지 않을 시
                  @change_gui = false
                  cancel()
                }
                break()
              case 'PICKUP_ALL':
              case 'PICKUP_HALF':
                if(array_index_exists(@repairable_items, @slot_item['name'])) { // 도구를 꺼냈을 시
                  @change_gui = true
                  @return_items[] = array_deep_clone(@slot_item)
                  modify_event('slotitem', null)
                } else { // 빈칸 클릭시
                  @change_gui = false
                  cancel()
                }
                break()
              case 'DROP_ONE_SLOT':
              case 'DROP_ALL_SLOT':
                if(is_null(@cursor_item)) {
                  if(array_index_exists(@repairable_items, @slot_item['name'])) {
                    @change_gui = true
                  } else {
                    @change_gui = false
                    cancel()
                  }
                } else {
                  @change_gui = false
                }
                break()
              case 'HOTBAR_SWAP':
              case 'HOTBAR_MOVE_AND_READD':
                if(is_null(@cursor_item)) {
                  @swapslot = @event['hotbarbutton']
                  if(@event['hotbarbutton'] == -1 ) { @swapslot = 40 }
                  @swap_item = get_inventory_item(@uuid, @swapslot)
                  if(array_index_exists(@repairable_items, @slot_item['name'])) {
                    if(!is_null(@swap_item)) {
                      if(array_index_exists(@repairable_items, @swap_item['name'])) {
                        @change_gui = true  // gui 도구 | 스왑 도구
                      } else {
                        @change_gui = false // gui 도구 | 스왑 기타
                        cancel()
                      }
                    } else {
                      @change_gui = true    // gui 도구 | 스왑 빈칸
                      cancel()
                      set_inventory_item(@id, @rawslot, @repairing_item_slot)
                      set_inventory_item(@uuid, @swapslot, @slot_item)
                    }
                  } else {
                    if(!is_null(@swap_item)) {
                      if(array_index_exists(@repairable_items, @swap_item['name'])) {
                        @change_gui = true  // gui 빈칸 | 스왑 도구
                        modify_event('slotitem', null)
                      } else {
                        @change_gui = false // gui 빈칸 | 스왑 기타
                        cancel()
                      }
                    } else {
                      @change_gui = false   // gui 빈칸 | 스왑 빈칸
                      cancel()
                    }
                  }
                } else {
                  @change_gui = false
                }
                break()
              case 'MOVE_TO_OTHER_INVENTORY':
                if(array_index_exists(@repairable_items, @slot_item['name'])) {
                  if(is_null(@cursor_item)) {
                    @change_gui = true
                  } else {
                    @change_gui = true
                    @return_items[] = @cursor_item
                    modify_event('cursoritem', null)
                  }
                } else {
                  @change_gui = false
                  cancel()
                }
                break();
              default:
                @change_gui = false
                cancel()
                break() 
              }
              if(@change_gui) {
                foreach(@return_item in @return_items) {
                  if(!is_null(@return_item)) {
                    @return_item['qty'] = pgive_item(@player, @return_item)
                    @ploc = ploc(@player)
                    @ploc['y'] += 1
                    drop_item(@ploc, @return_item, false)
                  }
                }
                if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                  unbind("close.@id")
                }
                set_timeout(1, closure() {
                  @inventory = get_inventory(@id)
                  @is_refresh = false
                  _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text)
                })
              }
              break()
            case 4..8:
            case 13..17: // ingredient
              if(!is_null(@slot_item) && !(@slot_item['name'] == 'STRUCTURE_VOID' && @slot_item['meta']['model'] == 1)) { // 재료를 놓을 수 있는 칸일 시
                //_debugmsg(@player @action @slot_item @cursor_item) // 디버깅용
                switch(@action) {
                case 'SWAP_WITH_CURSOR':
                  @cursor_item_copy = array_deep_clone(@cursor_item)
                  if(!is_null(@cursor_item) && @cursor_item['name'] == @ingredient_name) { // 재료를 들고 있을시
                    if(@slot_item['name'] == @ingredient_name) { // 슬롯에 재료가 있었을시
                      if(@cursor_item['qty'] == 1) { // 아이템 하나만 들고 있을시 (커서랑 슬롯이랑 스왑시키는 용도)
                        @change_ingredient = true
                        @player_data['cache']['gui_click_time'] = time() + 100
                      } else {
                        @change_ingredient = false
                        cancel()
                      }
                    } else { // 슬롯이 빈칸일 시
                      if(!is_cancelled()) {
                        @change_ingredient = true
                        @player_data['cache']['gui_click_time'] = time() + 100
                        @cursor_item['qty'] = 1
                        @cursor_item_copy['qty'] = 63
                        modify_event('slotitem', @cursor_item_copy)
                        set_timeout(1, closure() {
                          set_inventory_item(@id, @rawslot, @cursor_item)
                        })
                      }
                    }
                  } else { // 재료를 들고 있지 않을 시
                    @change_ingredient = false
                    cancel()
                  }
                  break()
                case 'PICKUP_ALL':
                case 'PICKUP_HALF':
                  if(@slot_item['name'] == @ingredient_name && @slot_item['qty'] == 1) {
                    @change_ingredient = true
                    @player_data['cache']['gui_click_time'] = time() + 100
                    set_timeout(1, closure() {
                      set_inventory_item(@id, @rawslot, @ingredient_slot)
                    })
                  } else {
                    @change_ingredient = false
                    cancel()
                  }
                  break()
                case 'DROP_ONE_SLOT':
                case 'DROP_ALL_SLOT':
                  if(is_null(@cursor_item)) {
                    if(@slot_item['name'] == @ingredient_name) {
                      @change_ingredient = true
                      @player_data['cache']['gui_click_time'] = time() + 100
                      set_timeout(1, closure() {
                        set_inventory_item(@id, @rawslot, @ingredient_slot)
                      })
                    } else {
                      @change_ingredient = false
                      cancel()
                    }
                  } else {
                    @change_ingredient = false
                  }
                  break()
                case 'HOTBAR_SWAP':
                case 'HOTBAR_MOVE_AND_READD':
                  if(is_null(@cursor_item)) {
                    @swapslot = @event['hotbarbutton']
                    if(@event['hotbarbutton'] == -1 ) { @swapslot = 40 }
                    @swap_item = get_inventory_item(@uuid, @swapslot)
                    if(@slot_item['name'] == @ingredient_name) {
                      if(!is_null(@swap_item)) {
                        if(@swap_item['name'] == @ingredient_name) {
                          if(@swap_item['qty'] == 1) {
                            @change_ingredient = true   // gui 재료 | 스왑 재료 1개
                            @player_data['cache']['gui_click_time'] = time() + 100
                          } else {
                            @change_ingredient = false  // gui 재료 | 스왑 재료 n개
                            cancel()
                          }
                        } else {
                          @change_ingredient = false    // gui 재료 | 스왑 기타
                          cancel()
                        }
                      } else {
                        @change_ingredient = true       // gui 재료 | 스왑 빈칸
                        @player_data['cache']['gui_click_time'] = time() + 100
                        cancel()
                        set_inventory_item(@id, @rawslot, @ingredient_slot)
                        set_inventory_item(@uuid, @swapslot, @slot_item)
                      }
                    } else {
                      if(!is_null(@swap_item)) {
                        if(@swap_item['name'] == @ingredient_name) {
                          if(@swap_item['qty'] == 1) {
                            @change_ingredient = true   // gui 빈칸 | 스왑 재료 1개
                            @player_data['cache']['gui_click_time'] = time() + 100
                            cancel()
                            set_inventory_item(@id, @rawslot, @swap_item)
                            set_inventory_item(@uuid, @swapslot, null)
                          } else {
                            @change_ingredient = true  // gui 빈칸 | 스왑 재료 n개
                            @player_data['cache']['gui_click_time'] = time() + 100
                            cancel()
                            @swap_item['qty'] -= 1
                            @swap_item_copy = array_deep_clone(@swap_item)
                            @swap_item_copy['qty'] = 1
                            set_inventory_item(@id, @rawslot, @swap_item_copy)
                            set_inventory_item(@uuid, @swapslot, @swap_item)
                          }
                        } else {
                          @change_ingredient = false    // gui 빈칸 | 스왑 기타
                          cancel()
                        }
                      } else {
                        @change_ingredient = false      // gui 빈칸 | 스왑 빈칸
                        cancel()
                      }
                    }
                  } else {
                    @change_ingredient = false
                  }
                  break()
                case 'MOVE_TO_OTHER_INVENTORY':
                  if(@slot_item['name'] == @ingredient_name) {
                    @change_ingredient = true
                    @player_data['cache']['gui_click_time'] = time() + 100
                    set_timeout(1, closure() {
                      set_inventory_item(@id, @rawslot, @ingredient_slot)
                    })
                  } else {
                    @change_ingredient = false
                    cancel()
                  }
                  break();
                default:
                  @change_ingredient = false
                  cancel()
                  break() 
                }
                if(@change_ingredient) {
                  set_timeout(1, closure() {
                    @inventory = get_inventory(@id)
                    @is_repairable = false
                    for(@index = 4, @index < 9, @index++) {
                      if(is_null(@inventory[@index])) {
                        set_inventory_item(@id, @index, @ingredient_slot)
                      } else if(@inventory[@index]['name'] == @ingredient_name) {
                        @is_repairable = true
                      }
                    }
                    for(@index = 13, @index < 18, @index++) {
                      if(is_null(@inventory[@index])) {
                        set_inventory_item(@id, @index, @ingredient_slot)
                      } else if(@inventory[@index]['name'] == @ingredient_name) {
                        @is_repairable = true
                      }
                    }
                    if(@is_repairable) {
                      set_inventory_item(@id, 37, @actvated_repair_button)
                    } else {
                      set_inventory_item(@id, 37, @unactvated_repair_button)
                    }
                    set_inventory_item(@id, 44, @actvated_refresh_button)
                  })
                }
              } else {
                cancel()
              }
              break()
            case 37: // repair button
              cancel()
              if(@action == 'PICKUP_ALL' && @slot_item['meta']['model'] == 14) {
                play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                @inventory = get_inventory(@id)
                @repairing_item = @inventory[1]
                # copy
                @repairing_item_copy = array_deep_clone(@repairing_item)
                @ingredients = array()
                for(@index = 4, @index < 9, @index++) {
                  @ingredient = @inventory[@index]
                  if(@ingredient['name'] == @ingredient_name) {
                    @ingredients[] = @ingredient
                  }
                }
                for(@index = 13, @index < 18, @index++) {
                  @ingredient = @inventory[@index]
                  if(@ingredient['name'] == @ingredient_name) {
                    @ingredients[] = @ingredient
                  }
                }
                # result
                @return = _get_repair_result(@inventory, @ingredient_name)
                if(rand() > @return['failure_probability'] * 0.01) {
                  @is_success = true
                } else {
                  @is_success = false
                }
                if(@is_success) { // 성공
                  @repairing_item['meta']['damage'] -= @return['repairing_durability']
                  if(@repairing_item['meta']['damage'] < 0) { @repairing_item['meta']['damage'] = 0 }
                  @result = @repairing_item
                } else { // 실패
                  @repairing_item['meta']['damage'] += @return['breaking_durability']
                  if(@repairing_item['meta']['damage'] >= material_info(@repairing_item['name'], 'maxDurability')) { 
                    @result = null
                  } else {
                    @result = @repairing_item
                  }
                }
                if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                  unbind("close.@id")
                  set_timeout(1000, closure() {
                    for(@i = 5, @i > 0, @i --) {
                      if(@i > 1) {
                        queue_push(closure() {
                          @particle_location = array('x': @block_location['x'] + 0.5, 'y': @block_location['y'] + 1, 'z': @block_location['z'] + 0.5, 'world': @block_location['world'])
                          if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                            play_named_sound(@particle_location, array('sound': 'block.anvil.land', 'category': 'BLOCKS', 'volume': 0.5, 'pitch': 1.7))
                            mom_playerparticle(@uuid, 'LAVA', @particle_location['x'], @particle_location['y'], @particle_location['z'], 5, 0.0, 0.0, 0.0, 0.0)
                          } else {
                            queue_clear('anvil.'.@player)
                            @return_item = @repairing_item_copy
                            if(!is_null(@return_item)) {
                              drop_item(@particle_location, @return_item, false)
                            }
                            foreach(@return_item in @ingredients) {
                              drop_item(@particle_location, @return_item, false)
                            }
                          }
                        }, 'anvil.'.@player)
                        queue_delay(1000, 'anvil.'.@player)
                      } else {
                        queue_push(closure() {
                          @particle_location = array('x': @block_location['x'] + 0.5, 'y': @block_location['y'] + 1, 'z': @block_location['z'] + 0.5, 'world': @block_location['world'])
                          if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                            play_named_sound(@particle_location, array('sound': 'block.anvil.land', 'category': 'BLOCKS', 'volume': 0.5, 'pitch': 1.7))
                            mom_playerparticle(@uuid, 'LAVA', @particle_location['x'], @particle_location['y'], @particle_location['z'], 5, 0.0, 0.0, 0.0, 0.0)
                            if(@is_success) {
                              play_named_sound(@particle_location, array('sound': 'entity.experience_orb.pickup', 'category': 'BLOCKS', 'volume': 0.5, 'pitch': 1))
                              mom_playerparticle(@uuid, 'FIREWORKS_SPARK', @particle_location['x'], @particle_location['y'], @particle_location['z'], 5, 0.1, 0.1, 0.1, 0.1)
                              title(@player, '성공!', '', 0, 15, 10)
                            } else {
                              play_named_sound(@particle_location, array('sound': 'entity.item.break', 'category': 'BLOCKS', 'volume': 0.5, 'pitch': 1))
                              mom_playerparticle(@uuid, 'CLOUD', @particle_location['x'], @particle_location['y'], @particle_location['z'], 5, 0.1, 0.1, 0.1, 0.1)
                              title(@player, '실패...', '', 0, 15, 10)
                            }
                            @return_item = @result
                            if(!is_null(@return_item)) {
                              drop_item(@particle_location, @return_item, false)
                            }
                          } else {
                            queue_clear('anvil.'.@player)
                            @return_item = @repairing_item_copy
                            if(!is_null(@return_item)) {
                              drop_item(@particle_location, @return_item, false)
                            }
                            foreach(@return_item in @ingredients) {
                              drop_item(@particle_location, @return_item, false)
                            }
                          }
                        }, 'anvil.'.@player)
                      }
                    }
                  })
                }
              }
              close_pinv(@player)
              break()
            case 44: // refresh
              cancel()
              if(@action == 'PICKUP_ALL' && @slot_item['meta']['model'] == 8) {
                play_named_sound(ploc(@player), array('sound': 'minecraft:ui.button.click', 'category': 'MASTER', 'volume': 0.25), array(@player))
                @inventory = get_inventory(@id)
                @return = _get_repair_result(@inventory, @ingredient_name)
                if(!is_null(@return['failure_probability'])) {
                  @rounded_failure_probability = integer(round(@return['failure_probability']))
                  @rounded_success_probability = integer(100 - @rounded_failure_probability)
                  @inventory[32] = @return['failure_item']
                  @inventory[34] = @return['success_item']
                } else {
                  @rounded_failure_probability = null
                  @rounded_success_probability = null
                  @inventory[32] =array(
                    'name': 'STRUCTURE_VOID',
                    'meta': array(
                      'display': ' ',
                      'model': 1
                    )
                  )
                  @inventory[34] = array(
                    'name': 'STRUCTURE_VOID',
                    'meta': array(
                      'display': ' ',
                      'model': 1
                    )
                  )
                }
                @inventory[44] = @unactvated_refresh_button
                if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                  unbind("close.@id")
                }
                set_timeout(1, closure() {
                  @is_refresh = true
                  _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text)
                })
              }
              break()
            default:
              cancel()
              break()
            }
          } else if(45 <= @rawslot && @rawslot <= 80) {
            @slot = @event['slot']
            @inventory = get_inventory(@id)
            @pinventory = pinv(@player)
            @old_slot_item = @pinventory[@slot]
            switch(@action) {
            case 'MOVE_TO_OTHER_INVENTORY':
              if(array_index_exists(@repairable_items, @old_slot_item['name'])) {
                if(@inventory[1]['name'] == 'STRUCTURE_VOID') {
                  @inventory[1] = @old_slot_item
                  set_pinv(@player, @slot, null)
                  if(array_contains(array('ANVIL', 'CHIPPED_ANVIL', 'DAMAGED_ANVIL'), get_block(@block_location))) {
                    unbind("close.@id")
                  }
                  set_timeout(1, closure() {
                    @is_refresh = false
                    _open_anvil(@player, @uuid, @inventory, @rounded_failure_probability, @rounded_success_probability, @is_refresh, @block_location, @text)
                  })
                } else {
                  cancel()
                }
              } else {
                cancel()
              }
              break()
            case 'COLLECT_TO_CURSOR':
              if(@cursor_item['name'] == @ingredient_name) {
                set_timeout(1, closure() {
                  @inventory = get_inventory(@id)
                  @is_repairable = false
                  for(@index = 4, @index < 9, @index++) {
                    if(is_null(@inventory[@index])) {
                      set_inventory_item(@id, @index, @ingredient_slot)
                    } else if(@inventory[@index]['name'] == @ingredient_name) {
                      @is_repairable = true
                    }
                  }
                  for(@index = 13, @index < 18, @index++) {
                    if(is_null(@inventory[@index])) {
                      set_inventory_item(@id, @index, @ingredient_slot)
                    } else if(@inventory[@index]['name'] == @ingredient_name) {
                      @is_repairable = true
                    }
                  }
                  if(@is_repairable) {
                    set_inventory_item(@id, 37, @actvated_repair_button)
                  } else {
                    set_inventory_item(@id, 37, @unactvated_repair_button)
                  }
                  set_inventory_item(@id, 44, @actvated_refresh_button)
                })
              }
              break()
            }
          }
        } else {
          cancel()
        }
      }
      #아이템 안뽑고 그냥 닫을시
      set_timeout(1, closure() {
        bind('inventory_drag', array('id': "drag.@id"), array('virtual': true), @event, @player, @uuid) {
          if(@event['player'] == @player) {
            @indexs = array_keys(@event['newitems'])
            foreach(@index in @indexs) {
              if(@index < 45) {
                cancel()
              }
            }
          }
        }
        bind('inventory_close', array('id': "close.@id"), array('virtual': true), @event, @player, @uuid) {
          if(@event['player'] == @player) {
            @inventory = @event['inventory']
            @return_item = @inventory[1]
            if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
              @return_item['qty'] = pgive_item(@player, @return_item)
              @ploc = ploc(@player)
              @ploc['y'] += 1
              drop_item(@ploc, @return_item, false)
            }
            for(@index = 4, @index < 9, @index++) {
              @return_item = @inventory[@index]
              if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
                @return_item['qty'] = pgive_item(@player, @return_item)
                @ploc = ploc(@player)
                @ploc['y'] += 1
                drop_item(@ploc, @return_item, false)
              }
            }
            for(@index = 13, @index < 18, @index++) {
              @return_item = @inventory[@index]
              if(!is_null(@return_item) && @return_item['name'] != 'STRUCTURE_VOID') {
                @return_item['qty'] = pgive_item(@player, @return_item)
                @ploc = ploc(@player)
                @ploc['y'] += 1
                drop_item(@ploc, @return_item, false)
              }
            }
          }
        }
      })
    }
    _show_gui(@player, 'anvil', 45, @texture_layer, '', @inventory, @closure, @ingredient_name, @repairable_items, @repairing_item_slot, @ingredient_slot, @actvated_repair_button, @unactvated_repair_button, @actvated_refresh_button, @unactvated_refresh_button, @rounded_failure_probability, @rounded_success_probability, @block_location, @text)
  } else {
    close_pinv(@player)
  }
}

*/