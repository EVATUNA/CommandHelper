proc _update_tip_data(@uuid, @players_data) {
  @tip_data_path = 'data/'.@uuid.'.json'
  if(file_exists(@tip_data_path)) {
    async_write_file(@tip_data_path, json_encode(@players_data[@uuid]['cache']['tip_data']), 'OVERWRITE')
  }
}

proc _bind_tip_events(@player, @uuid, @players_data) {
  @tip_data = @players_data[@uuid]['cache']['tip_data']
  switch(pworld(@player)) {
  case 'spawn':
  case 'spawn_minecraft_residence':
    if(!array_index_exists(@tip_data, 'spawn_join')) {
      @tip_data['spawn_join'] = 0
    }
    if(@tip_data['spawn_join'] < 1) {
      bind('player_move', array('id': 'tip.spawn_join.'.@player), array('player': @player, 'world': 'spawn'), @event, @player, @uuid, @players_data, @tip_data) {
        tmsg(@player, ' §7화면 상 하단에 사각형이 보이신다면, 언어 설정에서')
        tmsg(@player, ' §7\'유니코드 글꼴 강제 사용\'을 \'꺼짐\'으로 설정해주세요.')
        @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
        _add_tips(@player, @uuid, @players_data, '카테가트 스폰마을에 오신 것을 환영합니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '스폰에선 상점 이용과 월드 이동이 가능하며, 활동형 이벤트에 참여하실 수 있습니다.', 5, false, @sound)
        _add_tips(@player, @uuid, @players_data, '야생 월드는 각각 거주월드와 자원 월드로 나뉘며,', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '첫 번째 테마 월드인 \'지옥\' 월드에도 입장하실 수 있습니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '거주 월드에서는 땅을 구매하여 자신만의 영역을 만들고 넓혀나갈 수 있습니다.', 5, false, @sound)
        _add_tips(@player, @uuid, @players_data, '자원 월드에서는 필요한 자원을 얻기 위해 자유롭게 채광하실 수 있습니다.', 5, false, @sound)
        _add_tips(@player, @uuid, @players_data, '지옥 월드는 특수한 필드 환경이 조성되어있으며,', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '해당 월드에서는 일반 자원 월드보다 상위 등급의 자원을 획득하실 수 있습니다.', 5, false, @sound)
        _add_tips(@player, @uuid, @players_data, '에바참치의 야생은 기존의 바닐라 야생을 재해석한 서버인 만큼', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '새롭고 다채로운 야생 경험을 제공합니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '기존과 다른 방식의 시스템들은 툴팁으로 안내해드리겠습니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '그럼 즐거운 에바참치 되시기를 바라겠습니다.', 4, false, @sound)
        @tip_data['spawn_join'] += 1
        _update_tip_data(@uuid, @players_data)
        unbind()
      }
    }
    if(!array_index_exists(@tip_data, 'residence_join')) {
      @tip_data['residence_join'] = 0
    }
    if(@tip_data['residence_join'] < 5) {
      bind('player_move', array('id': 'tip.residence_join.'.@player), array('player': @player, 'world': 'spawn_minecraft_residence'), @event, @player, @uuid, @players_data, @tip_data) {
        @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
        _add_tips(@player, @uuid, @players_data, '거주 월드에선 점유한 청크에서만 건축 및 파괴가 가능합니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '다이아몬드 블럭을 손에 들고 웅크린 상태에서 설치하여 청크를 점유할 수 있습니다.', 5, false, @sound)
        _add_tips(@player, @uuid, @players_data, '점유한 땅에서 침대 설치 후 홈 등록이 가능합니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '거주 월드에선 광물 자원을 구할 수 없지만 농사를 할 수 있습니다.', 4, false, @sound)
        @tip_data['residence_join'] += 1
        _update_tip_data(@uuid, @players_data)
        unbind()
      }
    }
    if(!array_index_exists(@tip_data, 'place_diamond_block')) {
      @tip_data['place_diamond_block'] = 0
    }
    if(@tip_data['place_diamond_block'] < 1) {
      bind('block_place', array('id': 'tip.place_diamond_block.'.@player), array('player': @player, 'block': 'DIAMOND_BLOCK'), @event, @player, @uuid, @players_data, @tip_data) {
        if(pworld(@player) == 'spawn_minecraft_residence') {
          @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
          _add_tips(@player, @uuid, @players_data, '인접한 청크를 추가로 점유 하기 위해선 점유 깃발을 인접 청크에 설치해야 합니다.', 5, false, @sound)
          _add_tips(@player, @uuid, @players_data, '점유 깃발은 청금석 블럭을 8개의 다이아몬드로 둘러 조합할 수 있습니다.', 5, false, @sound)
          _add_tips(@player, @uuid, @players_data, '점유를 해제하기 위해선 제거 깃발을 설치해야 합니다.', 4, false, @sound)
          _add_tips(@player, @uuid, @players_data, '제거 깃발은 TNT를 8개의 레드스폰 블럭으로 둘러 조합할 수 있습니다.', 5, false, @sound)
          @tip_data['place_diamond_block'] += 1
          _update_tip_data(@uuid, @players_data)
          unbind()
        }
      }
    }
    if(!array_index_exists(@tip_data, 'place_enchanting_table')) {
      @tip_data['place_enchanting_table'] = 0
    }
    if(@tip_data['place_enchanting_table'] < 3) {
      bind('block_place', array('id': 'tip.place_enchanting_table.'.@player), array('player': @player, 'block': 'ENCHANTING_TABLE'), @event, @player, @uuid, @players_data, @tip_data) {
        if(pworld(@player) == 'spawn_minecraft_residence') {
          @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
          _add_tips(@player, @uuid, @players_data, '설치하신 정수 추출기로 레벨을 소비하여 마법의 정수를 추출 하실 수 있습니다.', 5, false, @sound)
          _add_tips(@player, @uuid, @players_data, '정수 추출기 우클릭 시 30레벨을 소비하며 랜덤한 마법의 정수가 드랍됩니다.', 5, false, @sound)
          _add_tips(@player, @uuid, @players_data, '카테가트 스폰마을의 대장간에서 마법의 정수를 사용하여 도구와 방어구에 마법을 부여할 수 있습니다.', 6, false, @sound)
          @tip_data['place_enchanting_table'] += 1
          _update_tip_data(@uuid, @players_data)
          unbind()
        }
      }
    }
    if(!array_index_exists(@tip_data, 'sow')) {
      @tip_data['sow'] = 0
    }
    if(@tip_data['sow'] < 5) {
      bind('player_interact', array('id': 'tip.sow.'.@player), array('button': 'right', 'player': @player), @event, @player, @uuid, @players_data, @tip_data) {
        if(pworld(@player) == 'spawn_minecraft_residence') {
          @dirts = array(
            'GRASS_BLOCK',
            'DIRT'
          )
          @hoes = array(
            'WOODEN_HOE',
            'GOLDEN_HOE',
            'STONE_HOE',
            'IRON_HOE',
            'DIAMOND_HOE',
            'NETHERITE_HOE'
          )
          if(!is_cancelled() && array_contains(@dirts, @event['block'])) {
            @item = @players_data[@uuid]['item']['main_hand']
            if(!is_null(@item) && array_contains(@hoes, @item['name'])) {
              @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
              _add_tips(@player, @uuid, @players_data, '경작지를 만들기 위해선 경작을 여러 번 시도해야 합니다.', 4, false, @sound)
              _add_tips(@player, @uuid, @players_data, '경작 진행도는 좌측 상단에 표시되며 진행도를 채우면 경작에 성공합니다', 4, false, @sound)
              _add_tips(@player, @uuid, @players_data, '괭이의 경작 강도에 따라 경작 진행 속도가 달라집니다.', 4, false, @sound)
              @tip_data['sow'] += 1
              _update_tip_data(@uuid, @players_data)
              unbind()
            }
          }
        }
      }
    }
    if(!array_index_exists(@tip_data, 'farm')) {
      @tip_data['farm'] = 0
    }
    if(@tip_data['farm'] < 5) {
      bind('block_place', array('id': 'tip.farm.'.@player), array('player': @player), @event, @player, @uuid, @players_data, @tip_data) {
        if(pworld(@player) == 'spawn_minecraft_residence') {
          @crops = array(
            'WHEAT',
            'BEETROOTS',
            'POTATOS',
            'CARROTS',
            'SWEET_BERRY_BUSH',
            'PUMPKIN_STEM',
            'MELON_STEM'
          )
          if(!is_cancelled() && array_contains(@crops, @event['block'])) {
            @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
            _add_tips(@player, @uuid, @players_data, '물병으로 경작지에 물을 주어 수분을 공급할 수 있으며,', 3, false, @sound)
            _add_tips(@player, @uuid, @players_data, '뼛가루로 비료를 주어 영양분을 공급할 수 있습니다.', 3, false, @sound)
            _add_tips(@player, @uuid, @players_data, '수분과 영양분이 없다면 작물이 자라지 않습니다.', 4, false, @sound)
            @tip_data['farm'] += 1
            _update_tip_data(@uuid, @players_data)
            unbind()
          }
        }
      }
    }
    if(!array_index_exists(@tip_data, 'harvest_without_hoe')) {
      @tip_data['harvest_without_hoe'] = 0
    }
    if(@tip_data['harvest_without_hoe'] < 5) {
      bind('block_break', array('id': 'tip.harvest_without_hoe.'.@player), array('player': @player), @event, @player, @uuid, @players_data, @tip_data) {
        if(pworld(@player) == 'spawn_minecraft_residence') {
          @crops = array(
            'WHEAT': 7,
            'BEETROOTS': 3,
            'POTATOS': 7,
            'CARROTS': 7,
            'SWEET_BERRY_BUSH': 3
          )
          @hoes = array(
            'WOODEN_HOE',
            'GOLDEN_HOE',
            'STONE_HOE',
            'IRON_HOE',
            'DIAMOND_HOE',
            'NETHERITE_HOE'
          )
          if(!is_cancelled() && array_index_exists(@crops, @event['block']) && get_blockdata(@event['location'])['age'] == @crops[@event['block']]) {
            @item = @players_data[@uuid]['item']['main_hand']
            if(is_null(@item) || !array_contains(@hoes, @item['name'])) {
              @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
              _add_tips(@player, @uuid, @players_data, '작물을 수확하기 위해선 괭이를 사용해야 합니다.', 4, false, @sound)
              @tip_data['harvest_without_hoe'] += 1
              _update_tip_data(@uuid, @players_data)
              unbind()
            }
          }
        }
      }
    }
    if(!array_index_exists(@tip_data, 'fish')) {
      @tip_data['fish'] = 0
    }
    if(@tip_data['fish'] < 2) {
      bind('player_fish', array('id': 'tip.fish.'.@player), array('player': @player, 'state': 'CAUGHT_FISH'), @event, @player, @uuid, @players_data, @tip_data) {
        @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
        _add_tips(@player, @uuid, @players_data, '낚은 다양한 종류의 물고기들은 조합대에서 손질하여', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '하나의 아이템으로 만들어 인벤토리 공간을 절약할 수 있습니다.', 4, false, @sound)
        @tip_data['fish'] += 1
        _update_tip_data(@uuid, @players_data)
        unbind()
      }
    }
    break()
  case 'over':
    if(!array_index_exists(@tip_data, 'join')) {
      @tip_data['join'] = 0
    }
    if(@tip_data['join'] < 5) {
      bind('player_move', array('id': 'tip.join.'.@player), array('player': @player), @event, @player, @uuid, @players_data, @tip_data) {
        @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
        _add_tips(@player, @uuid, @players_data, '자원 월드에선 다양한 자원을 수집할 수 있습니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '밤에는 많은 몬스터들이 스폰 되며 강력한 몬스터도 존재합니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '자원 월드에서 사망 시, 약 10%의 아이템이 영원히 소실됩니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '홈을 지정할 수 없으며 자원 월드로 이동할 때마다 랜덤 한 곳으로 이동되기 때문에', 5, false, @sound)
        _add_tips(@player, @uuid, @players_data, '다이아몬드 블럭을 구한 후, 거주 월드에 정착하여 아이템을 보관하시는것을 추천드립니다.', 5, false, @sound)
        @tip_data['join'] += 1
        _update_tip_data(@uuid, @players_data)
        unbind()
      }
    }
    if(!array_index_exists(@tip_data, 'start_mine')) {
      @tip_data['start_mine'] = 0
    }
    if(@tip_data['start_mine'] < 3) {
      bind('block_break', array('id': 'tip.start_mine.'.@player), array('player': @player), @event, @player, @uuid, @players_data, @tip_data) {
        @ores = array(
          'COAL_ORE',
          'PETRIFIED_OAK_SLAB',
          'IRON_ORE',
          'LAPIS_ORE',
          'GOLD_ORE',
          'REDSTONE_ORE',
          'DIAMOND_ORE',
          'EMERALD_ORE'
        )
        @pickaxes = array(
          'WOODEN_PICKAXE',
          'GOLDEN_PICKAXE',
          'STONE_PICKAXE',
          'IRON_PICKAXE',
          'DIAMOND_PICKAXE',
          'NETHERITE_PICKAXE'
        )
        if(array_contains(@ores, @event['block'])) {
          @item = @players_data[@uuid]['item']['main_hand']
          if(!is_null(@item) && array_contains(@pickaxes, @item['name'])) {
            @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
            _add_tips(@player, @uuid, @players_data, '광물을 얻기 위해, 채굴을 여러번 시도해야 합니다.', 4, false, @sound)
            _add_tips(@player, @uuid, @players_data, '채광 진행도는 좌측 상단에 표시되며, 진행도를 채우면 광물 채광에 성공합니다', 4, false, @sound)
            _add_tips(@player, @uuid, @players_data, '곡괭이의 채굴 강도에 따라 채광 진행 속도가 달라집니다.', 4, false, @sound)
            @tip_data['start_mine'] += 1
            _update_tip_data(@uuid, @players_data)
            if(@tip_data['start_mine'] >= 3) {
              unbind()
            }
          }
        }
      }
    }
    if(!array_index_exists(@tip_data, 'drop_ranked_mineral')) {
      @tip_data['drop_ranked_mineral'] = 0
    }
    if(@tip_data['drop_ranked_mineral'] < 3) {
      bind('block_break', array('id': 'tip.drop_ranked_mineral.'.@player), array('player': @player), @event, @player, @uuid, @players_data, @tip_data) {
        @ores = array(
          'PETRIFIED_OAK_SLAB',
          'IRON_ORE',
          'GOLD_ORE',
          'DIAMOND_ORE'
        )
        @pickaxes = array(
          'WOODEN_PICKAXE',
          'GOLDEN_PICKAXE',
          'STONE_PICKAXE',
          'IRON_PICKAXE',
          'DIAMOND_PICKAXE',
          'NETHERITE_PICKAXE'
        )
        if(!is_cancelled() && array_contains(@ores, @event['block'])) {
          @item = @players_data[@uuid]['item']['main_hand']
          if(!is_null(@item) && array_contains(@pickaxes, @item['name'])) {
            @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
            _add_tips(@player, @uuid, @players_data, '일부 광물엔 등급이 존재합니다.', 3, false, @sound)
            _add_tips(@player, @uuid, @players_data, '광물의 등급에 따라 무기, 도구, 방어구의 성능에 영향을 줍니다.', 4, false, @sound)
            @tip_data['drop_ranked_mineral'] += 1
            _update_tip_data(@uuid, @players_data)
            if(@tip_data['drop_ranked_mineral'] >= 3) {
              unbind()
            }
          }
        }
      }
    }
    if(!array_index_exists(@tip_data, 'mine_iron_without_copper')) {
      @tip_data['mine_iron_without_copper'] = 0
    }
    if(@tip_data['mine_iron_without_copper'] < 1000) {
      bind('block_break', array('id': 'tip.mine_iron_without_copper.'.@player), array('player': @player, 'block': 'IRON_ORE'), @event, @player, @uuid, @players_data, @tip_data) {
        @item = @players_data[@uuid]['item']['main_hand']
        if(!is_null(@item) && @item['name'] == 'WOODEN_PICKAXE' && !is_null(@item['meta']) && @item['meta']['model'] == 8) {
          @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
          _add_tips(@player, @uuid, @players_data, '철을 채굴하기 위해선 더욱 강력한 곡괭이가 필요합니다!', 4, false, @sound)
          _add_tips(@player, @uuid, @players_data, '구리로 만든 곡괭이라면 철을 채굴할 수 있을 것 같습니다.', 3, false, @sound)
          @tip_data['mine_iron_without_copper'] += 1
          _update_tip_data(@uuid, @players_data)
          if(@tip_data['mine_iron_without_copper'] >= 1000) {
            unbind()
          }
        }
      }
    }
    if(!array_index_exists(@tip_data, 'fish')) {
      @tip_data['fish'] = 0
    }
    if(@tip_data['fish'] < 2) {
      bind('player_fish', array('id': 'tip.fish.'.@player), array('player': @player, 'state': 'CAUGHT_FISH'), @event, @player, @uuid, @players_data, @tip_data) {
        @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
        _add_tips(@player, @uuid, @players_data, '낚은 다양한 종류의 물고기들은 조합대에서 손질하여', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '하나의 아이템으로 만들어 인벤토리 공간을 절약할 수 있습니다.', 4, false, @sound)
        @tip_data['fish'] += 1
        _update_tip_data(@uuid, @players_data)
        unbind()
      }
    }
    break()
  case 'nether':
    if(!array_index_exists(@tip_data, 'join')) {
      @tip_data['join'] = 0
    }
    if(@tip_data['join'] < 1) {
      bind('player_move', array('id': 'tip.join.'.@player), array('player': @player), @event, @player, @uuid, @players_data, @tip_data) {
        @sound = array('sound': 'minecraft:entity.player.levelup', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1.75)
        _add_tips(@player, @uuid, @players_data, '네더 월드에선 강력한 자원을 수집할 수 있습니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '네더 월드엔 특수한 필드효과가 적용됩니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '주기적으로 몸에 지옥불이 붙으며 일부 블럭을 부술 시, 용암이 흘러 나올 수 있습니다.', 5, false, @sound)
        _add_tips(@player, @uuid, @players_data, '지옥의 몬스터들은 받는 피해가 50% 경감됩니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '이 필드효과를 무시하기 위해서는 차가운 속성의 인첸트가 필요합니다.', 4, false, @sound)
        _add_tips(@player, @uuid, @players_data, '지옥 월드에서 사망 시, 약 40%의 아이템이 영원히 소실됩니다.', 4, false, @sound)
        @tip_data['join'] += 1
        _update_tip_data(@uuid, @players_data)
        unbind()
      }
    }
    break()
  }
}

proc _load_tip_data(@player, @uuid, @players_data) {
  @tip_data_path = 'data/'.@uuid.'.json'
  if(!file_exists(@tip_data_path)) {
    create_file(@tip_data_path)
    async_write_file(@tip_data_path, json_encode(array()), 'OVERWRITE')
    @players_data[@uuid]['cache']['tip_data'] = array()
    _bind_tip_events(@player, @uuid, @players_data)
  } else {
    async_read(@tip_data_path, closure(@value) {
      @players_data[@uuid]['cache']['tip_data'] = json_decode(@value)
      _bind_tip_events(@player, @uuid, @players_data)
    })
  }
}