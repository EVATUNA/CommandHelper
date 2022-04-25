# proc 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @category, @skill, @skill_spec, @point,
# @selected_combat_method, @selected_sowing_method, @selected_harvesting_method, @selected_runes

proc("_apply_loading_by_@skill", @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @selected_combat_method) {
  if(@point > 0 && @skill == @selected_combat_method) {
    # 액티브 설정
    _load_active_skill(@player_data, @uuid, @skill, @point, @skill_spec)
    # 패시브 설정
    @passive_attack_speed = @skill_spec['effect_by_point'][@point]['passive']['attack_speed']
    @modifier = array(
      'attribute': 'GENERIC_ATTACK_SPEED',
      'operation': 'ADD_SCALAR',
      'amount': @passive_attack_speed,
      'name': 'sweeping_passive'
    )
    _remove_all_modifiers(@uuid, 'GENERIC_ATTACK_SPEED', 'sweeping_passive')
    add_entity_attribute_modifier(@uuid, @modifier)
  } else {
    # 액티브 리셋
    _reset_active_skill(@player_data, @uuid, @skill)
    _remove_all_modifiers(@uuid, 'GENERIC_ATTACK_SPEED', 'sweeping_active')
    # 패시브 리셋
    _remove_all_modifiers(@uuid, 'GENERIC_ATTACK_SPEED', 'sweeping_passive')
  }
}