# proc 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @category, @skill, @skill_spec, @point,
# @selected_combat_method, @selected_sowing_method, @selected_harvesting_method, @selected_runes

proc("_apply_loading_by_@skill", @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @selected_combat_method) {
  if(@point > 0 && @skill == @selected_combat_method) {
    # 액티브 설정
    _load_active_skill(@player_data, @uuid, @skill, @point, @skill_spec)
  } else {
    # 액티브 설정
    _reset_active_skill(@player_data, @uuid, @skill)
  }
}