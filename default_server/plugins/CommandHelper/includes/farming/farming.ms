# 농사 보상 저장
@files = list_files('rewards')
foreach(@file in @files) {
  @file_path = "rewards/@file"
  @file_name_and_extension = _get_file_name_and_extension(@file)
  @file_name = @file_name_and_extension[0]
  @file_extension = @file_name_and_extension[1]
  if(@file_extension == 'json') {
    async_read_file(@file_path, closure(@content) {
      foreach(@crop_name: @crop_reward in json_decode(@content)) {
        #@namespace = "@file_name:@crop_name"
        #@crop_rewards[@namespace] = @crop_reward
        @crop_rewards[@crop_name] = @crop_reward
      }
    })
  }
}

proc _crop_mine_event(@event, @player, @uuid, @players_data, @crop_rewards, @skills_spec, @text, @harvesting_log_path) {
  @player_data = @players_data[@uuid]
  @skill_manager = @player_data['skill_manager']
  # 부순 블럭 선언
  @crop = @event['block']
  # 부순 블럭이 작물일 시
  if(array_contains(array_keys(@crop_rewards), @crop)) {
    # 작물 스펙 선언
    @crop_reward = @crop_rewards[@crop]
    ## 스킬 불러오기
    # 수확 숙련 배수
    @farming_mastery_multiply = 1
    if(array_index_exists(@crop_reward, 'mastery')) {
      @farming_mastery_name = @crop_reward['mastery']
      @farming_mastery_point = @player_data['skill_data'][@farming_mastery_name][0]
      @farming_mastery_multiply = @skills_spec[@farming_mastery_name]['effect_by_point'][@farming_mastery_point]['multiply']
    }
    # 풍년 배수
    @plenty_point = @player_data['skill_data']['plenty'][0]
    @plenty_multiply = @skills_spec['plenty']['effect_by_point'][@plenty_point]['multiply']
    # 최대 드랍 갯수 배수에 선광 스킬 배수, 인첸트 반영
    @max_drop_multiply = @plenty_multiply
    if(@player_data['item']['enchantments']['main_hand'] == '행운') {
      @max_drop_multiply += 1.5
    }
    # 수박 호박 수확할 시
    if(array_contains(array('PUMPKIN', 'MELON'), @crop)) {
      @center_location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
      @near_locations = array(
        'east': array(
          'facing': 'west',
          'location': array('x': @center_location['x'] + 1, 'y': @center_location['y'], 'z': @center_location['z'], 'world': @center_location['world'])
        ),
        'west': array(
          'facing': 'east',
          'location': array('x': @center_location['x'] - 1, 'y': @center_location['y'], 'z': @center_location['z'], 'world': @center_location['world'])
        ),
        'south': array(
          'facing': 'north',
          'location': array('x': @center_location['x'], 'y': @center_location['y'], 'z': @center_location['z'] + 1, 'world': @center_location['world'])
        ),
        'north': array(
          'facing': 'south',
          'location': array('x': @center_location['x'], 'y': @center_location['y'], 'z': @center_location['z'] - 1, 'world': @center_location['world'])
        )
      )
      # 줄기가 연결되어 있는지
      @is_placed = true
      foreach(@near_location in @near_locations) {
        if(get_block(@near_location['location']) == @crop_reward['stem'] && get_blockdata(@near_location['location'])['facing'] == @near_location['facing']) {
          @is_placed = false
          break()
        }
      }
      if(!@is_placed) {
        set_timeout(1, closure() {
          if(!is_cancelled()) { // 성공적으로 수확 시
            # 줄기 부수기
            break_block(@near_location['location'])
            # 루트 테이블 시스템
            @entries = @crop_reward['loot_table']
            @total_weight = 0
            foreach(@key: @entry in @entries) {
              @entries[@key]['weight'] += @entry['quality'] * @farming_mastery_multiply
              @total_weight += @entry['weight']
            }
            # 드랍 갯수 설정
            @qty = integer(round(@crop_reward['default_qty'] * @max_drop_multiply * rand()))
            if(@qty < @crop_reward['default_qty']) { @qty = @crop_reward['default_qty']}
            # 드랍 갯수 만큼 아이템 떨구기
            for(@i = 0, @i < @qty, @i++) {
              @result_weight = @total_weight * round(rand(), 5)
              @min_weight = 0
              foreach(@entry in @entries) {
                @max_weight = @min_weight + @entry['weight']
                if(@max_weight > @result_weight) {
                  drop_item(@center_location, @entry['item'], false)
                  _harvesting_logging(@harvesting_log_path, @player, @uuid, @entry['item'], @center_location)
                  break()
                } else {
                  @min_weight = @max_weight
                }
              }
            }
            # 경험치 드랍
            if(@player_data['item']['enchantments']['main_hand'] == '경험') {
              _drop_arcanelevel_random_experience(@center_location, @crop_reward['arcanelevel']['default'], @crop_reward['arcanelevel']['extra'])
              _drop_arcanelevel_random_experience(@center_location, @crop_reward['arcanelevel']['default'], @crop_reward['arcanelevel']['extra'])
            } else {
              _drop_arcanelevel_random_experience(@center_location, @crop_reward['arcanelevel']['default'], @crop_reward['arcanelevel']['extra'])
            }
            # 튜나레벨
            _give_tunalevel_random_experience(@uuid, @player_data, @crop_reward['tunalevel']['default'], @crop_reward['tunalevel']['extra'], @text)
          }
        })
        # 아이템, 경험치 수동으로 떨구기 때문에 모디피 이벤트로 이벤트 결과 수정
        modify_event('drops', array())
        modify_event('xp', 0)
      }
    } else { //호박 수박 이외의 작물 수확 시
      @locations = array()
      @center_location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
      @harvesting_method = json_decode(@skill_manager[4])['harvesting_method']
      @age = get_blockdata(@center_location)['age']
      set_timeout(1, closure() {
        if(!is_cancelled()) { // 성공적으로 수확 시
          # 괭이 검사
          @item = @player_data['item']['main_hand']
          @slot = pheld_slot(@player)
          if(!is_null(@item) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @item['name'])) {
            # 괭이 수확 내구도 시스템
            @max_durability = material_info(@item['name'], 'maxDurability')
            if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'damage')) {
              @damage = 0
              @item['meta'] = array()
            } else {
              @damage = @item['meta']['damage']
            }
            if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'enchants') || !array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
              @unbreaking_level = 0
            } else {
              @unbreaking_level = @item['meta']['enchants']['unbreaking']['elevel']
            }
            @breaking_chance = 1 / (@unbreaking_level + 1)
            # 수확 방식 적용
            if(@harvesting_method != '' && @player_data['active_skill'][@harvesting_method][1] > 0) {
              switch(@harvesting_method) {
              case 'wide_hands':
                if(@age == @crop_reward['max_age']) {
                  if(rand() < @breaking_chance) {
                    @damage += 1
                  }
                  @locations[] = @center_location
                  for(@x = -1, @x < 2, @x++) {
                    for(@z = -1, @z < 2, @z++) {
                      if(@x != 0 || @z != 0) {
                        @surrounding_location = array('x': @center_location['x'] + @x, 'y': @center_location['y'], 'z': @center_location['z'] + @z, 'world': @center_location['world'])
                        if(get_block(@surrounding_location) == @crop && get_blockdata(@surrounding_location)['age'] == @crop_reward['max_age']) {
                          if(@max_durability > @damage) {
                            if(rand() < @breaking_chance) {
                              @damage += 1
                            }
                            #주변 블럭들 부술 블럭 목록에 넣기 및 부수기
                            @locations[] = @surrounding_location
                            break_block(@surrounding_location)
                          }
                        }
                      }
                    }
                  }
                }
                break()
              case 'golden_finger':
                if(@age == @crop_reward['max_age']) {
                  if(rand() < @breaking_chance) {
                    @damage += 1
                  }
                  @locations[] = @center_location
                  array_remove(@event['drops'], 0)
                  foreach(@seed in @event['drops']) {
                    drop_item(@center_location, @seed, false)
                  }
                  if(!is_cancelled()) { // 성공적으로 수확 시 1단계 작물 심기
                    set_timeout(1, closure() {
                      set_block(@center_location, @crop)
                    })
                  }
                } else {
                  #다 안자란 작물 캘려 하면 안캐지도록 캔슬
                  cancel()
                }
                break()
              default:
                if(@age == @crop_reward['max_age']) {
                  if(rand() < @breaking_chance) {
                    @damage += 1
                  }
                  @locations[] = @center_location
                }
                break()
              }
            } else {
              if(@age == @crop_reward['max_age']) {
                if(rand() < @breaking_chance) {
                  @damage += 1
                }
                @locations[] = @center_location
              }
            }
            _update_item(@player, @uuid, array('main_hand': @item), @player_data, @skills_spec, @text)
            # 루트 테이블 시스템
            @entries = @crop_reward['loot_table']
            @total_weight = 0
            foreach(@key: @entry in @entries) {
              @entries[@key]['weight'] += @entry['quality'] * @farming_mastery_multiply
              @total_weight += @entry['weight']
            }
            # 부순 모든 작물에 드랍 시스템 작동
            foreach(@location in @locations) {
              # 드랍 갯수 설정
              @qty = integer(round(@crop_reward['default_qty'] * @max_drop_multiply * rand()))
              if(@qty < @crop_reward['default_qty']) { @qty = @crop_reward['default_qty']}
              # 드랍 갯수 만큼 아이템 떨구기
              for(@i = 0, @i < @qty, @i++) {
                @result_weight = @total_weight * round(rand(), 5)
                @min_weight = 0
                foreach(@entry in @entries) {
                  @max_weight = @min_weight + @entry['weight']
                  if(@max_weight > @result_weight) {
                    drop_item(@location, @entry['item'], false)
                    _harvesting_logging(@harvesting_log_path, @player, @uuid, @entry['item'], @center_location)
                    break()
                  } else {
                    @min_weight = @max_weight
                  }
                }
              }
              # 경험치 드랍
              if(@player_data['item']['enchantments']['main_hand'] == '경험') {
                _drop_arcanelevel_random_experience(@location, @crop_reward['arcanelevel']['default'], @crop_reward['arcanelevel']['extra'])
                _drop_arcanelevel_random_experience(@location, @crop_reward['arcanelevel']['default'], @crop_reward['arcanelevel']['extra'])
              } else {
                _drop_arcanelevel_random_experience(@location, @crop_reward['arcanelevel']['default'], @crop_reward['arcanelevel']['extra'])
              }
              # 튜나레벨
              _give_tunalevel_random_experience(@uuid, @player_data, @crop_reward['tunalevel']['default'], @crop_reward['tunalevel']['extra'], @text)
            }
            # 내구도 깍기 및 다 부셔지면 아이템 없애기
            if(@max_durability > @damage) {
              @item['meta']['damage'] = @damage
              set_inventory_item(puuid(@player), @slot, @item)
            } else {
              play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
              @item = null
              set_inventory_item(puuid(@player), @slot, @item)
            }
          }
        }
      })
    }
  }
}

proc _farmland_cultivate_event(@event, @player, @uuid, @players_data, @hp_blocks, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  @block = @event['block']
  if(@event['action'] == 'right_click_block' && array_contains(array('GRASS_BLOCK', 'DIRT'), @event['block']) && !is_null(@event['item']) && array_index_exists(@event, 'location')) {
    @location = array('x': @event['location']['x'], 'y': @event['location']['y'], 'z': @event['location']['z'], 'world': @event['location']['world'])
    @hoes_cooldown = array(
      'WOODEN_HOE': 40,
      'STONE_HOE': 28,
      'IRON_HOE': 20,
      'DIAMOND_HOE': 12,
      'NETHERITE_HOE': 8,
      'GOLDEN_HOE': 4
    )
    if(array_contains(array_keys(@hoes_cooldown), @event['item']['name']) && array_contains(array('AIR', 'CAVE_AIR', 'VOID_AIR'), get_block(array('x': @location['x'], 'y': @location['y'] + 1, 'z': @location['z'], 'world': @location['world'])))) {
      if(@event['hand'] == 'main_hand') {
        @slot = pheld_slot(@player)
      } else {
        @slot = 40
      }
      @item = @player_data['item'][@event['hand']]
      if(pcooldown(@player, @item['name']) == 0) {
        if(@player_data['item']['enchantments'][@event['hand']] == '효율') {
          @cooldown_multiply = 0.75
        } else {
          @cooldown_multiply = 1
        }
        foreach(@hoe:@hoe_cooldown in @hoes_cooldown) {
          if(@hoe_cooldown > @hoes_cooldown[@item['name']]) {
            set_pcooldown(@player, @hoe, @hoe_cooldown)
          } else {
            set_pcooldown(@player, @hoe, integer(@hoes_cooldown[@item['name']] * @cooldown_multiply))
          }
        }
        @cultivating_power = 1
        if(!is_null(@item['meta']) && !is_null(@item['meta']['modifiers']) && array_index_exists(@item['meta'], 'modifiers')) {
          foreach(@modifier in @item['meta']['modifiers']) {
            if(@modifier['attribute'] == 'GENERIC_FOLLOW_RANGE') {
              @cultivating_power = @modifier['amount']
              break()
            }
          }
        }
        @max_hp = 20
        @id = array_implode(array(integer(@location['x']), integer(@location['y']), integer(@location['z']), @location['world']), '.')
        if(!array_index_exists(@hp_blocks, @id)) {
          @hp_blocks[@id] = array(
            'name': @block,
            'hp': @max_hp,
            'reset_countdown': 3
          )
        } else if(@hp_blocks[@id]['name'] != @block) {
          @hp_blocks[@id] = array(
            'name': @block,
            'hp': @max_hp,
            'reset_countdown': 3
          )
        }
        @old_hp = @hp_blocks[@id]['hp']
        @hp_blocks[@id]['hp'] -= @cultivating_power
        if(@hp_blocks[@id]['hp'] > 0) {
          @hp_blocks[@id]['reset_countdown'] = 3
          @hp = @hp_blocks[@id]['hp']
          @indicator_data = array(
            'block': 'FARMLAND',
            'max_hp': @max_hp,
            'old_hp': @old_hp,
            'new_hp': @hp,
            'id': @id,
            'countdown': 3
          )
          _show_indicator(@uuid, @player_data, @indicator_data, @text)
          set_block(@location, @block)
          if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'damage')) {
            @damage = 0
          } else {
            @damage = @item['meta']['damage']
          }
          if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'enchants') || !array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
            @unbreaking_level = 0
          } else {
            @unbreaking_level = @item['meta']['enchants']['unbreaking']['elevel']
          }
          @breaking_chance = 1 / (@unbreaking_level + 1)
          if(rand() < @breaking_chance) {
            if(is_null(@item['meta'])) {
              @item['meta'] = array('damage': @damage + 1)
            } else {
              @item['meta']['damage'] = @damage + 1
            }
            if(material_info(@item['name'], 'maxDurability') == @item['meta']['damage']) {
              play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
              set_inventory_item(puuid(@player), @slot, null)
            } else {
              set_inventory_item(puuid(@player), @slot, @item)
            }
            if(@slot == 40) {
              @items = array('off_hand': @item)
            } else {
              @items = array('main_hand': @item)
            }
            _update_item(@player, @uuid, @items, @player_data, @skills_spec, @text)
          }
        } else {
          @hp = 0
          @indicator_data = array(
            'block': 'FARMLAND',
            'max_hp': @max_hp,
            'old_hp': @old_hp,
            'new_hp': @hp,
            'id': @id,
            'countdown': 1
          )
          _show_indicator(@uuid, @player_data, @indicator_data, @text)
        }
      }
    }
  }
}

### 기타 이벤트

# 작물 성장
# age가 0일때, 경작지가 아닌곳에서 작물이 자랄때 성장하는것 캔슬
bind('block_grow', null, null, @event) {
  if(array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'SWEET_BERRY_BUSH'), @event['block'])) {
    if(get_blockdata(@event['location'])['age'] > 0) {
      @under_location = array('x': @event['location']['x'], 'y': @event['location']['y'] - 1, 'z': @event['location']['z'], 'world': @event['location']['world'])
      if(get_block(@under_location) != 'FARMLAND') {
        cancel()
      }
    } else {
      cancel()
    }
  }
}

# 경작지 보호 (다른 block_fade 이벤트를 사용하는 기능이 생길 시 proc화 시켜야 할 수도 있음)
bind('block_fade', null, null, @event) {
  if(@event['block'] == 'FARMLAND') {
    @upper_location = array('x': @event['location']['x'], 'y': @event['location']['y'] + 1, 'z': @event['location']['z'], 'world': @event['location']['world'])
    if(!get_block_info(@upper_location, 'solid')) {
      cancel()
    }
  }
}

# 경작지 수분
bind('mom_moisture_change', null, null, @event) {
  cancel()
  @new_moisture = @event['moistureLevelAfter']
  @old_moisture = @event['moisture']
  @location = array('x': @event['location'][0], 'y': @event['location'][1], 'z': @event['location'][2], 'world': @event['location'][3])
  @crop_location = array_deep_clone(@location)
  @crop_location['y'] += 1
  @is_drying = true
  if(@new_moisture == 7) {
    //broadcast( has_storm(@location['world'])  has_thunder(@location['world']) @location['world'])
    if((has_storm(@location['world']) || has_thunder(@location['world'])) && get_highest_block_at(@location)['y'] <= @crop_location['y']) {
      @is_drying = false
    }
  }
  if(@is_drying) {
    if(array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'SWEET_BERRY_BUSH'), get_block(@crop_location))) {
      @chance = 0.5
    } else {
      @chance = 0.3
    }
    if(rand() < @chance) {
      @new_moisture = @old_moisture - 1
      if(@new_moisture < 0) {@new_moisture = 0}
      set_blockdata(@location, array('block': 'farmland', 'moisture': @new_moisture))
    }
  } else {
    @new_moisture = @old_moisture + 1
    if(@new_moisture > 6) {@new_moisture = 6}
    set_blockdata(@location, array('block': 'farmland', 'moisture': @new_moisture))
  }
}

# 물뿌리개 물뜨기
bind('mom_player_bucket_fill', null, null, @event) {
  @uuid = @event['who']
  @player = player(@uuid)
  @main_hand_item = get_inventory_item(@uuid, pheld_slot(@player))
  @off_hand_item = get_inventory_item(@uuid, 40)
  if(!is_null(@main_hand_item) && @main_hand_item['name'] == 'BUCKET') {
    @slot = pheld_slot(@player)
    @item = @main_hand_item
  } else if(!is_null(@off_hand_item) && @off_hand_item['name'] == 'BUCKET') {
    @slot = 40
    @item = @off_hand_item
  } else {
    @slot = null
    @item = null
  }
  if(!is_null(@item) && !is_null(@item['meta']) && @item['meta']['model'] > 0 && @item['meta']['model'] < 5) {
    cancel()
    @item['name'] = 'TURTLE_HELMET'
    @item['meta']['damage'] = 1
    set_inventory_item(@uuid, @slot, @item)
  }
}

