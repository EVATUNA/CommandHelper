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

@text['space_fonts'] = json_decode(comp_read('files/font_space.json'))
//async_read('files/font_space.json', closure(@value) {
//  @text['space_fonts'] = json_decode(@value)
//})
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

# 스코어보드 초기화
foreach(@scoreboard in get_scoreboards()) {
  if(string_starts_with(@scoreboard, 'ch_scoreboard.')) {
    remove_scoreboard(@scoreboard)
  }
}

# 광물 보상
@mineral_rewards = array()
# 작물 보상
@crop_rewards = array()
# 낚시 보상
@fish_rewards = array()
# 몹 보상
@mob_rewards = array()

# 데스 패널티
@death_penalties_multiply = array()

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

# GUI 시스템
proc _gui_exists(@id) {
  return(array_contains(get_virtual_inventories(), @id))
}

bind('inventory_close', null, array('virtual': true), @event) {
  @player = @event['player']
  @id = pinventory_holder(@player)
  set_timeout(1, closure() {
    #if(has_bind('open'.@id)) { unbind('open'.@id) } #의미 없음
    if(has_bind('click'.@id)) { unbind('click'.@id) }
    if(has_bind('drag'.@id)) { unbind('drag'.@id) }
    if(has_bind('close'.@id)) { unbind('close'.@id) }
    if(_gui_exists(@id)) { delete_virtual_inventory(@id) }
  })
}

proc _show_gui(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure) {
  @id = @player.'.'.@gui_id.'.'.time()
  create_virtual_inventory(@id, @type, color('white').@texture_layer._color('#404040').@message, @inventory)
  @closure_arguments = array_merge(array(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id), array_get(@arguments, cslice(7, array_size(@arguments) - 1)))
  #기본 클로저 인수: closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id) @id 뒤에 추가로 기입 가능
  execute_array(@closure_arguments, @closure)
  popen_inventory(@player, @id)
}

proc _close_all_gui() {
  foreach(@id in get_virtual_inventories()) {
    foreach(@player in get_inventory_viewers(@id)) {
      close_pinv(@player)
    }
  }
}

# 파일 이름과 파일 확장자를 나누어 구하기 (확장명이 있는 파일 이름만 넣을 것!)
proc _get_file_name_and_extension(@file) {
  @full_stop_qty = reg_count('\\.', @file) // . 의 갯수 구하기
  @splited_file = split('.', @file, @full_stop_qty) // . 로 문자열 나누기
  @file_name = array_implode(array_get(@splited_file, cslice(0, @full_stop_qty - 1)), '.') // 파일 이름부분
  @file_extension = @splited_file[@full_stop_qty] // 파일 확장자 부분
  return(array(@file_name, @file_extension))
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

# 엔티티 태그
proc _update_tag(@id, @array) {
  if(array_size(get_scoreboard_tags(@id)) == 0) {
    add_scoreboard_tag(@id, json_encode(@array))
  } else if(array_size(get_scoreboard_tags(@id)) == 1) {
    remove_scoreboard_tag(@id, get_scoreboard_tags(@id)[0])
    add_scoreboard_tag(@id, json_encode(@array))
  }
}
proc _get_tag(@id) {
  @tags = get_scoreboard_tags(@id)
  if(array_size(@tags) == 1) {
    return(json_decode(@tags[0]))
  } else {
    return(null)
  }
}

proc _get_vanilla_world(@world) {
  switch(@world) {
  case 'spawn':
    @return = 'overowrld'
    break()
  case 'world':
    @return = 'overowrld'
    break()
  case 'spawn_minecraft_residence':
    @return = 'residence'
    break()
  default:
    @return = @world
    break()
  }
  return(@return)
}

# 아이템 액자
proc _summon_item_frame(@location, @frame_facing, @item_rotation, @name, @item, @tag) {
  @vanilla_world = _get_vanilla_world(@location['world'])
  @x = round(@location['x'], 1)
  @y = round(@location['y'], 1)
  @z = round(@location['z'], 1)
  @facing = 0
  # Facing
  switch(@frame_facing) {
  case 'UP':
    @facing = 1
    break()
  case 'DOWN':
    @facing = 0
    break()
  case 'SOUTH':
    @facing = 3
    break()
  case 'WEST':
    @facing = 4
    break()
  case 'NORTH':
    @facing = 2
    break()
  case 'EAST':
    @facing = 5
    break()
  }
  @nbt_facing = "Facing: @facing"

  @nbt_default = "Invisible: 1, Fixed: 1"
  @nbt_rotation = "ItemRotation: @item_rotation"

  # CustomName
  if(is_null(@name)) {
    @name = '\\\"\\\"'
  } else {
    @name = '\\\"'.@name.'\\\"'
  }
  @nbt_name = "CustomName:\"@name\""

  # Tags
  if(is_null(@tag)) {
    @nbt_tag = "Tags: []"
  } else {
    @encoded_tag = replace(replace(json_encode(@tag), '\\', '\\\\'), '"', '\\\"')
    @nbt_tag = "Tags: [\"@encoded_tag\"]"
  }

  # Item
  if(is_null(@item)) {
    @item = array('name': 'AIR')
  }

  @item_name = to_lower(@item['name'])
  if(array_index_exists(@item, 'meta', 'model')) {
    @item_model = @item['meta']['model']
  } else {
    @item_model = 0
  }
  @nbt_item = "Item: {id: \"minecraft:@item_name\", tag:{CustomModelData: @item_model}, Count: 1}"
  
  runas('~console', "/execute in @vanilla_world run summon item_frame @x @y @z {@nbt_default, @nbt_facing, @nbt_rotation, @nbt_name, @nbt_tag, @nbt_item}")
  //broadcast('~console' "/execute in @vanilla_world run summon item_frame @x @y @z {@nbt_default, @nbt_facing, @nbt_rotation, @nbt_name, @nbt_tag, @nbt_item}")
}

# 미스틱 몹
proc _summon_mythicmob(@name, @count, @location) {
  @world = @location['world']
  @x = round(@location['x'], 1)
  @y = round(@location['y'], 1)
  @z = round(@location['z'], 1)
  runas('~console', "/mm mobs spawn @name @count @world,@x,@y,@z")
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