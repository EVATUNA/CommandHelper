# proc 내부에서 사용 가능한 변수:
# @event, @player_data, @player, @uuid,
# @category, @skill, @skill_spec, @point,
# @attack_cooldown, @attribute_attack_damage, @attribute_attack_speed

proc("_apply_attacking_by_@skill", @event, @player_data, @player, @uuid, @category, @skill, @skill_spec, @point, @attack_cooldown, @attribute_attack_damage, @attribute_attack_speed) {
  @cleaving_multiply = @skill_spec['effect_by_point'][@point]['passive']['crit_multiply']
  @active_skill_duration = @player_data['active_skill'][@skill][1]
  if(round(@event['amount'], 5) == round(@attribute_attack_damage * 1.5, 5)) { // 크리티컬 공격 했을시,
    @event['amount'] = @attribute_attack_damage * @cleaving_multiply
  } else { // 크리티컬 공격 안했을시,
    if(@active_skill_duration > 0) { // 액티브 스킬 발동중일시 크리 공격 아니라도 모든 공격에 크리 배수 적용
      @event['amount'] *= @cleaving_multiply
    }
  }
}