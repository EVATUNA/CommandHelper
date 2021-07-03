## BungeeCord Channel Register
if(!is_channel_registered('BungeeCord')) {
  register_channel('BungeeCord')
}

## Resourcepack Link Setting
@server = array(
  'name': 'guest',
  'resourcepack': get_value('resourcepack')
)



## BungeeCord Data Sender
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

## Resourcepack Downloader
register_command('resourcepackstart', array(
  'description': 'You can download resourcepack',
  'usage': '/resourcepackstart',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) == 0) {
      send_resourcepack(@player, @server['resourcepack'])
      return(true)
    } else {
      return(false)
    }
  }
))

## Resourcepack Download Checker
bind('resource_pack_status', null,, null, @event) {
  @player = @event['player']
  @uuid = puuid(@player)
  switch(@event['status']) {
  case 'DECLINED':
    pkick(@player, hexcolor('#ff4040').'§l서버 리소스팩을 사용하도록 설정해 주시기 바랍니다.\n'.hexcolor('#c0c0c0').'§l에바참치 서버를 선택한 후, 수정 버튼을 눌러\n서버 리소스팩을 사용으로 설정해 주세요.\n\n'.hexcolor('#ffff80').'§l버그 문의: ')
    @data = array(
      'player': @player,
      'uuid': @uuid,
      'is_op': pisop(@player),
      'guild': null
    )
    _bungeecord_foward(@player, 'ch_update_state', @data)
    break()
  case 'SUCCESSFULLY_LOADED':
    runas(@player, '/resourcepackdone')
    break()
  }
}

## Server Move Checker
register_command('moveserver', array(
  'description': 'move to spawn server',
  'usage': '/moveserver',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) == 0) {
      @data = array(
        'uuid': puuid(@player)
      )
      _bungeecord_foward(@player, 'ch_player_quit', @data)
      return(true)
    } else {
      return(false)
    }
  }
))

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

bind('plugin_message_received', null, array('channel': 'BungeeCord'), @event, @server) {
  if(ponline(@event['player'])) {
    @identifier_size = -1
    foreach(@key: @byte in @event['bytes']) {
      #broadcast(@key @byte )
      if(@key != 0) {
        #if(@byte == 0) {
        if(@byte == 123) {
          @identifier_size = @key - 6 #-2
          break()
        }
      }
    }
    #
    if(@identifier_size != -1) {
      @value_string = string(ba_get_bytes(@event['bytes'], array_size(@event['bytes']) - @identifier_size - 6, @identifier_size + 6))
      if(string_starts_with(@value_string, '{"') &&string_ends_with(@value_string, '}')) {
        @data = array(
          'identifier': string(ba_get_bytes(@event['bytes'], @identifier_size, 2)),
          'value': json_decode(@value_string)
        )
        switch(@data['identifier']) {
        case 'ch_resourcepack_url_update':
          @server['resourcepack'] = @data['value']['url']
          store_value('resourcepack', @data['value']['url'])
        }
      } #else {
        #broadcast(@value_string)
      #}
    }
  }
}