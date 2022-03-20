bind('player_fish', null, null, @event, @players_data, @text) {
  if(@event['state'] == 'CAUGHT_FISH') {
    @player = @event['player']
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      @player_data = @players_data[@uuid]
      @xp = integer(@event['xp'] / 2)
      modify_event('xp', @xp)
      _give_tunalevel_random_experience(@uuid, @player_data, 0, integer(@xp / 2), @text)
    }
  }
}