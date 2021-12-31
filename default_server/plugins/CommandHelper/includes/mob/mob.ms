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
        broadcast(@mob_reward)

        # 마법레벨 주기
        if(array_index_exists(@mob_reward, 'arcanelevel')) {
          @location = entity_loc(@id)
          _add_arcanelevel_experience(@location, @mob_reward['arcanelevel']['default'], @mob_reward['arcanelevel']['extra'])
        }

        # 튜나레벨 주기
        if(array_index_exists(@mob_reward, 'tunalevel')) {
          _add_tunalevel_experience(@uuid, @player_data, @mob_reward['tunalevel']['default'], @mob_reward['tunalevel']['extra'])
        }

        # 룬, 비법서 등 아이템 드랍

        break()
      }
    }

    //if(@players_data[@uuid]['item']['enchantments']['main_hand'] == '경험') {
    //  modify_event('xp', @event['xp'] * 2) // 경험 인첸트 있을시 2배의 경험치 떨굼
    //  # 파티시스템 만들어지면 경험치 나누어 받는 시스템 만들어야 함
    //}

  }
  # 몹 죽고나서 사라질때 떨구는 경험치 제거
  modify_event('xp', 0)
}

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