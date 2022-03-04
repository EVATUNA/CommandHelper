@musics_data = array()
@musics_data['spawn'] = json_decode(comp_read("musics/spawn.json"))
@musics_data['residence'] = json_decode(comp_read("musics/residence.json"))
@musics_data['over'] = json_decode(comp_read("musics/over.json"))
@musics_data['nether'] = json_decode(comp_read("musics/nether.json"))
@musics_data['end'] = json_decode(comp_read("musics/end.json"))

proc _play_world_music(@player, @uuid, @players_data, @musics_data) {
  if(ponline(@player) && array_index_exists(@players_data, @uuid)) {
    clear_task(@players_data[@uuid]['cache']['music_remove_task'])
    @music_data = null
    switch(pworld(@player)) {
    case 'spawn':
      @music_data = array_get_rand(@musics_data['spawn'])
      break()
    case 'spawn_minecraft_residence':
      @music_data = array_get_rand(@musics_data['residence'])
      break()
    case 'over':
      @music_data = array_get_rand(@musics_data['over'])
      break()
    case 'nether':
      @music_data = array_get_rand(@musics_data['nether'])
      break()
    case 'end':
      @music_data = array_get_rand(@musics_data['end'])
      break()
    }
    if(!is_null(@music_data)) {
      @music_name = @music_data['name']
      @music_time = @music_data['time']
      @music_volume = @music_data['volume']
      //runas('~console', "/stopsound @player music")
      set_timeout(100, closure() {
        play_named_sound(ploc(@player), array('category': 'MUSIC', 'sound': @music_name, 'volume': @music_volume, 'pitch': 1), array(@player))
        @players_data[@uuid]['cache']['music_remove_task'] = set_timeout(@music_time * 1000, closure() {
          _play_world_music(@player, @uuid, @players_data, @musics_data)
        })
      })
    }
  }
}