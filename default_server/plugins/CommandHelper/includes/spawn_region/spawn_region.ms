if(has_value('golden_pig_data')) {
  store_value('golden_pig_data', 0)
}

bind('region_change', null, null, @event) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_size(@event['toRegions']) > 0) {

    @regions = array(
      //'spawn_rt': '랜덤텔포',
      'tuna24': '튜나24',
      'big_sauna': '사우나',
      'bigtree': '100년 된 참나무', 
      'flowershop': '꽃집',
      'pub': '선술집',
      'waterfall': '폭포',
      'floating_island': '공중 섬'
    )

    @region = @event['toRegions'][0]

    if(@region == 'spawn_rt') {
      runas(@player, '/randomteleport')
    } else if(array_index_exists(@regions, @region)) {
      @region_name = @regions[@region]
      if(@player == 'aaaa__') {
        title(@player, '', @region_name)
      }
      //broadcast(@region_name)
    }
  }
}