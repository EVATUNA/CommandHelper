@musics_data = array()
@musics_data['spawn'] = json_decode(comp_read("musics/spawn.json"))

proc _play_spawn_music(@player, @uuid, @musics_data) {
  
  @queue_name = "music.@uuid"
  queue_clear(@queue_name)
  if(pworld(@player) == 'spawn') {
    @music_data = array_get_rand(@musics_data['spawn'])
    @music_name = @music_data['name']
    @music_time = @music_data['time']
    @music_volume = @music_data['volume']
    @play_closure = closure() {
      play_named_sound(ploc(@player), array('category': 'MUSIC', 'sound': @music_name, 'volume': @music_volume, 'pitch': 1), array(@player))
    }
    set_timeout(100, closure() {
      queue_push(@play_closure, @queue_name)
      queue_delay(@music_time * 1000, @queue_name)
      @recurse_closure = closure(
        //runas('~console', "/stopsound @player music")
        _play_spawn_music(@player, @uuid, @musics_data)
      )
      queue_push(@recurse_closure, @queue_name)
    })


  }
}

bind('world_changed', null, null, @event, @musics_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  switch(@event['to']) {
  case 'spawn':
    set_timeout(1000, closure() {
      _play_spawn_music(@player, @uuid, @musics_data)
    })
    break()
  }
}