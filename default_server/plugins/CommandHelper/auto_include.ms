### Initial Including Data

## 공용 데이터
# 서버 이름
@splited_absolute_path = split('\\', get_absolute_path())
array_reverse(@splited_absolute_path)
@server = @splited_absolute_path[2]

# 리소스팩 링크
@resourcepack = array(
  'url': get_value('resourcepack')
)

# 텍스트
@text = array(
  'prefix': array(
    'success': '\ue4dc',
    'failure': '\ue4de',
    'warn': '\ue4dd',
    'info': '\ue4e3',
    'broadcast': '\ue4db'
  )
)
async_read('files/font_space.json', closure(@value) {
  @text['space_fonts'] = json_decode(@value)
})
async_read('files/general_emoji.json', closure(@value) {
  @text['general_emoji'] = json_decode(@value)
})

# 서버 이동중으로 인식할 플레이어 목록
@reconnectable_players = array()

# 플레이어 개인 데이터
@players_data = array()

## 게임 플레이 관련 데이터
# 블럭 피통
@hp_blocks = array()

# 광물 스펙
@minerals_spec = array()
async_read('files/minerals_spec.json', closure(@value) {
  foreach(@mineral: @spec in json_decode(@value)) {
    @minerals_spec[@mineral] = @spec
  }
})

# 작물 스펙
@crops_spec = array()
async_read('files/crops_spec.json', closure(@value) {
  foreach(@crop: @spec in json_decode(@value)) {
    @crops_spec[@crop] = @spec
  }
})

## Item Management
@effective_items = array(
  'armor': array(
    'LEATHER_BOOTS',
    'CHAINMAIL_BOOTS',
    'IRON_BOOTS',
    'GOLDEN_BOOTS',
    'DIAMOND_BOOTS',
    'NETHERITE_BOOTS'
  ),
  'weapon': array(
    'WOODEN_SWORD',
    'WOODEN_SHOVEL',
    'WOODEN_PICKAXE',
    'WOODEN_AXE',
    'WOODEN_HOE',
    'STONE_SWORD',
    'STONE_SHOVEL',
    'STONE_PICKAXE',
    'STONE_AXE',
    'STONE_HOE',
    'GOLDEN_SWORD',
    'GOLDEN_SHOVEL',
    'GOLDEN_PICKAXE',
    'GOLDEN_AXE',
    'GOLDEN_HOE',
    'IRON_SWORD',
    'IRON_SHOVEL',
    'IRON_PICKAXE',
    'IRON_AXE',
    'IRON_HOE',
    'DIAMOND_SWORD',
    'DIAMOND_SHOVEL',
    'DIAMOND_PICKAXE',
    'DIAMOND_AXE',
    'DIAMOND_HOE',
    'NETHERITE_SWORD',
    'NETHERITE_SHOVEL',
    'NETHERITE_PICKAXE',
    'NETHERITE_AXE',
    'NETHERITE_HOE',
    'TRIDENT',
    'BOW',
    'CROSSBOW',
    'SHIELD',
    'WHEAT_SEEDS',
    'BEETROOT_SEEDS',
    'POTATO',
    'CARROT',
    'PUMPKIN_SEEDS',
    'MELON_SEEDS',
    'SWEET_BERRIES'
  )
)

### Initial Including Procedure
## 화면 관련
# 액션바
proc _send_action_msg(@player, @player_data, @skills_spec, @text) {
  switch(@player_data['chat'][1]) {
  case true:
    switch(@player_data['chat'][0]) {
    case 'general':
      @channel = '\ue3fd'
    case 'town':
      @channel = '\ue3ff'
    case 'local':
      @channel = '\ue401'
    case 'admin':
      @channel = '\ue403'
    default:
      @channel = '\ue3fd'
    }
  case false:
  switch(@player_data['chat'][0]) {
    case 'general':
      @channel = '\ue3fe'
    case 'town':
      @channel = '\ue400'
    case 'local':
      @channel = '\ue402'
    case 'admin':
      @channel = '\ue404'
    default:
      @channel = '\ue3fe'
    }
  }
  # 스킬 매니징
  @skill_manager = @player_data['skill_manager']
  @selected_methods = json_decode(@skill_manager[4])
  # 손에 든 아이템 구하기
  @main_hand_item = @player_data['item']['main_hand']
  @hoes = array(
    'WOODEN_HOE',
    'STONE_HOE',
    'IRON_HOE',
    'GOLDEN_HOE',
    'DIAMOND_HOE',
    'NETHERITE_HOE'
  )
  @seeds = array(
    'WHEAT_SEEDS',
    'BEETROOT_SEEDS',
    'POTATO',
    'CARROT',
    'PUMPKIN_SEEDS',
    'MELON_SEEDS',
    'SWEET_BERRIES'
  )
  # 손에든 아이템에 따라 사용할 액티브 스킬 설정
  if(!is_null(@main_hand_item)) { // 무언가 들고 있을시
    if(array_contains(@hoes, @main_hand_item['name'])) {
      @skill = @selected_methods['harvesting_method']
    } else if(array_contains(@seeds, @main_hand_item['name'])) {
      @skill = @selected_methods['sowing_method']
    } else {
      @skill = @selected_methods['combat_method']
    }
    if(@skill == '') { // 파종, 수확 스킬 선택 안했을시
      @skill = @selected_methods['combat_method']
    }
  } else { // 특별한 도구 든거 없을시
    @skill = @selected_methods['combat_method']
  }
  # 액티브 스킬을 쓸수 있을시
  if(@skill != '' && array_index_exists(@player_data['active_skill'], @skill)) {
    @active_skill = @player_data['active_skill'][@skill]
    @point = @player_data['skill_data'][@skill][0]
    @skill_spec = @skills_spec[@skill]
    if(@skill_spec['effect_by_point'][@point]['active']['count'] == 0) {
      if(@active_skill[1] > 0) {
        @max_duration = @skill_spec['effect_by_point'][@point]['active']['duration']
        @index = integer(@active_skill[1] / @max_duration * 10)
        switch(@index) {
        case 0:
          @hotbar = '\ue406'
          break()
        case 1:
          @hotbar = '\ue408'
          break()
        case 2:
          @hotbar = '\ue409'
          break()
        case 3:
          @hotbar = '\ue40a'
          break()
        case 4:
          @hotbar = '\ue40b'
          break()
        case 5:
          @hotbar = '\ue40c'
          break()
        case 6:
          @hotbar = '\ue40d'
          break()
        case 7:
          @hotbar = '\ue40e'
          break()
        case 8:
          @hotbar = '\ue40f'
          break()
        case 9:
          @hotbar = '\ue410'
          break()
        case 10:
          @hotbar = '\ue411'
          break()
        }
      } else {
        @max_cooldown = @skill_spec['effect_by_point'][@point]['active']['cooldown']
        @remain_cooldown = @max_cooldown - @active_skill[0]
        @index = integer(@remain_cooldown / @max_cooldown * 10)
        switch(@index) {
        case 0:
          @hotbar = '\ue406'
          break()
        case 1:
          @hotbar = '\ue408'
          break()
        case 2:
          @hotbar = '\ue409'
          break()
        case 3:
          @hotbar = '\ue40a'
          break()
        case 4:
          @hotbar = '\ue40b'
          break()
        case 5:
          @hotbar = '\ue40c'
          break()
        case 6:
          @hotbar = '\ue40d'
          break()
        case 7:
          @hotbar = '\ue40e'
          break()
        case 8:
          @hotbar = '\ue40f'
          break()
        case 9:
          @hotbar = '\ue410'
          break()
        case 10:
          @hotbar = '\ue411'
          break()
        }
      }
    } else {
      @max_cooldown = @skill_spec['effect_by_point'][@point]['active']['cooldown']
      @remain_cooldown = @max_cooldown - @active_skill[0]
      @index = integer(@remain_cooldown / @max_cooldown * 10)
      switch(@active_skill[2]) {
      case 0:
        switch(@index) {
        case 0:
          @hotbar = '\ue406'
          break()
        case 1:
          @hotbar = '\ue412'
          break()
        case 2:
          @hotbar = '\ue413'
          break()
        case 3:
          @hotbar = '\ue414'
          break()
        case 4:
          @hotbar = '\ue415'
          break()
        case 5:
          @hotbar = '\ue416'
          break()
        case 6:
          @hotbar = '\ue417'
          break()
        case 7:
          @hotbar = '\ue418'
          break()
        case 8:
          @hotbar = '\ue419'
          break()
        case 9:
          @hotbar = '\ue41a'
          break()
        case 10:
          @hotbar = '\ue41b'
          break()
        }
        break()
      case 1:
        switch(@index) {
        case 0:
          @hotbar = '\ue41b'
          break()
        case 1:
          @hotbar = '\ue41c'
          break()
        case 2:
          @hotbar = '\ue41d'
          break()
        case 3:
          @hotbar = '\ue41e'
          break()
        case 4:
          @hotbar = '\ue41f'
          break()
        case 5:
          @hotbar = '\ue420'
          break()
        case 6:
          @hotbar = '\ue421'
          break()
        case 7:
          @hotbar = '\ue422'
          break()
        case 8:
          @hotbar = '\ue423'
          break()
        case 9:
          @hotbar = '\ue424'
          break()
        case 10:
          @hotbar = '\ue425'
          break()
        }
        break()
      case 2:
        switch(@index) {
        case 0:
          @hotbar = '\ue425'
          break()
        case 1:
          @hotbar = '\ue426'
          break()
        case 2:
          @hotbar = '\ue427'
          break()
        case 3:
          @hotbar = '\ue428'
          break()
        case 4:
          @hotbar = '\ue429'
          break()
        case 5:
          @hotbar = '\ue42a'
          break()
        case 6:
          @hotbar = '\ue42b'
          break()
        case 7:
          @hotbar = '\ue42c'
          break()
        case 8:
          @hotbar = '\ue42d'
          break()
        case 9:
          @hotbar = '\ue42e'
          break()
        case 10:
          @hotbar = '\ue42f'
          break()
        }
        break()
      case 3:
        @hotbar = '\ue42f'
        break()
      }
    }
    switch(@skill) {
    case 'sweeping':
      @icon = '\ue431'
      break()
    case 'knockback':
      @icon = '\ue432'
      break()
    case 'cleaving':
      @icon = '\ue433'
      break()
    case 'blocking':
      @icon = '\ue434'
      break()
    case 'wide_hands':
      @icon = '\ue435'
      break()
    case 'golden_finger':
      @icon = '\ue436'
      break()
    case 'wet_hands':
      @icon = '\ue437'
      break()
    case 'fertile_touch':
      @icon = '\ue438'
      break()
    default:
      @icon = '\ue430'
      break()
    }
  } else {
    @hotbar = @text['space_fonts']['space.23']
    @icon = @text['space_fonts']['space.17']
  }
  if(@player_data['setting'][1]) {
    @left_hotbar = @text['space_fonts']['space.23']
    @left_icon = @text['space_fonts']['space.17']
    @right_hotbar = @hotbar
    @right_icon = @icon
  } else {
    @left_hotbar = @hotbar
    @left_icon = @icon
    @right_hotbar = @text['space_fonts']['space.23']
    @right_icon = @text['space_fonts']['space.17']
  }
  @left_surface = '§c\ue3f8§r'.@text['space_fonts']['space.-8'].'\ue006'.@text['space_fonts']['space.-8'].'\ue007'.@text['space_fonts']['space.-1']
  @right_surface = '§c\ue3f8§r'.@text['space_fonts']['space.-2']
  @resolution = @player_data['setting'][0]
  if(@resolution % 2 == 0) {
    @left_resolution = integer(@resolution / 2)
    @right_resolution = integer(@resolution / 2)
  } else {
    @left_resolution = integer(@resolution / 2)
    @right_resolution = integer(@resolution / 2 + 1)
  }
  @left_quota = integer(@left_resolution / 1024)
  @right_quota = integer(@right_resolution / 1024)
  @left_rest = @left_resolution % 1024
  @right_rest = @right_resolution % 1024
  @left_void = string_multiply(@text['space_fonts']['space.1024'], @left_quota).@text['space_fonts']['space.'.@left_rest]
  @right_void = string_multiply(@text['space_fonts']['space.1024'], @right_quota).@text['space_fonts']['space.'.@right_rest]
  @chat_hud = @text['space_fonts']['space.2'].@channel.@text['space_fonts']['space.-67']
  @skill_hud = @text['space_fonts']['space.-118'].@text['space_fonts']['space.-2'].@left_hotbar.@text['space_fonts']['space.-20'].@left_icon.@text['space_fonts']['space.198'].@right_hotbar.@text['space_fonts']['space.-20'].@right_icon.@text['space_fonts']['space.-118']
  action_msg(@player, @left_surface.@chat_hud.@left_void.@skill_hud.@right_void.@right_surface)
}

# 팁 메시지 보여주기
proc _set_tooltips(@player, @uuid, @player_data) {
  @tooltips = @player_data['cache']['tooltips']
  if(array_size(@tooltips) > 0) {
    @tooltip_message = @tooltips[0]['message']
    @tooltip_percent = @tooltips[0]['percent']
    @tooltip_color = @tooltips[0]['color']
    if(array_index_exists(@tooltips[0], 'sound')) {
      if(@tooltips[0]['sound_time'] == @tooltips[0]['countdown']) {
        play_named_sound(ploc(@player), @tooltips[0]['sound'], array(@player))
      }
    }
  } else {
    @tooltip_message = ''
    @tooltip_percent = 0
    @tooltip_color = 'WHITE'
  }
  @tooltip_bossbar_data = array(
    'title': @tooltip_message,
    'percent': @tooltip_percent,
    'color': @tooltip_color
  )
  update_bar('tooltip.'.@uuid, @tooltip_bossbar_data)
}

# 팁 메시지 목록에 추가하기
proc _add_tooltip(@player, @uuid, @player_data, @tooltip_data) {
  @tooltips = @player_data['cache']['tooltips']
  @tooltip = array(
    'message': @tooltip_data['message'],
    'countdown': @tooltip_data['countdown']
  )
  if(array_index_exists(@tooltip_data, 'sound') && is_array(@tooltip_data['sound'])) {
    @tooltip['sound'] = @tooltip_data['sound']
    if(array_size(@tooltips) == 0) {
      @tooltip['sound_time'] = @tooltip_data['countdown'] - 1
    } else {
      @tooltip['sound_time'] = @tooltip_data['countdown']
    }
  }
  switch(@tooltip_data['type']) {
  case 'warn':
    @tooltip['type'] = 'warn'
    @tooltip['color'] = 'WHITE'
    @tooltip['percent'] = 0
    if(array_size(@tooltips) > 0 && (@tooltips[0]['type'] == 'warn' || @tooltips[0]['type'] == 'indicator')) {
      @tooltips[0] = @tooltip
    } else {
      array_insert(@tooltips, @tooltip, 0)
    }
    break()
  case 'indicator':
    @tooltip['type'] = 'indicator'
    @tooltip['color'] = 'PURPLE'
    @tooltip['percent'] = @tooltip_data['percent']
    if(array_size(@tooltips) > 0 && (@tooltips[0]['type'] == 'warn' || @tooltips[0]['type'] == 'indicator')) {
      @tooltips[0] = @tooltip
    } else {
      array_insert(@tooltips, @tooltip, 0)
    }
    break()
  default:
    @tooltip['type'] = 'default'
    @tooltip['color'] = 'WHITE'
    @tooltip['percent'] = 0
    @tooltips[] = @tooltip
    break()
  }
}

# 인디케이터
proc _set_indicator(@player, @uuid, @player_data, @indicator_data, @text) {
  switch(@indicator_data['block']) {
  case 'COAL_ORE':
    @icon = '\ue4c7'
    break()
  case 'DEEPSLATE_COAL_ORE':
    @icon = '\ue4d1'
    break()
  case 'COPPER_ORE':
    @icon = '\ue4c8'
    break()
  case 'DEEPSLATE_COPPER_ORE':
    @icon = '\ue4d2'
    break()
  case 'IRON_ORE':
    @icon = '\ue4c9'
    break()
  case 'DEEPSLATE_IRON_ORE':
    @icon = '\ue4d3'
    break()
  case 'LAPIS_ORE':
    @icon = '\ue4ca'
    break()
  case 'DEEPSLATE_LAPIS_ORE':
    @icon = '\ue4ca'
    break()
  case 'GOLD_ORE':
    @icon = '\ue4d4'
    break()
  case 'DEEPSLATE_GOLD_ORE':
    @icon = '\ue4d5'
    break()
  case 'NETHER_QUARTZ_ORE':
    @icon = '\ue4cc'
    break()
  case 'NETHER_GOLD_ORE':
    @icon = '\ue4d6'
    break()
  case 'REDSTONE_ORE':
    @icon = '\ue4cd'
    break()
  case 'DEEPSLATE_REDSTONE_ORE':
    @icon = '\ue4d7'
    break()
  case 'EMERALD_ORE':
    @icon = '\ue4ce'
    break()
  case 'DEEPSLATE_EMERALD_ORE':
    @icon = '\ue4d8'
    break()
  case 'DIAMOND_ORE':
    @icon = '\ue4cf'
    break()
  case 'DEEPSLATE_DIAMOND_ORE':
    @icon = '\ue4d9'
    break()
  case 'ANCIENT_DEBRIS':
    @icon = '\ue4d0'
    break()
  case 'FARMLAND':
    @icon = '\ue4da'
    break()
  }
  @percentage = (1- @indicator_data['hp'] / @indicator_data['max_hp']) * 0.8 + 0.15
  if(@percentage > 0.95) { @percentage = 0.95 }
  if(@percentage < 0.15) { @percentage = 0.15 }
  @tooltip_data = array(
    'type': 'indicator',
    'message': '\ue4b2'.@text['space_fonts']['space.-178'].@icon.@text['space_fonts']['space.162'],
    'countdown': @indicator_data['countdown'],
    'percent': @percentage
  )
  _add_tooltip(@player, @uuid, @player_data, @tooltip_data)
}

## 기타 proc
# 배열 나누기
proc _paging(@array, @size) {
  @pages = array()
  @asize = array_size(@array)
  for(@i = 0, @i < integer(@asize / @size), @i++) {
    @pages[] = array_get(@array, cslice(@i * @size, (@i + 1) * @size - 1))
  }
  if(@asize % @size != 0) {
    @pages[] = array_get(@array, cslice(@asize - (@asize % @size), @asize - 1))
  }
  return(@pages)
}

# 배수와 편차로 나눠진 랜덤 정수 구하기
proc _multiply_value(@value, @multiply, @deviation) {
  @multiply_value = @value * @multiply + @value * @deviation * 0.5 - @value * @deviation * rand()
  # 9 + 0.45 - 0~0.9
  @quota = integer(@multiply_value)
  @rest = @multiply_value - @quota
  if(@rest > rand()) { @quota += 1 }
  return(integer(@quota))
}

proc _color(@color) {
  if(reg_count('^#[a-fA-F0-9]{6}$', @color)) {
    return('§x§'.@color[1].'§'.@color[2].'§'.@color[3].'§'.@color[4].'§'.@color[5].'§'.@color[6])
  } else {
    return(color(@color))
  }
}

# 참치 경험치 구하는 proc
proc _get_max_tuna_experience(@level) {
  if(@level <= 20) {
    @max_experience = integer(round(1.25 ** (@level + 1) * 50))
  } else {
    @max_experience = integer(round(4770 * 1.25 ** (@level + 1 - 21)))
  }
  return(@max_experience)
}

# 참치 레벨 기준 토탈 스킬 포인트 구하는 proc 
proc _get_total_skill_point(@skill_manager) {
  @point = @skill_manager[0] + integer(@skill_manager[0] / 5) + @skill_manager[2] // 1 레벨당 1 포인트, 5 레벨당 1 보너스 포안트, 그외 추가 포인트 의 총합
  return(@point)
}


# 참치 레벨 텍스트 생성
proc _replace_tunalevel_text(@level) {
  if(@level == 0) {
    @tunalevel_text = ''
  } else {
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
                        @level, '0', '\uf136\uf801'
                      ), '1', '\uf137\uf801'
                    ), '2', '\uf138\uf801'
                  ), '3', '\uf139\uf801'
                ), '4', '\uf13a\uf801'
              ), '5', '\uf13b\uf801'
            ), '6', '\uf13c\uf801'
          ), '7', '\uf13d\uf801'
        ), '8', '\uf13e\uf801'
      ), '9', '\uf13f\uf801'
    )
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
                        @level, '0', '\uf802\uf12c\uf801'
                      ), '1', '\uf802\uf12d\uf801'
                    ), '2', '\uf802\uf12e\uf801'
                  ), '3', '\uf802\uf12f\uf801'
                ), '4', '\uf802\uf130\uf801'
              ), '5', '\uf802\uf131\uf801'
            ), '6', '\uf802\uf132\uf801'
          ), '7', '\uf802\uf133\uf801'
        ), '8', '\uf802\uf134\uf801'
      ), '9', '\uf802\uf135\uf801'
    )
    @chars = split('', @level)
    @nsf = ''
    foreach(@char in @chars) {
      if(@char == 1) {
        @nsf = @nsf.'\uF803'
      } else {
        @nsf = @nsf.'\uF804'
      }
    }
    @tunalevel_text = '\uf801'.@background.'\uf801'.@nsf.@text
  }
  return(@tunalevel_text)
}

proc _replace_repair_percent(@percent) {
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
                      @percent, '0', '\uf801\uec20'
                    ), '1', '\uec21'
                  ), '2', '\uf801\uec22'
                ), '3', '\uf801\uec23'
              ), '4', '\uf801\uec24'
            ), '5', '\uf801\uec25'
          ), '6', '\uf801\uec26'
        ), '7', '\uf801\uec27'
      ), '8', '\uf801\uec28'
    ), '9', '\uf801\uec29'
  ).'\uf801\uec2a'
  @return = ''
  switch(length(@percent)) {
  case '1':
    @return = '\uF824'.@text.'\uF824'
    break()
  case '2':
    @return = '\uF822'.@text.'\uF822'
    break()
  }
  return(@return)
}

# 상점 리코딩 후 제거 예정
array proc _clone(array @arr) { return(array_deep_clone(@arr)) }
boolean proc _existsGui(string @guiid) { return(array_contains(get_virtual_inventories(), @guiid)) }


proc _get_circle_offsets(@radius) {
  @offsets = array(
    array(0, +@radius),
    array(0, -@radius),
    array(+@radius, 0),
    array(-@radius, 0)
  )
  @x = 1
  @y = @radius
  @p = 1 - @radius
  while(@x <= @y) {
    if(@p < 0) {
      @p += @x * 2 + 1
    } else {
      @p += @x * 2 + 1 - @y * 2
      @y--
      for(@i = 0, @i < @x, @i++) {
        @offsets[] = array(+@y, +@i)
        @offsets[] = array(-@y, +@i)
        @offsets[] = array(+@y, -@i)
        @offsets[] = array(-@y, -@i)
        @offsets[] = array(+@i, +@y)
        @offsets[] = array(-@i, +@y)
        @offsets[] = array(+@i, -@y)
        @offsets[] = array(-@i, -@y)
      }
    }
    @offsets[] = array(+@x, +@y)
    @offsets[] = array(+@x, -@y)
    @offsets[] = array(-@x, +@y)
    @offsets[] = array(-@x, -@y)
    @offsets[] = array(+@y, +@x)
    @offsets[] = array(+@y, -@x)
    @offsets[] = array(-@y, +@x)
    @offsets[] = array(-@y, -@x)
    @x++
  }
  for(@i = -@y + 1, @i < @y, @i++) {
    for(@j = -@y + 1, @j < @y, @j++) {
      @offsets[] = array(@i, @j)
    }
  }
  return(array_unique(@offsets))
}

export('circumference_0', array(
  array(+0,+0)
))

export('circumference_1', array(
  array(-1,-1), array(+0,-1), array(+1,-1),
  array(-1,+0),               array(+1,+0),
  array(-1,+1), array(+0,+1), array(+1,+1)
))

export('circumference_2', array(
                array(-1,-2), array(+0,-2), array(+1,-2),
  array(-2,-1),                                           array(+2,-1),
  array(-2,+0),                                           array(+2,+0),
  array(-2,+1),                                           array(+2,+1),
                array(-1,+2), array(+0,+2), array(+1,+2)
))

export('circumference_3', array(
                              array(-1,-3), array(+0,-3), array(+1,-3),
                array(-2,-2),                                           array(+2,-2),
  array(-3,-1),                                                                       array(+3,-1),
  array(-3,+0),                                                                       array(+3,+0),
  array(-3,+1),                                                                       array(+3,+1),
                array(-2,+2),                                           array(+2,+2),
                              array(-1,+3), array(+0,+3), array(+1,+3)
))

export('circumference_4', array(
                              array(-2,-4), array(-1,-4), array(+0,-4), array(+1,-4), array(+2,-4),
                array(-3,-3), array(-2,-3),                                           array(+2,-3), array(+3,-3),
  array(-4,-2), array(-3,-2),                                                                       array(+3,-2), array(+4,-2),
  array(-4,-1),                                                                                                   array(+4,-1),
  array(-4,+0),                                                                                                   array(+4,+0),
  array(-4,+1),                                                                                                   array(+4,+1),
  array(-4,+2), array(-3,+2),                                                                       array(+3,+2), array(+4,+2),
                array(-3,+3), array(-2,+3),                                           array(+2,+3), array(+3,+3),
                              array(-2,+4), array(-1,+4), array(+0,+4), array(+1,+4), array(+2,+4)
))

array(
                                            array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0),
                              array(+0,+0),                                                                       array(+0,+0),
                array(+0,+0),                                                                                                   array(+0,+0),
  array(+0,+0),                                                                                                                               array(+0,+0),
  array(+0,+0),                                                                                                                               array(+0,+0),
  array(+0,+0),                                                                                                                               array(+0,+0),
  array(+0,+0),                                                                                                                               array(+0,+0),
  array(+0,+0),                                                                                                                               array(+0,+0),
                array(+0,+0),                                                                                                   array(+0,+0),
                              array(+0,+0),                                                                       array(+0,+0),
                                            array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0)
)

array(
                                                          array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0),
                              array(+0,+0), array(+0,+0),                                                                       array(+0,+0), array(+0,+0),
                array(+0,+0), array(+0,+0),                                                                                                   array(+0,+0), array(+0,+0),
                array(+0,+0),                                                                                                                               array(+0,+0),
  array(+0,+0),                                                                                                                                                           array(+0,+0),
  array(+0,+0),                                                                                                                                                           array(+0,+0),
  array(+0,+0),                                                                                                                                                           array(+0,+0),
  array(+0,+0),                                                                                                                                                           array(+0,+0),
  array(+0,+0),                                                                                                                                                           array(+0,+0),
                array(+0,+0),                                                                                                                               array(+0,+0),
                array(+0,+0), array(+0,+0),                                                                                                   array(+0,+0), array(+0,+0),
                              array(+0,+0), array(+0,+0),                                                                       array(+0,+0), array(+0,+0),
                                                          array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0)
)

array(
                                                                        array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0),
                                            array(+0,+0), array(+0,+0),                                                                       array(+0,+0), array(+0,+0),
                              array(+0,+0),                                                                                                                               array(+0,+0),
                array(+0,+0),                                                                                                                                                           array(+0,+0),
                array(+0,+0),                                                                                                                                                           array(+0,+0),
  array(+0,+0),                                                                                                                                                                                       array(+0,+0),
  array(+0,+0),                                                                                                                                                                                       array(+0,+0),
  array(+0,+0),                                                                                                                                                                                       array(+0,+0),
  array(+0,+0),                                                                                                                                                                                       array(+0,+0),
  array(+0,+0),                                                                                                                                                                                       array(+0,+0),
                array(+0,+0),                                                                                                                                                           array(+0,+0),
                array(+0,+0),                                                                                                                                                           array(+0,+0),
                              array(+0,+0),                                                                                                                               array(+0,+0),
                                            array(+0,+0), array(+0,+0),                                                                       array(+0,+0), array(+0,+0),
                                                                        array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0), array(+0,+0)
)