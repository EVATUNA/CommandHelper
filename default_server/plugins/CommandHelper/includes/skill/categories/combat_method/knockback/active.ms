# include 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skills_spec, @text

proc("_apply_active_by_@skill", @player_data, @player, @uuid, @skill, @skills_spec, @text) {
  @active_skill = @player_data['active_skill'][@skill]
  if(@active_skill[2] > 0) {
    # 대쉬
    if(!@player_data['cache']['is_dash']) {
    @old_ploc = ploc(@player)
      set_timeout(200, closure() {
        @new_ploc = ploc(@player)
        @yaw = get_yaw(@old_ploc, @new_ploc)
        @vector = get_vector(array('yaw': @yaw, 'pitch': 0), 2)
        if(math_const('NaN') != @vector[0]) {
          set_pvelocity(@player, @vector)
          play_named_sound(ploc(@player), array('sound': 'entity.bat.takeoff', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1))
          @active_skill[2] -= 1
          _send_action_msg(@player, @player_data, @skills_spec, @text)
          _save_active_skill(@uuid, @skill, @active_skill)
        }
        @player_data['cache']['is_dash'] = false
      })
    }
    @player_data['cache']['is_dash'] = true
  }
}