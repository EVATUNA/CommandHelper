## BungeeCord Channel Register
if(!is_channel_registered('BungeeCord')) {
  register_channel('BungeeCord')
}

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

## Resourcepack Link Setting
@resourcepack = 'https://drive.google.com/uc?export=download&id=1fFXChwt073_Tniwy40-9zc44pBXrdhPF'
@resourcepack_setting_command = array(
  'description': 'You can set resourcepack download url.',
  'permission': '*',
  'usage': '/resourceurl <msg>',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(pisop(@player)) {
      if(array_size(@args) == 1) {
        @resourcepack = @args[0]
        return(true)
      } else {
        return(false)
      }
    } else {
      return(false)
    }
  }
)
register_command('resourceurl', @resourcepack_setting_command)

## Resourcepack Downloader
@resourcepack_download_command = array(
  'description': 'You can download resourcepack',
  'usage': '/resourcepackstart',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) == 0) {
      send_resourcepack(@player, @resourcepack)
      #모든 서버의 리소스팩 다운로드 링크 설정하도록 바꾸기
      return(true)
    } else {
      return(false)
    }
  }
)
register_command('resourcepackstart', @resourcepack_download_command)

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
@resourcepack_download_command = array(
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
)
register_command('moveserver', @resourcepack_download_command)