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
  # 대쉬
  @old_ploc = ploc(@player)
  set_timeout(200, closure() {
    @new_ploc = ploc(@player)
    @yaw = get_yaw(@old_ploc, @new_ploc)
    @vector = get_vector(array('yaw': @yaw, 'pitch': 0), 2)
    # TODO 내부 테스트 가능해질때 벡터가 NAN 아닐경우에만 작동 NAN이라면 카운트 다시 +1
    set_pvelocity(@player, @vector)
    play_named_sound(ploc(@player), array('sound': 'entity.bat.takeoff', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1))
  })
}

#if(@active_skill[2] > 0) {
#  @active_skill[2] -= 1
#  @old_ploc = ploc(@player)
#  set_timeout(200, closure() {
#    @new_ploc = ploc(@player)
#    @yaw = get_yaw(@old_ploc, @new_ploc)
#    @vector = get_vector(array('yaw': @yaw, 'pitch': 0), 2)
#    set_pvelocity(@player, @vector)
#    play_named_sound(ploc(@player), array('sound': 'entity.bat.takeoff', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1))
#  })
#  _send_action_msg(@player, @player_data, @skills_spec, @text)
#