proc _fishing_start(@player, @uuid, @hook) {
  // 물고기 선정 및 @fishing_data 세팅
  @fishing_data = array(
    'fish': 'test',
    'health': 20.0,
    'escape': 20.0,
    'location': 0.0,
    'escape_power': array(
      'min': 2.5,
      'max': 5
    )
  )
  _update_tag(@hook, @fishing_data)
  tmsg(@player, 'start')

  set_interval(100, closure() {
    
    if(entity_exists(@hook)) {
      @fishing_data = _get_tag(@hook)
      @escape_power = @fishing_data['escape_power']['min'] + (@fishing_data['escape_power']['max'] - @fishing_data['escape_power']['min']) * rand()
      if(@escape_power < 0) {@escape_power = 0}
      @fishing_data['location'] -= @escape_power
      if(@fishing_data['location'] < 0) {@fishing_data['location'] = 0}
      _update_tag(@hook, @fishing_data)
      tmsg(@player, round(@fishing_data['location'], 3))
    } else {
      tmsg(@player, 'end (task)')
      clear_task()
    }
  })
}

proc _reel_in(@player, @uuid, @hook, @fishing_data) {
  @fishing_data['location'] += 10
  if(@fishing_data['location'] > 100) {@fishing_data['location'] = 100}
  _update_tag(@hook, @fishing_data)
  tmsg(@player, round(@fishing_data['location'], 3))
}

bind('player_fish', null, null, @event, @players_data, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  @hook = @event['hook']
  if(entity_exists(@hook)) {
    @fishing_data = _get_tag(@hook)
    if(is_null(@fishing_data) && @event['state'] == 'CAUGHT_FISH') {
      cancel()
      _fishing_start(@player, @uuid, @hook)
    } else if(!is_null(@fishing_data) && (@event['state'] == 'REEL_IN' || @event['state'] == 'CAUGHT_FISH')) {
      cancel()
      _reel_in(@player, @uuid, @hook, @fishing_data)
      //우클(REEL_IN) 판정
    }
  }
  
  //broadcast(@event)
  //if(@event['state'] == 'CAUGHT_FISH') {
  //  @player = @event['player']
  //  @uuid = puuid(@player)
  //  if(array_index_exists(@players_data, @uuid)) {
  //    @player_data = @players_data[@uuid]
  //    @xp = integer(@event['xp'] / 2)
  //    modify_event('xp', @xp)
  //    _give_tunalevel_random_experience(@uuid, @player_data, 0, @event['xp'] / 3, @text)
  //  }
  //}
}