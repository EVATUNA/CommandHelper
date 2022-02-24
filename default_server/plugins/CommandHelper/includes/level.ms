## 참치 레벨 데이터 관리
# 레벨 데이터 get
proc _get_tunalevel_data(@player_data) {
  @skill_manager = @player_data['skill_manager']
  @tunalevel_data = array(
    'levels': @skill_manager[0],
    'points': @skill_manager[1]
  )
  return(@tunalevel_data)
}

# 튜나 레벨 HUD
proc _replace_tunalevel_text(@tunalevel) {
  @background = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      @tunalevel, '0', '\uf802\uef10\uf801'
                    ), '1', '\uf802\uef11\uf801'
                  ), '2', '\uf802\uef12\uf801'
                ), '3', '\uf802\uef13\uf801'
              ), '4', '\uf802\uef14\uf801'
            ), '5', '\uf802\uef15\uf801'
          ), '6', '\uf802\uef16\uf801'
        ), '7', '\uf802\uef17\uf801'
      ), '8', '\uf802\uef18\uf801'
    ), '9', '\uf802\uef19\uf801'
  )
  @text = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      @tunalevel, '0', '\uef00\uf801'
                    ), '1', '\uef01\uf801'
                  ), '2', '\uef02\uf801'
                ), '3', '\uef03\uf801'
              ), '4', '\uef04\uf801'
            ), '5', '\uef05\uf801'
          ), '6', '\uef06\uf801'
        ), '7', '\uef07\uf801'
      ), '8', '\uef08\uf801'
    ), '9', '09\uf801'
  )
  @nsf = string_multiply('\uF804', length(@tunalevel))
  @tunalevel_text = '\uef1c\uf801'.@background.'\uf801'.@nsf.'\uf808\uf801'.'\uef1b\uf801'.@text
  return(@tunalevel_text)
}
proc _show_tunalevel(@uuid, @player_data, @text) {
  @tunalevel = @player_data['skill_manager'][0]
  @experience = @player_data['skill_manager'][1]
  @max_experience = _get_max_experience(@tunalevel)
  # bar
  @bars = array(
    '\uee60', '\uee61', '\uee62', '\uee63', '\uee64', '\uee65', '\uee66', '\uee67', '\uee68', '\uee69', '\uee6a', '\uee6b', '\uee6c', '\uee6d', '\uee6e', '\uee6f',
    '\uee70', '\uee71', '\uee72', '\uee73', '\uee74', '\uee75', '\uee76', '\uee77', '\uee78', '\uee79', '\uee7a', '\uee7b', '\uee7c', '\uee7d', '\uee7e', '\uee7f',
    '\uee80', '\uee81', '\uee82', '\uee83', '\uee84', '\uee85', '\uee86', '\uee87', '\uee88', '\uee89', '\uee8a', '\uee8b', '\uee8c', '\uee8d', '\uee8e', '\uee8f',
    '\uee90', '\uee91', '\uee92', '\uee93', '\uee94', '\uee95', '\uee96', '\uee97', '\uee98', '\uee99', '\uee9a', '\uee9b', '\uee9c', '\uee9d', '\uee9e', '\uee9f',
    '\ueea0', '\ueea1', '\ueea2', '\ueea3', '\ueea4', '\ueea5', '\ueea6', '\ueea7', '\ueea8', '\ueea9', '\ueeaa', '\ueeab', '\ueeac', '\ueead', '\ueeae', '\ueeaf'
  )
  @bar_index = integer((@experience / @max_experience) * 80)
  @bar = @bars[@bar_index]
  # level
  @tunalevel_text = _replace_tunalevel_text(@tunalevel)
  _set_sidebar(@uuid, 5, color('#fd0000').@text['space_fonts']['space.-92'].@bar.@text['space_fonts']['space.-83'].@tunalevel_text, @text)
  set_placeholders(player(@uuid), 'tunalevel')
}

# 레벨 데이터 set
proc _set_tunalevel(@uuid, @player_data, @tunalevel_data, @text) {
  @skill_manager = @player_data['skill_manager']
  @skill_manager[0] = @tunalevel_data['levels']
  @skill_manager[1] = @tunalevel_data['points']
  _set_skill_manager(@uuid, @skill_manager)
  _show_tunalevel(@uuid, @player_data, @text)
}

# 플레이스홀더
register_placeholder_hook('player', closure(@player, @placeholder){
  if(is_null(@player)) {
    return("")
  }
  if(@placeholder == 'tunalevel') {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      @level = @players_data[@uuid]['skill_manager'][0]
      switch(integer(@level/10)) {
      case 0:
        @color = '§a'
        break()
      case 1:
        @color = '§e'
        break()
      case 2:
        @color = '§6'
        break()
      case 3:
        @color = '§c'
        break()
      case 4:
        @color = '§d'
        break()
      case 5:
        @color = '§5'
        break()
      case 6:
        @color = '§9'
        break()
      case 7:
        @color = '§b'
        break()
      case 8:
        @color = '§f'
        break()
      default:
        @color = '§7'
        break()
      }
      @text = @color.@level
      @return = @text
    } else {
      @return = '-'
    }
    return(@return)
  }
});

# 튜나레벨 맥스 경치 get 함수
proc _get_max_experience(@level) {
  if(@level <= 20) {
    @max_experience = integer(round(1.25 ** (@level + 1) * 50))
  } else {
    @max_experience = integer(round(4770 * 1.25 ** (@level + 1 - 21)))
  }
  @max_experience = integer(@max_experience * 1.5)
  return(@max_experience)
}

# 경치 추가 계산
proc _get_added_tunalevel_data(@tunalevel_data, @adding_tunalevel_data) {
  @tunalevel_data['levels'] += @adding_tunalevel_data['levels']
  @adding_tunalevel_data['levels'] = 0
  @max_experience = _get_max_experience(@tunalevel_data['levels'])
  @new_experience = @tunalevel_data['points'] + @adding_tunalevel_data['points']
  if(@new_experience >= @max_experience) {
    @adding_tunalevel_data['levels'] += 1
    @adding_tunalevel_data['points'] -= (@max_experience - @tunalevel_data['points'])
    @tunalevel_data['points'] = 0
    @tunalevel_data = _get_added_tunalevel_data(@tunalevel_data, @adding_tunalevel_data)
  } else {
    @tunalevel_data['points'] += @adding_tunalevel_data['points']
  }
  return(@tunalevel_data)
}

# 경치 추가
proc _add_tunalevel(@uuid, @player_data, @adding_tunalevel_data, @text) {
  @tunalevel_data = _get_tunalevel_data(@player_data)
  @added_tunalevel_data = _get_added_tunalevel_data(@tunalevel_data, @adding_tunalevel_data)
  _set_tunalevel(@uuid, @player_data, @added_tunalevel_data, @text)
}

# 튜나레벨 커맨드
proc _tunalevel_command(@command, @player, @args, @text, @players_data) {
  if(array_size(@args) == 4) {
    @target_name = @args[1]
    if(ponline(@target_name)) {
      @target_uuid = puuid(@target_name)
      @player_data = @players_data[@target_uuid]
      @amount = integer(@args[2])
      switch(@args[0]) {
      case 'add':
        switch(@args[3]) {
        case 'levels':
          @adding_tunalevel_data = array(
            'levels': @amount,
            'points': 0
          )
          _add_tunalevel(@target_uuid, @player_data, @adding_tunalevel_data, @text)
          break()
        case 'points':
          @adding_tunalevel_data = array(
              'levels': 0,
              'points': @amount
          )
          _add_tunalevel(@target_uuid, @player_data, @adding_tunalevel_data, @text)
          break()
        default:
          tmsg(@player, @text['prefix']['warn'].color('gray').' 명령어의 4번째 인자는 levels 또는 points이여야 합니다.')
          break()
        }
        break()
      case 'set':
        switch(@args[3]) {
        case 'levels':
          @setting_tunalevel_data = array(
            'levels': @amount,
            'points': 0
          )
          _set_tunalevel(@target_uuid, @player_data, @setting_tunalevel_data, @text)
          break()
        case 'points':
          @level = _get_tunalevel_data(@player_data)['levels']
          if(_get_max_experience(@level) > @args[2]) {
            @setting_tunalevel_data = array(
              'levels': @level,
              'points': @amount
            )
            _set_tunalevel(@target_uuid, @player_data, @setting_tunalevel_data, @text)
          } else {
            tmsg(@player, @text['prefix']['failure'].color('gray').' 경험치를 현재 튜나 레벨의 최대 경험치보다 높게 설정할 수 없습니다.')
          }
          break()
        default:
          tmsg(@player, @text['prefix']['warn'].color('gray').' 명령어의 4번째 인자는 levels 또는 points이여야 합니다.')
          break()
        }
        break()
      default:
        tmsg(@player, @text['prefix']['warn'].color('gray').' 명령어의 2번째 인자는 add 또는 set이여야 합니다.')
        break()
      }
    } else {
      tmsg(@player, @text['prefix']['failure'].color('gray').' 해당 플레이어를 찾을 수 없습니다.')
    }
  } else {
    tmsg(@player, @text['prefix']['warn'].color('yellow').' /tunalevel <add/set> <플레이어> <수치> <levels/points>')
  }
}
register_command('tunalevel', array(
  permission: 'tunalevel',
  'tabcompleter': closure(@command, @player, @args) {
    switch(array_size(@args)) {
    case 1:
      @return = array('add', 'set')
      @input = @args[-1]
      return(array_filter(@return, closure(@key, @value) {
        return(length(@input) <= length(@value) && equals_ic(@input, substr(@value, 0, length(@input))))
      }))
    case 2:
      @online_players = all_players()
      @input = @args[-1]
      return(array_filter(@online_players, closure(@key, @value) {
        return(length(@input) <= length(@value) && equals_ic(@input, substr(@value, 0, length(@input))))
      }))
    case 4:
      @return = array('levels', 'points')
      @input = @args[-1]
      return(array_filter(@return, closure(@key, @value) {
        return(length(@input) <= length(@value) && equals_ic(@input, substr(@value, 0, length(@input))))
      }))
    default:
      return(array())
    }
  },
  'executor': closure(@command, @player, @args) {
    _tunalevel_command(@command, @player, @args, @text, @players_data)
  }
))

# 튜나레벨 랜덤 커맨드
proc _give_tunalevel_random_experience(@uuid, @player_data, @adding_default_experience, @adding_extra_experience, @text) {
  @points = integer(round(@adding_default_experience + rand() * @adding_extra_experience))
  if(@points < 0) { @points = 0 }
  @adding_tunalevel_data = array(
    'levels': 0,
    'points': @points
  )
  _add_tunalevel(@uuid, @player_data, @adding_tunalevel_data, @text)
  return(@points)
}

register_command('tunalevelrand', array(
  permission: 'tunalevelrand',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) == 3) {
      @target_name = @args[0]
      @target_uuid = puuid(@target_name)
      @player_data = @players_data[@target_uuid]
      @adding_default_experience = double(@args[1])
      @adding_extra_experience = double(@args[2])
      @points = _give_tunalevel_random_experience(@target_uuid, @player_data, @adding_default_experience, @adding_extra_experience, @text)
      tmsg(@target_name, @text['prefix']['success'] @points.'의 튜나 레벨 경험치를 받았습니다.')
    }
  }
))


# 레벨 HUDs
proc _replace_arcanelevel_text(@arcanelevel) {
  @background = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      @arcanelevel, '0', '\uf802\uef30\uf801'
                    ), '1', '\uf802\uef31\uf801'
                  ), '2', '\uf802\uef32\uf801'
                ), '3', '\uf802\uef33\uf801'
              ), '4', '\uf802\uef34\uf801'
            ), '5', '\uf802\uef35\uf801'
          ), '6', '\uf802\uef36\uf801'
        ), '7', '\uf802\uef37\uf801'
      ), '8', '\uf802\uef38\uf801'
    ), '9', '\uf802\uef39\uf801'
  )
  @text = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      @arcanelevel, '0', '\uef20\uf801'
                    ), '1', '\uef21\uf801'
                  ), '2', '\uef22\uf801'
                ), '3', '\uef23\uf801'
              ), '4', '\uef24\uf801'
            ), '5', '\uef25\uf801'
          ), '6', '\uef26\uf801'
        ), '7', '\uef27\uf801'
      ), '8', '\uef28\uf801'
    ), '9', '\uef29\uf801'
  )
  @nsf = string_multiply('\uF804', length(@arcanelevel))
  @arcanelevel_text = '\uef3c\uf801'.@background.'\uf801'.@nsf.'\uf808\uf801'.'\uef3b\uf801'.@text
  return(@arcanelevel_text)
}

## 아케인 경험치
proc _show_arcanelevel(@player, @uuid, @text) {
  # bar
  @bars = array(
    '\ueeb0', '\ueeb1', '\ueeb2', '\ueeb3', '\ueeb4', '\ueeb5', '\ueeb6', '\ueeb7', '\ueeb8', '\ueeb9', '\ueeba', '\ueebb', '\ueebc', '\ueebd', '\ueebe', '\ueebf',
    '\ueec0', '\ueec1', '\ueec2', '\ueec3', '\ueec4', '\ueec5', '\ueec6', '\ueec7', '\ueec8', '\ueec9', '\ueeca', '\ueecb', '\ueecc', '\ueecd', '\ueece', '\ueecf',
    '\ueed0', '\ueed1', '\ueed2', '\ueed3', '\ueed4', '\ueed5', '\ueed6', '\ueed7', '\ueed8', '\ueed9', '\ueeda', '\ueedb', '\ueedc', '\ueedd', '\ueede', '\ueedf',
    '\ueee0', '\ueee1', '\ueee2', '\ueee3', '\ueee4', '\ueee5', '\ueee6', '\ueee7', '\ueee8', '\ueee9', '\ueeea', '\ueeeb', '\ueeec', '\ueeed', '\ueeee', '\ueeef',
    '\ueef0', '\ueef1', '\ueef2', '\ueef3', '\ueef4', '\ueef5', '\ueef6', '\ueef7', '\ueef8', '\ueef9', '\ueefa', '\ueefb', '\ueefc', '\ueefd', '\ueefe', '\ueeff'
  )
  @bar_index = integer(pexp(@player) * 0.8)
  @bar = @bars[@bar_index]
  
  # level
  @arcanelevel_text = _replace_arcanelevel_text(plevel(@player))

  _set_sidebar(@uuid, 6, color('#fd0000').@text['space_fonts']['space.9'].@bar.@text['space_fonts']['space.-83'].@arcanelevel_text, @text)
}

proc _drop_arcanelevel_random_experience(@location, @adding_default_experience, @adding_extra_experience) {
  @points = integer(round(@adding_default_experience + rand() * @adding_extra_experience))
  if(@points > 0) {
    spawn_entity('EXPERIENCE_ORB', 1, @location, closure(@euuid) {
      set_entity_spec(@euuid, array('amount': @points))
    })
  }
}

bind('exp_change', null, null, @event, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  set_timeout(0, closure() {
    _show_arcanelevel(@player, @uuid, @text)
  })
}

proc _give_arcanelevel_random_experience(@player, @uuid, @adding_default_experience, @adding_extra_experience, @text) {
  @points = integer(round(@adding_default_experience + rand() * @adding_extra_experience))
  if(@points < 0) { @points = 0 }
  give_pexp(@player, @points)
  _show_arcanelevel(@player, @uuid, @text)
  return(@points)
}

register_command('arcanelevelrand', array(
  permission: 'arcanelevelrand',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) == 3) {
      @target_name = @args[0]
      @target_uuid = puuid(@target_name)
      @adding_default_experience = double(@args[1])
      @adding_extra_experience = double(@args[2])
      @points = _give_arcanelevel_random_experience(@target_name, @target_uuid, @adding_default_experience, @adding_extra_experience, @text)
      tmsg(@target_name, @text['prefix']['success'] @points.'의 아케인 레벨 경험치를 받았습니다.')
    }
  }
))