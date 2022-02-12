/*
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
      }
    })
  }
}

bind('entity_death', null, null, @event, @players_data, @mob_rewards) {
  if(array_index_exists(@event['cause'],'damager') && ponline(@event['cause']['damager'])) {
    # 플레이어에 의하여 죽을시 추가 보상 (마법레벨, 튜나레벨, 룬, 비법서)
    @player = @event['cause']['damager']
    @uuid = puuid(@player)
    @player_data = @players_data[@uuid] // 죽인 플레이어의 데이터 // 나중에 파티 시스템 생기면 각각의 플레이어 데이터 구해서 튜나레벨 줘야 함

    @id = @event['id']
    @target_name = get_mob_name(@id)
    if(@target_name == '') {
      @target_name = entity_type(@id)
    }

    foreach(@namespace: @mob_reward in @mob_rewards) {
      @splited_namespace = split(':', @namespace)
      @category = @splited_namespace[0]
      @mob_name = @splited_namespace[1]

      if(@mob_name == @target_name) {
        //if(@players_data[@uuid]['item']['enchantments']['main_hand'] == '경험') {
        //  modify_event('xp', @event['xp'] * 2) // 경험 인첸트 있을시 2배의 경험치 떨굼
        //  # 파티시스템 만들어지면 경험치 나누어 받는 시스템 만들어야 함
        //}
        # 마법레벨 주기
        if(array_index_exists(@mob_reward, 'arcanelevel')) {
          @location = entity_loc(@id)
          if(@players_data[@uuid]['item']['enchantments']['main_hand'] == '경험') {
            _add_arcanelevel_experience(@location, @mob_reward['arcanelevel']['default'], @mob_reward['arcanelevel']['extra'])
            _add_arcanelevel_experience(@location, @mob_reward['arcanelevel']['default'], @mob_reward['arcanelevel']['extra'])
          } else {
            _add_arcanelevel_experience(@location, @mob_reward['arcanelevel']['default'], @mob_reward['arcanelevel']['extra'])
          }
        }
        
        # 튜나레벨 주기
        if(array_index_exists(@mob_reward, 'tunalevel')) {
          _add_randed_tunalevel_experience(@uuid, @player_data, @mob_reward['tunalevel']['default'], @mob_reward['tunalevel']['extra'], @text)
        }

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
        
        # 포리치 종료
        break()
      }
    }


  }
  # 몹 죽고나서 사라질때 떨구는 경험치 제거
  modify_event('xp', 0)
}
*/

# 스폰된 몹 들 입고있는 아이템 떨구지 안토록 수정
bind('creature_spawn', null, null, @event) {
  @uuid = @event['id']
  set_equipment_droprates(@uuid, array(
    'HELMET': 0,
    'CHESTPLATE': 0,
    'LEGGINGS': 0,
    'BOOTS': 0,
    'WEAPON': 0,
    'OFF_HAND': 0
  ))
}