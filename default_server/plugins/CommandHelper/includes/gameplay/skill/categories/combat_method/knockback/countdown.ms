# include 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point,
# @active_skill

# active_skill index:
# 0 - countdown
@countdown = @active_skill[0]
# 1 - duration
@duration = @active_skill[1]
# 2 - count
@count = @active_skill[2]
# 3 - energy
# 4 - is_activated

if(@count < @skill_spec['effect_by_point'][@point]['active']['count']) { // 스킬 횟수가 최대 스킬 횟수보다 낮을 시,
  if(@countdown > 0) { // 쿨타임 있을시 (쿨타임 도중)
    @countdown -= 1 // 클타임 감소
  } else { //쿨타임 다 달았을 시
    @count += 1 // 횟수 추가
    @countdown = @skill_spec['effect_by_point'][@point]['active']['cooldown'] // 쿨탐 재설정
  }
}

#if(@active_skill[2] < @skill_spec['effect_by_point'][@point]['active']['count']) {
#  if(@active_skill[0] > 0) {
#    @active_skill[0] -= 1
#  } else {
#    @active_skill[2] += 1
#    @active_skill[0] = @skill_spec['effect_by_point'][@point]['active']['cooldown']
#  }
#}