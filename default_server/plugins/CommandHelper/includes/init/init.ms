### 전역 변수 선언 ###

# 서버 이름
@splited_absolute_path = split('\\', get_absolute_path())
array_reverse(@splited_absolute_path)
@server = @splited_absolute_path[4]
export('server', @server)

# 리소스팩 링크
@resourcepack = array(
  'url': get_value('resourcepack')
)

# 텍스트
@text = array(
  'space_fonts': json_decode(comp_read('../../files/font_space.json')),
  //'emoji': array(
  //  'general': json_decode(comp_read('../../files/general_emoji.json'))
  //),
  'prefix': array(
    'success': '\ue4dc',
    'failure': '\ue4de',
    'warn': '\ue4dd',
    'info': '\ue4e3',
    'broadcast': '\ue4db',
    'join': '\ue4e5',
    'leave': '\ue4e6',
    'tutorial': '\ue4ea'
  )
)
export('text', @text)

# 서버 이동중으로 인식할 플레이어 목록
@reconnecting_datas = array()
export('reconnecting_datas', @reconnecting_datas)

# 플레이어 개인 데이터
@players_data = array()
export('players_data', @players_data)

# 블럭 피통
@hp_blocks = array()
export('hp_blocks', @hp_blocks)

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
# GUI 시스템
proc _gui_exists(@id) {
  return(array_contains(get_virtual_inventories(), @id))
}

bind('inventory_close', null, array('virtual': true), @event) {
  @player = @event['player']
  @id = pinventory_holder(@player)
  set_timeout(1, closure() {
    if(has_bind("click.@id")) { unbind("click.@id") }
    if(has_bind("drag.@id")) { unbind("drag.@id") }
    if(has_bind("close.@id")) { unbind("close.@id") }
    if(_gui_exists(@id)) { delete_virtual_inventory(@id) }
  })
}

proc _show_gui(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure) {
  @id = @player.'.'.@gui_id.'.'.time()
  create_virtual_inventory(@id, @type, color('white').@texture_layer._color('#404040').@message, @inventory)
  @closure_arguments = array_merge(array(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id), array_get(@arguments, cslice(7, array_size(@arguments) - 1)))
  #기본 클로저 setter 인수: closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id) @id 뒤에 추가로 기입 가능
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

# 파일 이름과 파일 확장자를 나누어 구하기 (확장명이 있는 파일 이름만 넣을 것!)
proc _get_file_name_and_extension(@file) {
  @full_stop_qty = reg_count('\\.', @file) // . 의 갯수 구하기
  @splited_file = split('.', @file, @full_stop_qty) // . 로 문자열 나누기
  @file_name = array_implode(array_get(@splited_file, cslice(0, @full_stop_qty - 1)), '.') // 파일 이름부분
  @file_extension = @splited_file[@full_stop_qty] // 파일 확장자 부분
  return(array(@file_name, @file_extension))
}

# 참치 레벨 기준 토탈 스킬 포인트 구하는 proc 
proc _get_total_skill_point(@skill_manager) {
  @point = @skill_manager[0] + integer(@skill_manager[0] / 5) + @skill_manager[2] // 1 레벨당 1 포인트, 5 레벨당 1 보너스 포안트, 그외 추가 포인트 의 총합
  return(@point)
}


# 인디케이터

# 스코어보드 변경
proc _set_sidebar(@uuid, @line, @message, @text) {
  @scoreboard = "ch_scoreboard.@uuid"
  if(length(@message) <= 63) {
    set_team_display(@line, array('prefix': @message.@text['space_fonts']['space.-max'] ), @scoreboard)
  } else {
    set_team_display(@line, array('prefix': @line.'번째 줄이 너무 깁니다. '.@text['space_fonts']['space.-max'] ), @scoreboard)
  }
}

proc _show_indicator(@uuid, @player_data, @indicator_data, @text) {

  @queue_id = @indicator_data['id']'.'@indicator_data['block']
  @queue = "@uuid.indicator"

  @icons = array(
    'COAL_ORE': '\ue4c7',
    'COPPER_ORE': '\ue4c8',
    'IRON_ORE': '\ue4c9',
    'LAPIS_ORE': '\ue4ca',
    'GOLD_ORE': '\ue4cb',
    'NETHER_QUARTZ_ORE': '\ue4cc',
    'REDSTONE_ORE': '\ue4cd',
    'EMERALD_ORE': '\ue4ce',
    'DIAMOND_ORE': '\ue4cf',
    'ANCIENT_DEBRIS': '\ue4d0',
    'DEEPSLATE_COAL_ORE': '\ue4d1',
    'DEEPSLATE_COPPER_ORE': '\ue4d2',
    'DEEPSLATE_IRON_ORE': '\ue4d3',
    'DEEPSLATE_LAPIS_ORE': '\ue4d4',
    'DEEPSLATE_GOLD_ORE': '\ue4d5',
    'NETHER_GOLD_ORE': '\ue4d6',
    'DEEPSLATE_REDSTONE_ORE': '\ue4d7',
    'DEEPSLATE_EMERALD_ORE': '\ue4d8',
    'DEEPSLATE_DIAMOND_ORE': '\ue4d9',
    'FARMLAND': '\ue4da'

  )
  @backgrounds = array(
    '\ue406',
    '\ue408', '\ue409', '\ue40a', '\ue40b', '\ue40c', '\ue40d', '\ue40e', '\ue40f', '\ue410', '\ue411',
    '\ue412', '\ue413', '\ue414', '\ue415', '\ue416', '\ue417', '\ue418', '\ue419', '\ue41a', '\ue41b',
    '\ue41c', '\ue41d', '\ue41e', '\ue41f', '\ue420', '\ue421', '\ue422', '\ue423', '\ue424', '\ue425',
    '\ue426', '\ue427', '\ue428', '\ue429', '\ue42a', '\ue42b', '\ue42c', '\ue42d', '\ue42e', '\ue42f',
    '\ue430', '\ue431', '\ue432', '\ue433', '\ue434', '\ue435', '\ue436', '\ue437', '\ue438', '\ue439',
    '\ue43a', '\ue43b', '\ue43c', '\ue43d', '\ue43e', '\ue43f', '\ue440', '\ue441', '\ue442', '\ue443',
    '\ue444', '\ue445', '\ue446', '\ue447', '\ue448', '\ue449', '\ue44a', '\ue44b', '\ue44c', '\ue44d',
    '\ue4b2', '\ue4b3', '\ue4b4', '\ue4b5', '\ue4b6', '\ue4b7', '\ue4b8', '\ue4b9', '\ue4ba', '\ue4bb',
    '\ue4bc', '\ue4bd', '\ue4be', '\ue4bf'
  )

  @icon = @icons[@indicator_data['block']]

  @old_background_index = integer((1- @indicator_data['old_hp'] / @indicator_data['max_hp']) * 84)
  @new_background_index = integer((1- @indicator_data['new_hp'] / @indicator_data['max_hp']) * 84)

  clear_task(@player_data['cache']['indicator_remove_task'])

  // 큐 프리셋
  if(queue_running(@queue)) {
    if(@player_data['cache']['indicator_id'] == @queue_id) {
      //같은 블럭 상호작용시 인디케이터 제거 큐 삭제
      queue_remove(@queue)
    } else{
      //다른 블럭 상호작용시 큐 클리어
      queue_clear(@queue)
    }
  }

  // 인디케이터 메인 큐 푸시
  if(@new_background_index != @old_background_index) {
    // 체력 변화 있을시
    for(@i = @old_background_index, @i <= @new_background_index, @i++) {
      @chance = ((@i - @old_background_index) / (@new_background_index - @old_background_index)) ** 2
      if(rand() < @chance) {
        @background = @backgrounds[@i]
        @closure = closure() {
          _set_sidebar(@uuid, 4, color('#fc8080').@text['space_fonts']['space.4'].@background.@text['space_fonts']['space.-20'].@icon, @text)
        }
        queue_push(@closure, @queue)
      }
    }
  } else {
    // 체력 변화 없을시
    @background = @backgrounds[@new_background_index]
    _set_sidebar(@uuid, 4, color('#fc8080').@text['space_fonts']['space.4'].@background.@text['space_fonts']['space.-20'].@icon, @text)
  }

  // 인디케이터 제거 큐 푸시
  if(@indicator_data['countdown'] > 10) { @indicator_data['countdown'] = 10 }
  @closure = closure() {
    @task = set_timeout(integer(@indicator_data['countdown'] * 1000), closure() {
      _set_sidebar(@uuid, 4, '', @text)
    })
    @player_data['cache']['indicator_remove_task'] = @task
  }
  queue_push(@closure, @queue)

  // 인디케이터 id 저장
  @player_data['cache']['indicator_id'] = @queue_id
}

# 수리 gui 텍스트
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
                    ), '1', '\uf801\uec21'
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


proc _debugmsg(@msg) {
  @player = 'aaaa__'
  if(ponline(@player)) {
    tmsg(@player, @msg)
  }
}