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
    if(!array_index_exists(@tip_data, 'sow')) {
      @tip_sow = 0
    } else {
      @tip_sow = @tip_data['sow']
    }
    if(@tip_sow < 1) {
      #
    }
    if(!array_index_exists(@tip_data, 'harvest')) {
      @tip_harvest = 0
    } else {
      @tip_harvest = @tip_data['harvest']
    }
    if(@tip_harvest < 5) {
      #
    }
    break()
  case 'over':
    if(!array_index_exists(@tip_data, 'mine_iron_without_copper')) {
      @tip_data['mine_iron_without_copper'] = 0
    }
    if(@tip_data['mine_iron_without_copper'] < 3) {
      bind('block_break', array('id': 'tip_mine_iron_without_copper'), array('player': @player, 'block': 'IRON_ORE'), @event, @player, @uuid, @players_data, @tip_data) {
        @item = @players_data[@uuid]['item']['main_hand']
        if(!is_null(@item) && @item['name'] == 'WOODEN_PICKAXE' && !is_null(@item['meta']) && @item['meta']['model'] == 8) {
          _add_tips(@player, @uuid, @players_data, '철을 채광하기 위해선 구리 곡괭이가 필요합니다', 5, false)
          @tip_data['mine_iron_without_copper'] += 1
          _update_tip_data(@uuid, @players_data)
          if(@tip_data['mine_iron_without_copper'] >= 3) {
            unbind()
          }
        }
      }
    }
    break()
  case 'nether':
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