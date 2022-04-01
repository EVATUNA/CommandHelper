# proc 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point,
# @item, @vanilla_enchants

proc("_apply_item_update_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point, @item, @vanilla_enchants) {
  if(@item['name'] == 'SHIELD' && array_index_exists(@vanilla_enchants, 'unbreaking', 'elevel')) {

    @unbreaking = @vanilla_enchants['unbreaking']['elevel'] + 1
    @unbreaking_multiply = @skill_spec['effect_by_point'][@point]['passive']['unbreaking_multiply']

    @vanilla_enchants['unbreaking'] = array(
      'etype': 'DURABILITY',
      'elevel': integer(@unbreaking * @unbreaking_multiply - 1)
    )
  }
}