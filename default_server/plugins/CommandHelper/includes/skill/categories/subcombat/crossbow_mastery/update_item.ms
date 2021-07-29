# include 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point,
# @item, @vanilla_enchants

proc("_apply_item_update_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point, @item, @vanilla_enchants) {
  if(@item['name'] == 'CROSSBOW') {
    if(@point > 0) {
      @quick_charge = @skill_spec['effect_by_point'][@point]['passive']['quick_charge']
      if(array_index_exists(@vanilla_enchants, 'quick_charge')) {
        @vanilla_enchants['quick_charge']['elevel'] += @quick_charge
      } else {
        @vanilla_enchants['quick_charge'] = array(
          'etype': 'QUICK_CHARGE',
          'elevel': @quick_charge
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