# proc 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @category, @skill, @skill_spec, @point,
# @selected_combat_method, @selected_sowing_method, @selected_harvesting_method, @selected_runes

proc("_apply_loading_by_@skill", @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @selected_combat_method, @selected_sowing_method, @selected_harvesting_method, @selected_runes) {
  @max_health = @skill_spec['effect_by_point'][@point]['passive']['max_health']
  set_entity_attribute_base(@uuid, 'GENERIC_MAX_HEALTH', @max_health)
}