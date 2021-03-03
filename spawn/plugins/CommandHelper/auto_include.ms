## Initial Including Data
@server = array(
  'name': 'spawn', //wild resident guest
  'loaded': false,
  'bots': array('aaaa__', 'dohun1') #'dohun1','aaaa__'
)
@bots = array(
  'LopLove',
  #'dohun1',
  '1L_Bottle'
)
@players_state = array()
@players_data = array()
@players_item = array()
@hp_blocks = array()
@text = array()
async_read('files/font_space.json', closure(@value) {
  @text['space_fonts'] = json_decode(@value)
})
async_read('files/general_emoji.json', closure(@value) {
  @text['general_emoji'] = json_decode(@value)
})

## Initial Including Procedure
proc _send_action_msg(@player, @player_data, @skills_spec, @text) {
  if(@player_data['cache'] ) {
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
    if(@skill != '' && array_index_exists(@player_data['active_skill'][@category], @skill)) {
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
        @index = integer(@remain_cooldown / @max_cooldown * 10)
        switch(@skills_spec[@category][@skill]['levels'][@level]['active']['count']) {
        case 1:
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
        case 2:
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
        case 3:
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
    #196
    action_msg(@player, @text['space_fonts']['space.5'].@channel.@text['space_fonts']['space.-71'].@text['space_fonts']['space.'.(@player_data['setting'][12] - 330)].@left_hotbar.@text['space_fonts']['space.-20'].@left_icon.@text['space_fonts']['space.2'].@text['space_fonts']['space.196'].@right_hotbar.@text['space_fonts']['space.-20'].@right_icon.@text['space_fonts']['space.2'].@text['space_fonts']['space.'.(@player_data['setting'][12] - 330)])
    #action_msg(@player, @text['space_fonts']['space.5'].@channel.@text['space_fonts']['space.-65'].@text['space_fonts']['space.'.@player_data['setting'][12]])
  } else {
    #해상도 설정
    #141496 #ff6464
    #\ue405 /tellraw aaaa__ "\ue405\uF800 A"
    action_msg(@player, hexcolor('#ff6464').'\ue3f8'.@text['space_fonts']['space.-1'].hexcolor('#ffffff').'\ue3f8'.'\uF800'.@text['space_fonts']['space.'.@player_data['setting'][12]].hexcolor('#ff6464').'\ue3f8'.@text['space_fonts']['space.-1'])
    #action_msg(@player, hexcolor('#ff6464').'|'.@text['space_fonts']['space.-1'].hexcolor('#64ffff').'|'.@text['space_fonts']['space.-2'].@text['space_fonts']['space.'.@player_data['setting'][12]].@text['space_fonts']['space.-1'].hexcolor('#64ffff').'|'.@text['space_fonts']['space.-1'].hexcolor('#ff6464').'|'.@text['space_fonts']['space.-1'])
  }

}
  
proc _all_players(@bots) {
  @players = all_players()
  foreach(@bot in @bots) {
    array_remove_values(@players, @bot)
  }
  return(@players)
}

proc _send_plugin_message(@request_bot, @channel_messages) {
  @byte_array = byte_array()
  foreach(@channel_message in @channel_messages) {
    ba_put_string(@byte_array, @channel_message)
  }
  send_plugin_message(@request_bot, 'BungeeCord', @byte_array)
}

proc _bungeecord_foward(@request_bot, @identifier, @data) {
  @data_array = byte_array()
  ba_put_string(@data_array, json_encode(@data))
  @byte_array = byte_array()
  ba_put_string(@byte_array, 'Forward')
  ba_put_string(@byte_array, 'ALL')
  ba_put_string(@byte_array, @identifier)
  ba_put_short(@byte_array, array_size(@data_array))
  ba_put_bytes(@byte_array, @data_array)
  send_plugin_message(@request_bot, 'BungeeCord', @byte_array)
}

proc _bungeecord_foward_to_bot(@request_bot, @receive_bot, @identifier, @data) {
  @data_array = byte_array()
  ba_put_string(@data_array, json_encode(@data))
  @byte_array = byte_array()
  ba_put_string(@byte_array, 'ForwardToPlayer')
  ba_put_string(@byte_array, @receive_bot)
  ba_put_string(@byte_array, @identifier)
  ba_put_short(@byte_array, array_size(@data_array))
  ba_put_bytes(@byte_array, @data_array)
  send_plugin_message(@request_bot, 'BungeeCord', @byte_array)
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
  return(@value * @multiply + @value * @deviation * 0.5 - @value * @deviation * rand())
}

#확장으로 대채될 예정
proc _particle(@player, @particle, @pos, @delta, @speed, @count) {
  sudo(@player, '/particle'@particle @pos['x'] @pos['y'] @pos['z'] @delta['x'] @delta['y'] @delta['z'] @speed @count 'force')
}