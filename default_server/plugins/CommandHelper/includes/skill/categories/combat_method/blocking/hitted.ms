# proc 내부에서 사용 가능한 변수:
# @event, @player_data, @player, @uuid,
# @category, @skill, @skill_spec, @point,
# @attack_cooldown, @attribute_attack_damage, @attribute_attack_speed

proc("_apply_hitted_by_@skill", @event, @player_data, @player, @uuid, @category, @skill, @skill_spec, @point) {
  @active_skill_duration = @player_data['active_skill'][@skill][1]
  if(@active_skill_duration > 0) {
    @damage_multiply = @skill_spec['effect_by_point'][@point]['active']['damage_multiply']
    modify_event('amount', @event['amount'] * @damage_multiply)
  }
}