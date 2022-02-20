# 채광 보상 저장
@files = list_files('rewards')
foreach(@file in @files) {
  @file_path = "rewards/@file"
  @file_name_and_extension = _get_file_name_and_extension(@file)
  @file_name = @file_name_and_extension[0]
  @file_extension = @file_name_and_extension[1]
  if(@file_extension == 'json') {
    async_read_file(@file_path, closure(@content) {
      foreach(@mineral_name: @mineral_reward in json_decode(@content)) {
        #@namespace = "@file_name:@mineral_name"
        #@mineral_rewards[@namespace] = @mineral_reward
        @mineral_rewards[@mineral_name] = @mineral_reward
      }
    })
  }
}

# 광질 로깅
@mining_log_data = array()
if(@server != 'main') {
  @date = simple_date('yyyy-MM-dd')
  @mining_log_data = array(
    'date': @date,
    'path': 'logs/'.@date.'.log'
  )

  if(!file_exists(@mining_log_data['path'])) {
    create_file(@mining_log_data['path'])
  }

  @cron_task = set_cron('0 0 * * *', closure() {
    @date = simple_date('yyyy-MM-dd')
    @mining_log_data['date'] = @date
    @mining_log_data['path'] = 'logs/'.@date.'.log'
  })

  proc _mining_logging(@mining_log_data, @player, @uuid, @item, @location) {
    if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
      @item_name = strip_colors(@item['meta']['display'])
    } else {
      @item_name = @item['name']
    }
    @x = integer(@location['x']) 
    @y = integer(@location['y'])
    @z = integer(@location['z'])
    @message = "@player(@uuid) mine @item_name in x: @x y: @y z: @z"
    @log = string('['.simple_date('HH:mm:ss').'] '.@message.'\n')
    write_file(@mining_log_data['path'], @log, 'APPEND')
  }
}

proc _mineral_mine_event(@event, @player, @uuid, @players_data, @hp_blocks, @mineral_rewards, @skills_spec, @text, @mining_log_data) {
  @player_data = @players_data[@uuid]
  # 부순 블럭 선언
  @mineral = @event['block']
  # 부순 블럭이 광물일시
  if(array_contains(array_keys(@mineral_rewards), @mineral)) {
    # 광물 스펙 선언
    @mineral_reward = @mineral_rewards[@mineral]
    ## 곡괭이 관련 데이터 선언
    # 기본 데이터 선언
    @pickaxe_hardness = 0
    @mining_power = 0
    # 곡괭이 강도 데이터
    @pickaxes_hardness = array(          # 캘수있는 광물
      'WOODEN_PICKAXE': 1,   #나무         (돌)
      #                      #돌           (돌, 구리)
      'STONE_PICKAXE': 3,    #구리         (돌, 구리, 철)
      'IRON_PICKAXE': 4,     #철           (돌, 구리, 철, 금)
      'GOLDEN_PICKAXE': 5,   #금           (돌, 구리, 철, 금, 다이아)
      'DIAMOND_PICKAXE': 6,  #다이아       (돌, 구리, 철, 금, 다이아, 고대파편)
      'NETHERITE_PICKAXE': 7 #네더라이트   (돌, 구리, 철, 금, 다이아, 고대파편)
    )
    if(!is_null(@player_data['item']['main_hand']) && array_contains(array_keys(@pickaxes_hardness), @player_data['item']['main_hand']['name'])) { // 곡괭이로 채굴할시
      # 곡괭이 선언
      @pickaxe = @player_data['item']['main_hand']
      # 곡괭이 강도 설정
      @pickaxe_hardness = @pickaxes_hardness[@pickaxe['name']]
      if(!is_null(@pickaxe['meta'])) {
        if(@pickaxe_hardness == 1 && @pickaxe['meta']['model'] >= 8) {
          @pickaxe_hardness = 2 // 돌 곡괭이 강도 조정
        }
        if(array_index_exists(@pickaxe['meta'], 'modifiers')) {
          foreach(@modifier in @pickaxe['meta']['modifiers']) {
            if(@modifier['attribute'] == 'HORSE_JUMP_STRENGTH') {
              # 채굴 강도 선언
              @mining_power = @modifier['amount']
              break()
            }
          }
        }
      }
    }
    # 위치 선언 (아이템 드랍 위치 기준)
    @location = array('x': @event['location']['x'] + 0.5, 'y': @event['location']['y'] + 0.5, 'z': @event['location']['z'] + 0.5, 'world': @event['location']['world'])
    # id 선언 (x.y.z.world)
    @id = array_implode(array(integer(@location['x']), integer(@location['y']), integer(@location['z']), @location['world']), '.')
    # 피통 선언
    @max_hp = @mineral_rewards[@mineral]['hp']
    if(@pickaxe_hardness >= @mineral_rewards[@mineral]['hardness']) { // 곡괭이로 캘 수 있는 광물일시
      ## 스킬 불러오기
      # 강인한 어깨 배수
      @mining_power_point = @player_data['skill_data']['tough_shoulder'][0]
      @mining_power_multiply = @skills_spec['tough_shoulder']['effect_by_point'][@mining_power_point]['multiply']
      @mining_power *= @mining_power_multiply
      # 채광 숙련 배수
      @mining_mastery_multiply = 1
      if(array_index_exists(@mineral_reward, 'mastery')) {
        @mining_mastery_name = @mineral_reward['mastery']
        @mining_mastery_point = @player_data['skill_data'][@mining_mastery_name][0]
        @mining_mastery_multiply = @skills_spec[@mining_mastery_name]['effect_by_point'][@mining_mastery_point]['multiply']
      }
      # 선광 배수
      @ore_selecting_multiply = 1
      switch(@location['world']) {
      case 'over':
        @ore_selecting_name = 'over_ore_selecting'
        break()
      case 'nether':
        @ore_selecting_name = 'nether_ore_selecting'
        break()
      default:
        @ore_selecting_name = null
        break()
      }
      if(!is_null(@ore_selecting_name)) {
        @ore_selecting_point = @player_data['skill_data'][@ore_selecting_name][0]
        @ore_selecting_multiply = @skills_spec[@ore_selecting_name]['effect_by_point'][@ore_selecting_point]['multiply']
      }
      # 최대 드랍 갯수 배수에 선광 스킬 배수, 인첸트 반영
      @max_drop_multiply = @ore_selecting_multiply
      if(@player_data['item']['enchantments']['main_hand'] == '행운') {
        @max_drop_multiply += 1.5
      }
      # id가 존재하지 않거나 광물이 다른 광물로 바뀔경우 기본데이터로 설정
      if(!array_index_exists(@hp_blocks, @id)) {
        @hp_blocks[@id] = array(
          'name': @mineral,
          'hp': @mineral_rewards[@mineral]['hp'],
          'reset_countdown': 3,
          'logs': array(
            'max_drop_multiplies': array(),
            'rank_quality_multiplies': array()
          )
        )
      } else if(@hp_blocks[@id]['name'] != @mineral) {
        @hp_blocks[@id] = array(
          'name': @mineral,
          'hp': @mineral_rewards[@mineral]['hp'],
          'reset_countdown': 3,
          'logs': array(
            'max_drop_multiplies': array(),
            'rank_quality_multiplies': array()
          )
        )
      }
      # old_hp 선언
      @old_hp = @hp_blocks[@id]['hp']
      # 체력 깍기 (0이하로 내려거면 0으로 설정) 및 @hp_block 기타 데이터 갱신
      @hp_blocks[@id]['hp'] -= @mining_power
      if(@hp_blocks[@id]['hp'] < 0) {
        @hp_blocks[@id]['hp'] = 0
      }
      @hp_blocks[@id]['reset_countdown'] = 3
      # hp 선언
      @hp = @hp_blocks[@id]['hp']
      # 선광 숙련, 채굴 숙련 기록
      @hp_blocks[@id]['logs']['max_drop_multiplies'][] = @max_drop_multiply
      @hp_blocks[@id]['logs']['rank_quality_multiplies'][] = @mining_mastery_multiply
      # 채굴 도중 일시
      if(@hp > 0) {
        cancel()
        # 수동 내구도 깍기 (캔슬 걸려 있어서 내구도 깍아줘야 함)
        @item = @player_data['item']['main_hand']
        @slot = pheld_slot(@player)
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
            @item = null
            set_inventory_item(puuid(@player), @slot, null)
          } else {
            set_inventory_item(puuid(@player), @slot, @item)
          }
          _update_item(@player, @uuid, array('main_hand': @item), @player_data, @skills_spec, @text)
        }
        # 인디케이터 데이터 설정
        @indicator_data  = array(
          'block': @mineral,
          'max_hp': @max_hp,
          'old_hp': @old_hp,
          'new_hp': @hp,
          'id': @id,
          'countdown': 7
        )
      } else { // 채굴 완료시
        # 선광 숙련, 채광 숙련 평균 구하기 (높은 레벨 유저가 막타 치거나 행운곡 막타 방지)
        @mining_mastery_multiply = average(@hp_blocks[@id]['logs']['rank_quality_multiplies']) 
        @max_drop_multiply = average(@hp_blocks[@id]['logs']['max_drop_multiplies'])
        # 채굴 데이터 삭제
        array_remove(@hp_blocks, @id)
        # 채굴 완료 소리
        play_named_sound(@location, array(
          'sound': 'minecraft:entity.player.levelup',
          'category': 'PLAYERS',
          'volume': 0.4,
          'pitch': 1.5
        ), @player)
        # 루트 테이블 시스템
        @entries = @mineral_reward['loot_table']
        @total_weight = 0
        foreach(@key: @entry in @entries) {
          # 채광 숙련 반영 (채광 숙련 스킬 연관 없는 광물일 경우 배수는 1임)
          @entries[@key]['weight'] += @entry['quality'] * @mining_mastery_multiply
          @total_weight += @entry['weight']
        }
        # 드랍 갯수 설정
        @qty = integer(round(@mineral_reward['default_qty'] * @max_drop_multiply * rand()))
        if(@qty < @mineral_reward['default_qty']) { @qty = @mineral_reward['default_qty']}
        # 드랍 갯수 만큼 아이템 떨구기
        for(@i = 0, @i < @qty, @i++) {
          @result_weight = @total_weight * round(rand(), 5)
          @min_weight = 0
          foreach(@entry in @entries) {
            @max_weight = @min_weight + @entry['weight']
            if(@max_weight > @result_weight) {
              drop_item(@location, @entry['item'], false)
              _mining_logging(@mining_log_data, @player, @uuid, @entry['item'], @location)
              break()
            } else {
              @min_weight = @max_weight
            }
          }
        }
        # 경험치 드랍
        if(@player_data['item']['enchantments']['main_hand'] == '경험') {
          _drop_arcanelevel_random_experience(@location, @mineral_reward['arcanelevel']['default'], @mineral_reward['arcanelevel']['extra'])
          _drop_arcanelevel_random_experience(@location, @mineral_reward['arcanelevel']['default'], @mineral_reward['arcanelevel']['extra'])
        } else {
          _drop_arcanelevel_random_experience(@location, @mineral_reward['arcanelevel']['default'], @mineral_reward['arcanelevel']['extra'])
        }
        # 튜나레벨
        _give_tunalevel_random_experience(@uuid, @player_data, @mineral_reward['tunalevel']['default'], @mineral_reward['tunalevel']['extra'], @text)
        # 아이템, 경험치 수동으로 떨구기 때문에 모디피 이벤트로 이벤트 결과 수정
        modify_event('drops', array())
        modify_event('xp', 0)
        # 인디케이터 데이터 설정
        @indicator_data = array(
          'block': @mineral,
          'max_hp': @max_hp,
          'old_hp': @old_hp,
          'new_hp': @hp,
          'id': @id,
          'countdown': 1
        )
      }
    } else { # 곡괭이 강도가 부족할시
      # hp 변화 없어 보이도록 @hp 선언
      if(array_index_exists(@hp_blocks, @id)) {
        @old_hp = @hp_blocks[@id]['hp']
        @hp = @hp_blocks[@id]['hp']
      } else {
        @old_hp = @mineral_rewards[@mineral]['hp']
        @hp = @mineral_rewards[@mineral]['hp']
      }
      # 인디케이터 데이터 설정
      @indicator_data = array(
        'block': @mineral,
        'max_hp': @max_hp,
        'old_hp': @old_hp,
        'new_hp': @hp,
        'id': @id,
        'countdown': 3
      )
      cancel()
    }
    #인디케이터 보여주기
    _show_indicator(@uuid, @player_data, @indicator_data, @text)
    #캔슬은 안됬는데 정상적으로 캔게 아닐떼 템 안떨구도록 해주는 코드
    modify_event('drops', array())
  }
}