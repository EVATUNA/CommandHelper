bind('region_change', null, null, @event) {
  @player = @event['player']
  if(array_size(@event['toRegions']) > 0) {

    @regions = array(
      //'spawn_rt': '랜덤텔포',
      'tuna24': '튜나24',
      'tunapczone': '튜나 피시방',
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
      //broadcast(@region_name)
    }
  }
}