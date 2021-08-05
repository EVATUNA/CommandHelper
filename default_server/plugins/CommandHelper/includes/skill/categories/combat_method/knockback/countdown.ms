# include 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point

proc("_apply_countdown_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point) {
  @active_skill = @player_data['active_skill'][@skill]
  if(@active_skill[2] < @skill_spec['effect_by_point'][@point]['active']['count']) { // 스킬 횟수가 최대 스킬 횟수보다 낮을 시,
    if(@active_skill[0] > 0) { // 쿨타임 있을시 (쿨타임 도중)
      @active_skill[0] -= 1 // 클타임 감소
    } else { //쿨타임 다 달았을 시
      @active_skill[2] += 1 // 횟수 추가
      @active_skill[0] = @skill_spec['effect_by_point'][@point]['active']['cooldown'] // 쿨탐 재설정
    }
  }
}