# include 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point,
# @item, @vanilla_enchants

proc("_apply_item_update_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point, @item, @vanilla_enchants) {
  if(@item['name'] == 'BOW') {
    if(@point > 0) {
      @power = @skill_spec['effect_by_point'][@point]['passive']['power']
      if(array_index_exists(@vanilla_enchants, 'power')) {
        @vanilla_enchants['power']['elevel'] += @power
      } else {
        @vanilla_enchants['power'] = array(
          'etype': 'ARROW_DAMAGE',
          'elevel': @power
        )
      }
      @unbreaking = @skill_spec['effect_by_point'][@point]['passive']['unbreaking']
      if(array_index_exists(@vanilla_enchants, 'unbreaking')) {
        @vanilla_enchants['unbreaking']['elevel'] += @unbreaking
      } else {
        @vanilla_enchants['unbreaking'] = array(
          'etype': 'DURABILITY',
          'elevel': @unbreaking
        )
      }
    }
  }
}