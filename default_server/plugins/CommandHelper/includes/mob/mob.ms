@boss_names = array()
# 몹 보상 저장
@files = list_files('rewards')
foreach(@file in @files) {
  @file_path = "rewards/@file"
  @file_name_and_extension = _get_file_name_and_extension(@file)
  @file_name = @file_name_and_extension[0]
  @file_extension = @file_name_and_extension[1]
  if(@file_extension == 'json') {
    async_read_file(@file_path, closure(@content) {
      foreach(@mob_name: @mob_reward in json_decode(@content)) {
        @namespace = "@file_name:@mob_name"
        @mob_rewards[@namespace] = @mob_reward
        # 보스일경우 따로 이름 저장
        if(array_index_exists(@mob_reward, 'is_boss') && @mob_reward['is_boss']) {
          @boss_names[] = @mob_name
        }
      }
    })
  }
}

bind('entity_death', null, null, @event, @players_data, @mob_rewards, @text) {
  @id = @event['id']
  @mob_name = strip_colors(get_mob_name(@id))
  if(@mob_name == '') { @mob_name = entity_type(@id) }
  @location = entity_loc(@id)
  @location['y'] += 1

  @is_unconfigured_mob = true
  foreach(@namespace: @mob_reward in @mob_rewards) {
    @splited_namespace = split(':', @namespace)
    @category = @splited_namespace[0]
    if(@mob_name == @splited_namespace[1]) { // 이름이 같은 몹일 시
      # 컨피큐어드 몹으로 설정 및 경치 드랍 제거
      @is_unconfigured_mob = false
      modify_event('xp', 0)
      
      # 몹 타입에 따른 보상
      if(array_index_exists(@mob_reward, 'is_boss') && @mob_reward['is_boss']) { // 보스일 시 (태그상에 인식되는 플레이어들에게 보상 지급)
        @size = array_size(get_scoreboard_tags(@id))
        @money = 300
        @tunapoint = 200

        @player_rewards = array()
        foreach(@player in get_scoreboard_tags(@id)) {
          if(ponline(@player)) {
            @uuid = puuid(@player)
            @player_data = @players_data[@uuid]

            @money_per_player = @money / @size
            @tunapoint_per_player = @tunapoint / @size
            broadcast(@player)
            //acc_add(@target_name, rand(integer(@money_per_player * 0.5), integer(@money_per_player * 1.5)))
            //_give_tunalevel_random_experience(@target_uuid, @player_data, @tunapoint_per_player / 2, @tunapoint_per_player, @text)
          }
        }
        
        /*
        
        @items = array(
          _drop_item_random_qty(@location, 'arcane_essence', 'arcane_essence_2', 1, 2, @ch_items),
          _drop_item_random_qty(@location, 'arcane_essence', 'arcane_essence_6', 1, 1, @ch_items),
          _drop_item_random_qty(@location, 'mineral', 'netherite_scrap_c', 1, 4, @ch_items),
          _drop_item_random_qty(@location, 'mineral', 'netherite_scrap_b', -3, 6, @ch_items),
          _drop_item_random_qty(@location, 'mineral', 'netherite_scrap_a', -8, 10, @ch_items),
          _drop_item_random_qty(@location, 'mineral', 'netherite_scrap_s', -99, 100, @ch_items),
          _drop_item_random_qty(@location, 'misc', 'EXPERIENCE_BOTTLE', -99, 100, @ch_items)
        )

        foreach(@item in @items) {
          if(!is_null(@item)) {
          }
        }
        
        
        // @type @time @server, @location, @mob, @player_rewards, @items
        _logging('loot', time(), @server, @location, @id, @item)
        */
        broadcast(B)
      } else if(array_index_exists(@event['cause'],'damager') && ponline(@event['cause']['damager'])) { // 플레이어에 의하여 죽은 컨픽상에 있는 몹일 시 (막타 친 플레이어에게 보상 지급)
        @player = @event['cause']['damager']
        @uuid = puuid(@player)
        @player_data = @players_data[@uuid]
        
        @player_rewards = array()
        @player_rewards[@player] = array(
          'uuid': @uuid,
          'arcanepoint': 0,
          'tunapoint': 0,
          'can': 0
        )
        # 아케인레벨 주기
        if(array_index_exists(@mob_reward, 'arcanelevel')) {
          if(@players_data[@uuid]['item']['enchantments']['main_hand'] == '경험') {
            @player_rewards[@player]['arcanepoint'] += _give_arcanelevel_random_experience(@player, @uuid, @mob_reward['arcanelevel']['default'], @mob_reward['arcanelevel']['extra'], @text)
            @player_rewards[@player]['arcanepoint'] += _give_arcanelevel_random_experience(@player, @uuid, @mob_reward['arcanelevel']['default'], @mob_reward['arcanelevel']['extra'], @text)
          } else {
            @player_rewards[@player]['arcanepoint'] += _give_arcanelevel_random_experience(@player, @uuid, @mob_reward['arcanelevel']['default'], @mob_reward['arcanelevel']['extra'], @text)
          }
        }
        # 튜나레벨 주기
        if(array_index_exists(@mob_reward, 'tunalevel')) {
          @player_rewards[@player]['tunapoint'] += _give_tunalevel_random_experience(@uuid, @player_data, @mob_reward['tunalevel']['default'], @mob_reward['tunalevel']['extra'], @text)
        }
        # 캔 주기
        if(array_index_exists(@mob_reward, 'money')) {
          @money = _get_random_double(@mob_reward['money']['default'], @mob_reward['money']['extra'])
          @player_rewards[@player]['can'] += @money
          if(@money > 0) {
            acc_add(@player, @money)
          }
        }
        # 아이템 떨구기
        if(array_index_exists(@mob_reward, 'loot_tables')) {
          @loot_tables = array_deep_clone(@mob_reward['loot_tables'])
          foreach(@loot_table in @loot_tables) {
            # 갯수 세팅 (아이템 뽑히는 횟수)
            if(is_array(@loot_table['qty'])) {
              @qty = integer(round(@loot_table['qty']['default'] + @loot_table['qty']['extra'] * rand())) // 플레이어 행운 인첸트 수치 반영하도록 변경
              if(@qty < 0) { @qty = 0 }
            } else {
              @qty = @loot_table['qty']
            }
            # 엔트리 weight 세팅
            @entries = @loot_table['entries']
            @total_weight = 0
            foreach(@key: @entry in @entries) {
              @entries[@key]['weight'] += @entry['quality'] * 1 // 해당 플레이어 행운 어트리뷰트 수치 반영하도록 변경
              @total_weight += @entry['weight']
            }
            # 드랍
            for(@i = 0, @i < @qty, @i++) {
              @result_weight = @total_weight * round(rand(), 5)
              @min_weight = 0
              foreach(@entry in @entries) {
                @max_weight = @min_weight + @entry['weight']
                if(@max_weight > @result_weight) {
                  drop_item(@location, @entry['item'], false)
                  //_logging('harvest', time(), @server, @location, @player, @uuid, @entry['item'])
                  break()
                } else {
                  @min_weight = @max_weight
                }
              }
            }
          }
          broadcast(@loot_tables)
        }
      }
      /*
      # 비법서 드랍
      if(array_index_exists(@mob_reward, 'scroll') && array_index_exists(@mob_reward['scroll'], 'chance') && rand() > @mob_reward['scroll']['chance']) { // chance 부분 수식 역으로 바꿔야 함
        @scroll_rank = 0 // 비법서 랭크
        if(array_index_exists(@mob_reward['scroll'], 'rank')) {
          @scroll_rank = @mob_reward['scroll']['rank']
          switch(rand(20)) {
          case 0..5:
            @extra_rank = -1
            break()
          case 6..14:
            @extra_rank = 0
            break()
          case 15..18:
            @extra_rank = 1
            break()
          case 19:
            @extra_rank = 2
            break()
          }
          @scroll_rank += @extra_rank
          if(@scroll_rank > 3) { // 최종 랭크가 3보다 클 시, 비법서 드랍
            switch(rand(5)) {
            case 0..2:
              # 사용중인 전투 방식
              # 사용중인 전투 구하기
              # 없을경우 사용중이지 않은 전투방식중 랜덤으로 하나 지장
              # 해당 비법서를 name로 지정
              break()
            case 3:
              # 사용중이지 않은 전투 방식
              # 사용중인 전투 구하기
              # 사용중인것 제외한 나머지 전투방식중에서 하나 지정
              # 해당 비법서를 name로 지정
              break()
            case 4:
              # 보조 전투
              # 보조 전투중에서 하나 지정
              # 해당 비법서를 name로 지정
              break()
            }
            #해당 name과 rank에 해당하는 비법서 주기
          }
        }
      }
      # 룬 드랍
      if(array_index_exists(@mob_reward, 'rune') && array_index_exists(@mob_reward['rune'], 'name') && array_index_exists(@mob_reward['rune'], 'chance') && rand() > @mob_reward['rune']['chance']) { // chance 부분 수식 역으로 바꿔야 함
        @rune_rank = 0 // 비법서 랭크
        if(array_index_exists(@mob_reward['rune'], 'rank')) {
          @rune_rank = @mob_reward['rune']['rank']
          #broadcast(@mob_reward['rune']['name'] @mob_reward['rune']['rank'])
          #해당 name과 rank에 해당하는 룬 주기
        }
      }
      */
      # 포리치 종료
      break()
    }
  }
  if(@is_unconfigured_mob) { // 컨픽상에 없는 몹일 시
    if(array_index_exists(@event['cause'],'damager') && ponline(@event['cause']['damager'])) {
      @player = @event['cause']['damager']
      @uuid = puuid(@player)
      @player_data = @players_data[@uuid]
    }
    if(@player_data['item']['enchantments']['main_hand'] == '경험') {
      modify_event('xp', integer(@event['xp'] * 2))
    }
    _give_tunalevel_random_experience(@uuid, @player_data, 0, @event['xp'] / 3, @text)
  }
}

/*
bind('entity_death', null, null, @event, @players_data, @text, @ch_items, @server) {
  if(array_index_exists(@event['cause'],'damager') && ponline(@event['cause']['damager'])) {
    # 플레이어에 의하여 죽을시
    @player = @event['cause']['damager']
    @uuid = puuid(@player)
    @player_data = @players_data[@uuid]

    @id = @event['id']
    @mob_name = strip_colors(get_mob_name(@id))

    if(@mob_name == '') { // 바닐라몹일시
      _give_tunalevel_random_experience(@uuid, @player_data, 0, @event['xp'] / 3, @text)
    } else {
      @location = @event['location']
      switch(@mob_name) {
      case '글룸':
        @size = array_size(get_scoreboard_tags(@id))
        @money = 300
        @tunapoint = 200

        @player_rewards = array()
        foreach(@target_name in get_scoreboard_tags(@id)) {
          if(ponline(@target_name)) {
            @target_uuid = puuid(@target_name)
            @player_data = @players_data[@target_uuid]

            @money_per_player = @money / @size
            @tunapoint_per_player = @tunapoint / @size
            acc_add(@target_name, rand(integer(@money_per_player * 0.5), integer(@money_per_player * 1.5)))
            _give_tunalevel_random_experience(@target_uuid, @player_data, @tunapoint_per_player / 2, @tunapoint_per_player, @text)
          }
        }
        
        
        @items = array(
          _drop_item_random_qty(@location, 'arcane_essence', 'arcane_essence_2', 1, 2, @ch_items),
          _drop_item_random_qty(@location, 'arcane_essence', 'arcane_essence_6', 1, 1, @ch_items),
          _drop_item_random_qty(@location, 'mineral', 'netherite_scrap_c', 1, 4, @ch_items),
          _drop_item_random_qty(@location, 'mineral', 'netherite_scrap_b', -3, 6, @ch_items),
          _drop_item_random_qty(@location, 'mineral', 'netherite_scrap_a', -8, 10, @ch_items),
          _drop_item_random_qty(@location, 'mineral', 'netherite_scrap_s', -99, 100, @ch_items),
          _drop_item_random_qty(@location, 'misc', 'EXPERIENCE_BOTTLE', -99, 100, @ch_items)
        )

        foreach(@item in @items) {
          if(!is_null(@item)) {
          }
        }
        
        
        // @type @time @server, @location, @mob, @player_rewards, @items
        _logging('loot', time(), @server, @location, @id, @item)
        
        break()
      }
    }
  }
}

*/
# 스폰된 몹 들 입고있는 아이템 떨구지 안토록 수정
bind('creature_spawn', null, null, @event) {
  @uuid = @event['id']
  if(entity_exists(@uuid) && is_entity_living(@uuid) && entity_type(@uuid) != 'UNKNOWN') {
    set_equipment_droprates(@uuid, array(
      'HELMET': 0,
      'CHESTPLATE': 0,
      'LEGGINGS': 0,
      'BOOTS': 0,
      'WEAPON': 0,
      'OFF_HAND': 0
    ))
  }
}

# 스포너 스폰 캔슬
bind('spawner_spawn', null, null, @event) {
  cancel()
}