# proc 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point,
# @item, @vanilla_enchants

proc("_apply_item_update_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point, @item, @vanilla_enchants) {
  #if(@item['name'] == 'SHIELD') {
  #  @unbreaking = @skill_spec['effect_by_point'][@point]['passive']['unbreaking']
  #  if(array_index_exists(@vanilla_enchants, 'unbreaking')) {
  #    @vanilla_enchants['unbreaking']['elevel'] += @unbreaking
  #  } else {
  #    @vanilla_enchants['unbreaking'] = array(
  #      'etype': 'DURABILITY',
  #      'elevel': @unbreaking
  #    )
  #  }
  #}
}