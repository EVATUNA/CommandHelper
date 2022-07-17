proc _fishing_start(@player, @uuid, @hook) {
  // 물고기 선정 및 @fishing_data 세팅
  @fishing_data = array(
    'fish': 'test',

    'progress': 20.0,
    'location': 0.0,

    'moving_speed': array(
      'default': 3.0,
      'deviation': array(
        'default': 2.0,
        'multiply_by_progress': 5.0,
        'multiply_by_location': array(
          'less': 0.0,
          'match': 3.0,
          'over': -2.0
        )
      )
      //min 2.5 max 7.5
    ),

    'power': array(
      'less': -1.5,
      'match': 0.5,
      'over': -10.0
    )
  )
  _update_tag(@hook, @fishing_data)

  @text = import('text')
  @progress_bars = array('\ueb20', '\ueb21', '\ueb22', '\ueb23', '\ueb24', '\ueb25', '\ueb26', '\ueb27', '\ueb28', '\ueb29', '\ueb2a', '\ueb2b', '\ueb2c', '\ueb2d', '\ueb2e', '\ueb2f', '\ueb30', '\ueb31', '\ueb32', '\ueb33', '\ueb34')
  // task 생성
  set_interval(100, closure() {
    
    if(entity_exists(@hook)) {
      @fishing_data = _get_tag(@hook)
      
      if(@fishing_data['location'] < 60) {
        @fishing_data['progress'] += @fishing_data['power']['less']
        @deviation_multiply_by_location = @fishing_data['moving_speed']['deviation']['multiply_by_location']['less']
      } else if(@fishing_data['location'] < 90) {
        @fishing_data['progress'] += @fishing_data['power']['match']
        @deviation_multiply_by_location = @fishing_data['moving_speed']['deviation']['multiply_by_location']['match']
      } else {
        @fishing_data['progress'] += @fishing_data['power']['over']
        @deviation_multiply_by_location = @fishing_data['moving_speed']['deviation']['multiply_by_location']['over']
      }
      
      if(@fishing_data['progress'] > 100) {
        tmsg(@player, '잡음')
        _set_sidebar(@uuid, 4, '', @text)
        clear_task()
        entity_remove(@hook)
      } else if(@fishing_data['progress'] < 0) {
        tmsg(@player, '놓침')
        _set_sidebar(@uuid, 4, '', @text)
        
        clear_task()
        entity_remove(@hook)
      } else {
        @location_index = integer(@fishing_data['location'] * 0.5)
        @progress_index = integer(@fishing_data['progress'] * 0.2)
        @location_space = -62 + @location_index
        @progress_bar = @progress_bars[@progress_index]
        _set_sidebar(@uuid, 4, color('#fc8080').@text['space_fonts']['space.-32'].'\ue3f9'.@text['space_fonts']['space.'.@location_space].'\ue3fa'.@text['space_fonts']['space.-19'].@progress_bar, @text)
        
        @deviation = @fishing_data['moving_speed']['deviation']['default'] + @fishing_data['moving_speed']['deviation']['multiply_by_progress'] * @fishing_data['progress'] * 0.01 + @deviation_multiply_by_location
        if(@deviation < 0) { @deviation = 0}

        @moving_speed = @fishing_data['moving_speed']['default'] + @deviation * (1 - 2 * rand())
        //@moving_speed = @fishing_data['moving_speed']['min'] + (@fishing_data['moving_speed']['max'] - @fishing_data['moving_speed']['min']) * rand()
        if(@moving_speed < 0) {@moving_speed = 0}

        @fishing_data['location'] -= @moving_speed
        if(@fishing_data['location'] < 0) {@fishing_data['location'] = 0}

        _update_tag(@hook, @fishing_data)
      }

      
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