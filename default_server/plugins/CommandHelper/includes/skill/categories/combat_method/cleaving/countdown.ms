# include 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point

proc("_apply_countdown_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point) {
  @active_skill = @player_data['active_skill'][@skill]
  if(@active_skill[2] == 0) {
    if(@active_skill[1] > 0) { // 스킬 지속시간 있을시
      @active_skill[1] -= 1 // 지속 시간 감소
      if(@active_skill[1] == 0) { //지속 시간 다 줄어들었을시
        @ploc = ploc(@player)
        @ploc['y'] += 1.5
        play_named_sound(@ploc, array('sound': 'minecraft:entity.illusioner.cast_spell', 'category': 'PLAYERS', 'volume': 1, 'pitch': 0.5), @player)
        mom_playerparticle(@uuid, 'SPELL_WITCH', @ploc['x'], @ploc['y'], @ploc['z'], 10, 0.05, 0.25, 0.05, 1.0)
        @active_skill[0] = @skill_spec['effect_by_point'][@point]['active']['cooldown'] // 쿨탐 재설정
      }
    } else { // 스킬 지속시간 없을시 (쿨타임 중일시)
      if(@active_skill[0] > 0) { // 쿨타임 있을시 (쿨타임 도중)
        @active_skill[0] -= 1 // 쿨타임 감소
      } else { //쿨타임 다 달았을 시
        @active_skill[2] = 1 // 스킬 횟수 설정
      }
    }
  }
}