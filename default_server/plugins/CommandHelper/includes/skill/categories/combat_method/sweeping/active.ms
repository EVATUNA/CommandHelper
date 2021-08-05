# include 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point

proc("_apply_active_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point) {
  @active_skill = @player_data['active_skill'][@skill]
  if(@active_skill[2] > 0) { // 스킬 횟수 있을시
    @active_skill[2] -= 1 // 스킬 횟소 차감
    @active_skill[1] = @skill_spec['effect_by_point'][@point]['active']['duration'] // 스킬 지속시간 설정
    # 어트리뷰트 설정
    @active_attack_speed = @skill_spec['effect_by_point'][@point]['active']['attack_speed']
    @modifier = array(
      'attribute': 'GENERIC_ATTACK_SPEED',
      'operation': 'ADD_SCALAR',
      'amount': @active_attack_speed,
      'name': 'sweeping_active'
    )
    add_entity_attribute_modifier(@uuid, @modifier)
  }
}