## Initial Including Data
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
  switch(@player_data['chating']['en_ko']) {
  case true:
    switch(@player_data['chating']['channel']) {
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
  switch(@player_data['chating']['channel']) {
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
  action_msg(@player, @text['space_fonts']['space.5'].@channel.@text['space_fonts']['space.-65'].@text['space_fonts']['space.'.@player_data['setting']['interface']['resolution']])
}

proc _send_plugin_message(@player, @channel_messages) {
  @byte_array = byte_array()
  foreach(@channel_message in @channel_messages) {
    ba_put_string(@byte_array, @channel_message)
  }
  send_plugin_message(@player, 'BungeeCord', @byte_array)
}

proc _bungeecord_foward(@player, @subchannel, @data) {
  @data_array = byte_array()
  ba_put_string(@data_array, json_encode(@data))
  @byte_array = byte_array()
  ba_put_string(@byte_array, 'Forward')
  ba_put_string(@byte_array, 'ALL')
  ba_put_string(@byte_array, @subchannel)
  ba_put_short(@byte_array, array_size(@data_array))
  ba_put_bytes(@byte_array, @data_array)
  send_plugin_message(@player, 'BungeeCord', @byte_array)
}

proc _bungeecord_foward_to_player(@sender, @receiver, @data) {
  @data_array = byte_array()
  ba_put_string(@data_array, json_encode(@data))
  @byte_array = byte_array()
  ba_put_string(@byte_array, 'ForwardToPlayer')
  ba_put_string(@byte_array, @receiver)
  ba_put_string(@byte_array, @subchannel)
  ba_put_short(@byte_array, array_size(@data_array))
  ba_put_bytes(@byte_array, @data_array)
  send_plugin_message(@sender, 'BungeeCord', @byte_array)
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

#확장으로 대채될 예정
proc _particle(@player, @particle, @pos, @delta, @speed, @count) {
  sudo(@player, '/particle'@particle @pos['x'] @pos['y'] @pos['z'] @delta['x'] @delta['y'] @delta['z'] @speed @count 'force')
}