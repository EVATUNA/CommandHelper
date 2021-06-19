## Initial Including Data
@server = array(
  'name': 'over',
  'resourcepack': get_value('resourcepack')
)

@bots = array(
  'c45537c6-39d3-459e-9a48-86f938a9c0dd', #dohun1
  'b5ee7eb3-f4e8-4ab4-82e4-e97c60a6b8c1', #Loplove
  'ff1cb130-7152-4609-8cbc-76884c7444bd', #Geralt_w
  '5c400342-2909-4571-8c45-7833a076b1dd', #AppleCrepe
  'bee4cc4e-ebd4-472c-9751-32d2655e9848', #CreamCrepe
  '9dfadbe7-9ad1-4048-9cdd-228f8db82be7'  #1L_Bottle
)
@bots_name = array(
  'dohun1', #dohun1
  'Loplove', #Loplove
  'Geralt_w', #Geralt_w
  'AppleCrepe', #AppleCrepe
  'creamcrepe',  #CreamCrepe
  '1L_Bottle' #1L_Bottle
)
@reconnectable_players = array()
@players_data = array()
@text = array()
async_read('files/font_space.json', closure(@value) {
  @text['space_fonts'] = json_decode(@value)
})
async_read('files/general_emoji.json', closure(@value) {
  @text['general_emoji'] = json_decode(@value)
})

## Gameplay Data
@hp_blocks = array()
@minerals_spec = array()
async_read('files/minerals_spec.json', closure(@value) {
  foreach(@mineral: @spec in json_decode(@value)) {
    @minerals_spec[@mineral] = @spec
  }
})
@crops_spec = array()
async_read('files/crops_spec.json', closure(@value) {
  foreach(@crop: @spec in json_decode(@value)) {
    @crops_spec[@crop] = @spec
  }
})

## Initial Including Procedure
proc _send_action_msg(@player, @player_data, @skills_spec, @text) {
  switch(@player_data['setting'][1]) {
  case true:
    switch(@player_data['setting'][0]) {
    case 'general':
      @channel = '\ue3fd'
    case 'guild':
      @channel = '\ue3ff'
    case 'local':
      @channel = '\ue401'
    case 'admin':
      @channel = '\ue403'
    default:
      @channel = '\ue3fd'
    }
  case false:
  switch(@player_data['setting'][0]) {
    case 'general':
      @channel = '\ue3fe'
    case 'guild':
      @channel = '\ue400'
    case 'local':
      @channel = '\ue402'
    case 'admin':
      @channel = '\ue404'
    default:
      @channel = '\ue3fe'
    }
  }
  #hub 표사
  #broadcast(@player_data['skill_manager'][2])

  @item = pinv(@player, pheld_slot(@player))
  if(!is_null(@item)) {
    if(array_contains(array('WOODEN_HOE', 'STONE_HOE', 'IRON_HOE', 'GOLDEN_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @item['name']) && @player_data['skill_manager'][3] != '') {
      @category = 'harvesting_method'
      @skill = @player_data['skill_manager'][3]
    } else if(array_contains(array('WHEAT_SEEDS', 'BEETROOT_SEEDS', 'POTATO', 'CARROT', 'PUMPKIN_SEEDS', 'MELON_SEEDS', 'SWEET_BERRIES'), @item['name']) && @player_data['skill_manager'][4] != '') {
      @category = 'sowing_method'
      @skill = @player_data['skill_manager'][4]
    } else {
      @category = 'combat_method'
      @skill = @player_data['skill_manager'][2]
    }
  } else {
    @category = 'combat_method'
    @skill = @player_data['skill_manager'][2]
  }
  if(@skill != '' && array_index_exists(@player_data, 'active_skill') && array_index_exists(@player_data['active_skill'], @category) && array_index_exists(@player_data['active_skill'][@category], @skill)) {
    @level = @player_data['skill_data'][@category][@skill][0]
    if(@skills_spec[@category][@skill]['levels'][@level]['active']['count'] == 0) {
      if(@player_data['active_skill'][@category][@skill][1] > 0) {
        @max_duration = @skills_spec[@category][@skill]['levels'][@level]['active']['duration']
        @duration = @player_data['active_skill'][@category][@skill][1]
        @index = integer(@duration / @max_duration * 10)
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
        @max_cooldown = @skills_spec[@category][@skill]['levels'][@level]['active']['cooldown']
        @remain_cooldown = @max_cooldown - @player_data['active_skill'][@category][@skill][0]
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
      @max_cooldown = @skills_spec[@category][@skill]['levels'][@level]['active']['cooldown']
      @remain_cooldown = @max_cooldown - @player_data['active_skill'][@category][@skill][0]
      @skill_count = @player_data['active_skill'][@category][@skill][2]
      @index = integer(@remain_cooldown / @max_cooldown * 10)
      #broadcast(@skill_count @index @player_data['active_skill'][@category][@skill] @max_cooldown)
      switch(@skill_count) {
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
    case 'wide_hand':
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
  if(@player_data['setting'][13]) {
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
  @resolution = @player_data['setting'][12]
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

proc _set_tips(@player, @uuid, @players_data) {
  @tips = @players_data[@uuid]['cache']['tips']
  if(array_size(@tips) > 0) {
    @tip_message = @tips[0]['message']
    if(array_index_exists(@tips[0], 'sound')) {
      if(@tips[0]['sound_time'] == @tips[0]['countdown']) {
        play_named_sound(ploc(@player), @tips[0]['sound'], array(@player))
      }
    }
  } else {
    @tip_message = ''
  }
  @tip_bossbar_data = array(
    'title': @tip_message
  )
  update_bar('tip.'.@uuid, @tip_bossbar_data)
}

proc _add_tips(@player, @uuid, @players_data, @message, @countdown, @is_warn, @sound) {
  @tips = @players_data[@uuid]['cache']['tips']
  @tip = array(
    'message': @message,
    'countdown': @countdown,
    'is_warn': @is_warn
  )
  if(is_array(@sound)) {
    @tip['sound'] = @sound
    if(array_size(@tips) == 0) {
      @tip['sound_time'] = @countdown - 1
    } else {
      @tip['sound_time'] = @countdown
    }
  }
  if(@is_warn) {
    if(array_size(@tips) > 0 && @tips[0]['is_warn']) {
      @tips[0] = @tip
    } else {
      array_insert(@tips, @tip, 0)
    }
  } else {
    @tips[] = @tip
  }
}

proc _set_indicator(@player, @uuid, @players_data, @text) {
  @indicator_data = @players_data[@uuid]['cache']['indicator']
  if(!is_null(@indicator_data)) {
    switch(@indicator_data['block']) {
    case 'COAL_ORE':
      @icon = '\ue4c7'
      break()
    case 'PETRIFIED_OAK_SLAB':
      @icon = '\ue4c8'
      break()
    case 'IRON_ORE':
      @icon = '\ue4c9'
      break()
    case 'LAPIS_ORE':
      @icon = '\ue4ca'
      break()
    case 'GOLD_ORE':
      @icon = '\ue4cb'
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
    case 'EMERALD_ORE':
      @icon = '\ue4ce'
      break()
    case 'DIAMOND_ORE':
      @icon = '\ue4cf'
      break()
    case 'ANCIENT_DEBRIS':
      @icon = '\ue4d0'
      break()
    case 'FARMLAND':
      @icon = '\ue4da'
      break()
    }
    @percentage = integer((1- @indicator_data['hp'] / @indicator_data['max_hp']) * 100)
    switch(@percentage) {
    case 100:
      @ui = '\ue4c6'
      break()
    case 95..100:
      @ui = '\ue4c5'
      break()
    case 90..95:
      @ui = '\ue4c4'
      break()
    case 85..90:
      @ui = '\ue4c3'
      break()
    case 80..85:
      @ui = '\ue4c2'
      break()
    case 75..80:
      @ui = '\ue4c1'
      break()
    case 70..75:
      @ui = '\ue4c0'
      break()
    case 65..70:
      @ui = '\ue4bf'
      break()
    case 60..65:
      @ui = '\ue4be'
      break()
    case 55..60:
      @ui = '\ue4bd'
      break()
    case 50..55:
      @ui = '\ue4bc'
      break()
    case 45..50:
      @ui = '\ue4bb'
      break()
    case 40..45:
      @ui = '\ue4ba'
      break()
    case 35..40:
      @ui = '\ue4b9'
      break()
    case 30..35:
      @ui = '\ue4b8'
      break()
    case 25..30:
      @ui = '\ue4b7'
      break()
    case 20..25:
      @ui = '\ue4b6'
      break()
    case 15..20:
      @ui = '\ue4b5'
      break()
    case 10..15:
      @ui = '\ue4b4'
      break()
    case 5..10:
      @ui = '\ue4b3'
      break()
    case 0..5:
      @ui = '\ue4b2'
      break()
    }
    @resolution = @players_data[@uuid]['setting'][12]
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
    @indicator_bossbar_data = array(
      'title': @text['space_fonts']['space.2'].@ui.@text['space_fonts']['space.-19'].@icon.@text['space_fonts']['space.-21'].@left_void.@right_void
    )
    update_bar('indicator.'.@uuid, @indicator_bossbar_data)
  } else {
    @indicator_bossbar_data = array(
      'title': ''
    )
    update_bar('indicator.'.@uuid, @indicator_bossbar_data)
  }
}

proc _all_players(@bots) {
  @players_uuid = bukkitlinked_get_all_players()
  foreach(@bot in @bots) {
    array_remove_values(@players_uuid, @bot)
  }
  return(@players_uuid)
}

proc _send_plugin_message(@request_bot, @channel_messages) {
  @byte_array = byte_array()
  foreach(@channel_message in @channel_messages) {
    ba_put_string(@byte_array, @channel_message)
  }
  send_plugin_message(@request_bot, 'BungeeCord', @byte_array)
}

proc _bungeecord_foward(@player, @identifier, @data) {
  @data_array = byte_array()
  ba_put_string(@data_array, json_encode(@data))
  @byte_array = byte_array()
  ba_put_string(@byte_array, 'Forward')
  ba_put_string(@byte_array, 'ALL')
  ba_put_string(@byte_array, @identifier)
  ba_put_short(@byte_array, array_size(@data_array))
  ba_put_bytes(@byte_array, @data_array)
  send_plugin_message(@player, 'BungeeCord', @byte_array)
}

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

proc _multiply_value(@value, @multiply, @deviation) {
  @multiply_value = @value * @multiply + @value * @deviation * 0.5 - @value * @deviation * rand()
  # 9 + 0.45 - 0~0.9
  @quota = integer(@multiply_value)
  @rest = @multiply_value - @quota
  if(@rest > rand()) { @quota += 1 }
  return(integer(@quota))
}

register_command('resourceurl', array(
  'description': 'You can set resourcepack download url.',
  'permission': '*',
  'usage': '/resourceurl <url>',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(pisop(@player)) {
      if(array_size(@args) == 1) {
        store_value('resourcepack', @args[0])
        @server['resourcepack'] = @args[0]
        @data = array(
          'url': @args[0]
        )
        _bungeecord_foward(@player, 'ch_resourcepack_url_update', @data)
        return(true)
      } else {
        return(false)
      }
    } else {
      return(false)
    }
  }
))

# 상점 리코딩 후 제거 예정
array proc _clone(array @arr) { return(array_deep_clone(@arr)) }
boolean proc _existsGui(string @guiid) { return(array_contains(get_virtual_inventories(), @guiid)) }