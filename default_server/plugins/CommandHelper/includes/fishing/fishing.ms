@fishing_tasks = array()
export('fishing_tasks', @fishing_tasks)

@fishing_hooks = array()
export('fishing_hooks', @fishing_hooks)

proc _choose_fish(@player, @uuid, @hook) {
  // 물고기 선정 및 @fishing_data 세팅
  @fishing_data = array(
    'hook': @hook,
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
      'less': -0.5,// -1.5
      'match': 0.5,
      'over': -10.0
    )
  )
  _update_tag(@hook, @fishing_data)
  return(@fishing_data)
}

proc _fishing_start(@player, @uuid, @hook, @fishing_hooks, @fishing_tasks, @text) {
  // 물고기 선정
  @fishing_data = _choose_fish(@player, @uuid, @hook)
  if(true) { // 물고기 선정이 올바르게 되었을 시
    // 낚시 시작 사운드, 파티클
    @hloc = entity_loc(@hook)
    play_named_sound(@hloc, array('sound': 'minecraft:entity.generic.splash', 'category': 'AMBIENT', 'volume': 0.2, 'pitch': 0.9 + rand() * 0.6))
    play_named_sound(@hloc, array('sound': 'minecraft:entity.fishing_bobber.splash', 'category': 'AMBIENT', 'volume': 0.2, 'pitch': 0.9 + rand() * 0.6))
    @pos = array(
      'x': @hloc['x'],
      'y': @hloc['y'],
      'z': @hloc['z'],
    )
    mom_playerparticle(@uuid, 'WATER_BUBBLE', @pos['x'], @pos['y'], @pos['z'], rand(1,3), 0.2, 0.0, 0.2, 0.0)
    @pos['y'] += 0.2
    mom_playerparticle(@uuid, 'WATER_SPLASH', @pos['x'], @pos['y'], @pos['z'], rand(1,3), 0.2, 0.0, 0.2, 0.0)
    // interval 동작
    @progress_bars = array('\ueb20', '\ueb21', '\ueb22', '\ueb23', '\ueb24', '\ueb25', '\ueb26', '\ueb27', '\ueb28', '\ueb29', '\ueb2a', '\ueb2b', '\ueb2c', '\ueb2d', '\ueb2e', '\ueb2f', '\ueb30', '\ueb31', '\ueb32', '\ueb33', '\ueb34')
    @task_id = set_interval(100, closure() {
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
          _fishing_end(@player, @uuid, @fishing_data, @fishing_hooks, @fishing_tasks, @text)
        } else if(@fishing_data['progress'] < 0) {
          tmsg(@player, '놓침')
          _fishing_end(@player, @uuid, @fishing_data, @fishing_hooks, @fishing_tasks, @text)
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
        _fishing_end(@player, @uuid, @fishing_data, @fishing_hooks, @fishing_tasks, @text)
      }
    })
    @fishing_data['task_id'] = @task_id
    _update_tag(@hook, @fishing_data)

    @fishing_tasks[@uuid] = @task_id
  }
}

proc _fishing_end(@player, @uuid, @fishing_data, @fishing_hooks, @fishing_tasks, @text) {
  // 낚싯찌 처리
  @hook = @fishing_data['hook']
  if(entity_exists(@hook)) { entity_remove(@hook) }
  if(array_index_exists(@fishing_hooks, @uuid)) { array_remove(@fishing_hooks, @uuid) }
  // task 처리
  @task_id = @fishing_data['task_id']
  clear_task() //clear_task(@task_id)
  array_remove_values(@fishing_tasks, @task_id)
  // 플레이어 UI 처리, 아이템 처리
  _set_sidebar(@uuid, 4, '', @text)
  set_pcooldown(@player, 'FISHING_ROD', 20)
}

proc _reel_in(@player, @uuid, @hook, @fishing_data, @fishing_hooks, @fishing_tasks, @text) {
  @fishing_data['location'] += 10
  if(@fishing_data['location'] > 100) {@fishing_data['location'] = 100}
  _update_tag(@hook, @fishing_data)
  set_entity_velocity(@hook, array(0, 0.01, 0))
  // 위치 선언
  @hloc = entity_loc(@hook)
  @ploc = ploc(@player)
  // 사운드
  if(rand() < 0.25) {
    play_named_sound(@hloc, array('sound': 'minecraft:entity.generic.splash', 'category': 'AMBIENT', 'volume': 0.2, 'pitch': 0.9 + rand() * 0.6))
  }
  if(rand() < 0.125) {  
    play_named_sound(@hloc, array('sound': 'minecraft:entity.fishing_bobber.splash', 'category': 'AMBIENT', 'volume': 0.2, 'pitch': 0.9 + rand() * 0.6))
  }
  play_named_sound(@ploc, array('sound': 'minecraft:item.crossbow.loading_start', 'category': 'PLAYERS', 'volume': 1, 'pitch': 1.15 + rand() * 0.1))
  play_named_sound(@ploc, array('sound': 'minecraft:item.crossbow.loading_middle', 'category': 'PLAYERS', 'volume': 0.5, 'pitch': 1.15 + rand() * 0.1))
  // 파티클
  @pos = array(
    'x': @hloc['x'],
    'y': @hloc['y'],
    'z': @hloc['z'],
  )
  mom_playerparticle(@uuid, 'WATER_BUBBLE', @pos['x'], @pos['y'], @pos['z'], rand(1,3), 0.2, 0.0, 0.2, 0.0)
  @pos['y'] += 0.2
  mom_playerparticle(@uuid, 'WATER_SPLASH', @pos['x'], @pos['y'], @pos['z'], rand(1,3), 0.2, 0.0, 0.2, 0.0)
}

bind('player_fish', null, null, @event, @players_data, @fishing_hooks, @fishing_tasks, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  @hook = @event['hook']
  if(entity_exists(@hook)) {
    @is_fishing = false
    @fishing_data = _get_tag(@hook)
    if(!is_null(@fishing_data)) {
      @task_id = @fishing_data['task_id']
      if(array_contains(@fishing_tasks, @task_id)) {
        @is_fishing = true
      }
    }
    if(@event['state'] == 'FISHING') {
      @fishing_hooks[@uuid] = @hook
    } else if(!@is_fishing && @event['state'] == 'BITE') {
      //cancel()
      //broadcast(@event['caught'])
      _fishing_start(@player, @uuid, @hook, @fishing_hooks, @fishing_tasks, @text)
    } else if(@is_fishing && (@event['state'] == 'REEL_IN' || @event['state'] == 'CAUGHT_FISH')) {
      cancel()
      //broadcast(entity_spec(@event['caught']))
      _reel_in(@player, @uuid, @hook, @fishing_data, @fishing_hooks, @fishing_tasks, @text)
    } else if(!@is_fishing && @event['state'] == 'REEL_IN') {
      if(array_index_exists(@fishing_hooks, @uuid)) { array_remove(@fishing_hooks, @uuid) }
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