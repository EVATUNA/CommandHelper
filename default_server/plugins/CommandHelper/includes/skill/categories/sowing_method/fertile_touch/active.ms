# include 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point

proc("_apply_active_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point) {
  @active_skill = @player_data['active_skill'][@skill]
  if(@active_skill[2] > 0) { // 스킬 횟수 있을시
    @active_skill[2] -= 1 // 스킬 횟소 차감
    @active_skill[1] = @skill_spec['effect_by_point'][@point]['active']['duration'] // 스킬 지속시간 설정
    
    @ploc = ploc(@player)
    @ploc['y'] += 1.5
    play_named_sound(@ploc, array('sound': 'minecraft:entity.illusioner.cast_spell', 'category': 'PLAYERS', 'volume': 1, 'pitch': 0.675), @player)
    mom_playerparticle(@uuid, 'SPELL_WITCH', @ploc['x'], @ploc['y'], @ploc['z'], 10, 0.05, 0.25, 0.05, 1.0)
    # 액티브 스킬 저장
    _save_active_skill(@uuid, @skill, @active_skill)
  }
}