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

if(@count > 0) { // 스킬 횟수 있을시
  @count -= 1 // 스킬 횟소 차감
  @duration = @skill_spec['effect_by_point'][@point]['active']['duration'] // 스킬 지속시간 설정
}

#if(@active_skill[2] > 0) {
#  @active_skill[2] -= 1
#  @active_skill[1] = @skill_spec['effect_by_point'][@point]['active']['duration']
#}