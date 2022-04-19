# 농사 보상 저장
foreach(@crop_name: @crop_reward in json_decode(comp_read("rewards/crops.json"))) {
  @crop_rewards[@crop_name] = @crop_reward
}

proc _crop_mine_event(@event, @player, @uuid, @players_data, @crop_rewards, @skills_spec, @text, @server) {
  @player_data = @players_data[@uuid]
  @skill_manager = @player_data['skill_manager']
  if(array_contains(array('PUMPKIN', 'MELON'), @event['block'])) { // 수박 호박을 직접 부쉈을 시
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
      if(array_contains(array('ATTACHED_PUMPKIN_STEM', 'ATTACHED_MELON_STEM'), get_block(@near_location['location'])) && get_blockdata(@near_location['location'])['facing'] == @near_location['facing']) {
        @is_placed = false
        break()
      }
    }
    if(!@is_placed) {
      set_timeout(1, closure() {
        if(!is_cancelled()) { // 성공적으로 수확 시
          # 줄기 부수기
          break_block(@near_location['location'])
          @prefix = @text['prefix']['failure']
          _send_instance_tooltip_msg(@player, @uuid, @prefix '수박 또는 호박을 수확하려면 줄기를 낫으로 부셔야 합니다.')
        }
      })
    }
  } else if(array_index_exists(@crop_rewards, @event['block'])) { // 작물 캘시
    # 드랍할 씨앗
    @drop_seeds = @event['drops']
    # 부순 블럭 선언
    @crop = @event['block']
    # 작물 스펙 선언
    @crop_reward = array_deep_clone(@crop_rewards[@crop])
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
      @max_drop_multiply += 1
    }
    # 부술 위치
    @locations = array()
    # 직접 부순 위치
    @center_location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
    # 수확 방식
    @harvesting_method = json_decode(@skill_manager[4])['harvesting_method']
    # 아이템
    @item = @player_data['item']['main_hand']
    # 낫으로 수확시
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
      # 작물 타입별 @age, @facing
      if(@crop_reward['type'] == 'normal') { // 일반 작물 수확시
        @age = get_blockdata(@center_location)['age']
        @facing = null
        @golden_finger_crop = @crop
      } else if(@crop_reward['type'] == 'attached') { // 수박 호박 줄기 수확시
        @age = 8
        @facing = get_blockdata(@center_location)['facing']
        @golden_finger_crop = @crop_reward['golden_finger_crop']
      }
      # 수확 스킬 적용
      @applied_harvesting_method = null
      if(@harvesting_method != '' && @player_data['active_skill'][@harvesting_method][1] > 0) {
        if(@age == @crop_reward['max_age']) { // 다 자란 작물 캘시
          switch(@harvesting_method) {
          case 'wide_hands': // 넓은 손 스킬로 캘시
            @applied_harvesting_method = 'wide_hands'
            # 내구성에 따라 내구도 감소
            if(rand() < @breaking_chance) {
              @damage += 1
            }
            # 캔 블럭 목록에 넣기
            @locations[] = @center_location
            # 주변 블럭들 구하기
            for(@x = -2, @x < 3, @x++) {
              for(@z = -2, @z < 3, @z++) {
                if(@x != 0 || @z != 0) {
                  @surrounding_location = array('x': @center_location['x'] + @x, 'y': @center_location['y'], 'z': @center_location['z'] + @z, 'world': @center_location['world'])
                  if(get_block(@surrounding_location) == @crop) { // 같은 종류의 작물만 목록에 넣기
                    # 작물 타입별 @surrounding_age 구하기
                    if(@crop_reward['type'] == 'normal') { // 일반 작물 수확시
                      @surrounding_age = get_blockdata(@surrounding_location)['age']
                    } else if(@crop_reward['type'] == 'attached') { // 수박 호박 줄기 수확시
                      @surrounding_age = 8
                    }
                    if(@surrounding_age == @crop_reward['max_age']) {
                      if(@max_durability > @damage) { // 내구도 여유 있을시
                        # 내구성에 따라 내구도 감소
                        if(rand() < @breaking_chance) {
                          @damage += 1
                        }
                        # 주변 블럭들 부술 블럭 목록에 넣기 및 부수기
                        @locations[] = @surrounding_location
                      }
                    }
                  }
                }
              }
            }
            break()
          case 'golden_finger': // 골든 핑거 스킬로 캘시
            @applied_harvesting_method = 'golden_finger'
            # 내구성에 따라 내구도 감소
            if(rand() < @breaking_chance) {
              @damage += 1
            }
            # 캔 블럭 목록에 넣기
            @locations[] = @center_location
            break()
            # 씨앗 드랍 1개 제거
            array_remove(@drop_seeds, 0)
          }
        } else { // 다 안자란 작물 캘시 캔슬
          cancel()
        }
      } else { // 수확 스킬 비활성화 상태에서 캘시
        if(@age == @crop_reward['max_age']) {
          # 내구성에 따라 내구도 감소
          if(rand() < @breaking_chance) {
            @damage += 1
          }
          # 캔 블럭 목록에 넣기
          @locations[] = @center_location
        }
      }
      # 캔슬 안 됬을 경우 수확 시스템 작동
      set_timeout(1, closure() {
        if(!is_cancelled()) {
          # 괭이 재 검사 (타임아웃 때문에 혹시 모름)
          @item = @player_data['item']['main_hand']
          @slot = pheld_slot(@player)
          if(!is_null(@item) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @item['name'])) { // 재검사 통과 시
            # 루트 테이블 시스템
            @entries = @crop_reward['rainy_biome']['loot_table']
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
              # 작물 타입에 따른 드랍 위치 설정 및 수박 호박의 경우 블럭도 부수기
              if(@crop_reward['type'] == 'normal') { // 일반 작물 수확시
                @drop_location = @location
              } else if(@crop_reward['type'] == 'attached') { // 수박 호박 줄기 수확시
                @drop_location = array_deep_clone(@location)
                if(@center_location != @location) {
                  @facing = get_blockdata(@drop_location)['facing']
                }
                switch(@facing) {
                case 'east':
                  @drop_location['x'] += 1
                  break()
                case 'west':
                  @drop_location['x'] -= 1
                  break()
                case 'south':
                  @drop_location['z'] += 1
                  break()
                case 'north':
                  @drop_location['z'] -= 1
                  break()
                }
                # 수박 호박 제거
                if(get_block(@drop_location) == @crop_reward['attached_crop']) {
                  set_block(@drop_location, 'AIR')
                }
              }
              # 적용된 수확방식에 따른 코드 작동
              switch(@applied_harvesting_method) {
              case 'wide_hands':
                # 블럭 부수기
                if(@center_location != @location) {
                  break_block(@location)
                }
                break()
              case 'golden_finger':
                # 작물 심기
                set_block(@center_location, @golden_finger_crop)
                # 파종 스킬에 따라 작물 심기
                @sowing_method = json_decode(@skill_manager[4])['sowing_method']
                if(@sowing_method != '' && @player_data['active_skill'][@sowing_method][1] > 0) {
                  switch(@sowing_method) {
                  case 'wet_hands':
                    @farmland_location = array_deep_clone(@center_location)
                    @farmland_location['y'] -= 1
                    @farmland_blockdata = get_blockdata(@farmland_location)
                    if(@farmland_blockdata['block'] == 'farmland') {
                      @farmland_blockdata['moisture'] = 5
                      set_blockdata(@farmland_location, @farmland_blockdata)
                    }
                    break()
                  case 'fertile_touch':
                    @crop_location = array_deep_clone(@center_location)
                    @crop_blockdata = get_blockdata(@crop_location)
                    @crop_blockdata['age'] = 1
                    set_blockdata(@crop_location, @crop_blockdata)
                    break()
                  }
                }
                break()
              }
              # 드랍 갯수 만큼 아이템 떨구기
              for(@i = 0, @i < @qty, @i++) {
                @result_weight = @total_weight * round(rand(), 5)
                @min_weight = 0
                foreach(@entry in @entries) {
                  @max_weight = @min_weight + @entry['weight']
                  if(@max_weight > @result_weight) {
                    drop_item(@drop_location, @entry['item'], false)
                    _logging('harvest', time(), @server, @location, @player, @uuid, @entry['item'])
                    break()
                  } else {
                    @min_weight = @max_weight
                  }
                }
              }
              # 경험치 드랍
              if(@player_data['item']['enchantments']['main_hand'] == '경험') {
                _drop_arcanelevel_random_experience(@drop_location, @crop_reward['rainy_biome']['arcanelevel']['default'], @crop_reward['rainy_biome']['arcanelevel']['extra'])
                _drop_arcanelevel_random_experience(@drop_location, @crop_reward['rainy_biome']['arcanelevel']['default'], @crop_reward['rainy_biome']['arcanelevel']['extra'])
              } else {
                _drop_arcanelevel_random_experience(@drop_location, @crop_reward['rainy_biome']['arcanelevel']['default'], @crop_reward['rainy_biome']['arcanelevel']['extra'])
              }
              # 튜나레벨
              _give_tunalevel_random_experience(@uuid, @player_data, @crop_reward['rainy_biome']['tunalevel']['default'], @crop_reward['rainy_biome']['tunalevel']['extra'], @text)
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
    } else {
      if(array_index_exists(@drop_seeds, 1)) {
        array_remove(@drop_seeds, 1)
      }
    }
    # 씨앗 드랍 수정
    modify_event('drops', array())
    set_timeout(1, closure() {
      if(!is_cancelled()) {
        foreach(@drop_seed in @drop_seeds) {
          drop_item(@center_location, @drop_seed, false)
        }
      }
    })
  }
}

proc _farmland_cultivate_event(@event, @player, @uuid, @players_data, @hp_blocks, @skills_spec, @text) {
  @player_data = @players_data[@uuid]
  @block = @event['block']
  if(@event['action'] == 'right_click_block' && array_contains(array('GRASS_BLOCK', 'DIRT', 'DIRT_PATH'), @event['block']) && !is_null(@event['item']) && array_index_exists(@event, 'location')) {
    @location = array('x': @event['location']['x'], 'y': @event['location']['y'], 'z': @event['location']['z'], 'world': @event['location']['world'])
    @hoes_cooldown = array(
      'WOODEN_HOE': 40,
      'STONE_HOE': 28,
      'IRON_HOE': 20,
      'DIAMOND_HOE': 12,
      'NETHERITE_HOE': 8,
      'GOLDEN_HOE': 4
    )
    @seeds = array(
      'WHEAT_SEEDS',
      'BEETROOT_SEEDS',
      'POTATO',
      'CARROT',
      'PUMPKIN_SEEDS',
      'MELON_SEEDS',
      'SWEET_BERRIES'
    )
    @item = @event['item']
    if(array_contains(array_keys(@hoes_cooldown), @item['name']) && array_contains(array('AIR', 'CAVE_AIR', 'VOID_AIR'), get_block(array('x': @location['x'], 'y': @location['y'] + 1, 'z': @location['z'], 'world': @location['world'])))) {
      if(@event['hand'] == 'main_hand') {
        @slot = pheld_slot(@player)
      } else {
        @slot = 40
      }
      //@player_data['item'][@event['hand']]
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
        foreach(@seed in @seeds) {
          set_pcooldown(@player, @seed, 50)
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
  if(array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'SWEET_BERRY_BUSH'), @event['block']) || array_contains(array('PUMPKIN', 'MELON'), @event['newblock'])) {
    if(array_contains(array('PUMPKIN', 'MELON'), @event['newblock']) || get_blockdata(@event['location'])['age'] > 0) {
      @under_location = array('x': @event['location']['x'], 'y': @event['location']['y'] - 1, 'z': @event['location']['z'], 'world': @event['location']['world'])
      if(get_block(@under_location) != 'FARMLAND') {
        cancel()
      } else {
        if(!array_contains(array('PUMPKIN', 'MELON'), @event['newblock'])) {
          if(get_blockdata(@under_location)['moisture'] == 0) {
            cancel()
          }
        }
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
    @upper_block = get_block(@upper_location)
    if(array_contains(array('PUMPKIN', 'MELON'), @upper_block) || !get_block_info(@upper_location, 'solid')) {
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
    if(array_contains(array('WHEAT', 'BEETROOTS', 'CARROTS', 'POTATOES', 'PUMPKIN_STEM', 'MELON_STEM', 'ATTACHED_PUMPKIN_STEM', 'ATTACHED_MELON_STEM', 'SWEET_BERRY_BUSH'), get_block(@crop_location))) {
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
    if(@new_moisture > 5) {@new_moisture = 5}
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

