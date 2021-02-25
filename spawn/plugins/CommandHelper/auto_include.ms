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
proc _send_action_msg(@player, @player_data, @text) {
  if(@player_data['cache']) {
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
    action_msg(@player, @text['space_fonts']['space.5'].@channel.@text['space_fonts']['space.-65'].@text['space_fonts']['space.'.@player_data['setting'][12]])
  } else {
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