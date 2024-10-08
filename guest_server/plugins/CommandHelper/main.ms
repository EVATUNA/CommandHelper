# 서버 이름
@splited_absolute_path = split('\\', get_absolute_path())
array_reverse(@splited_absolute_path)
@server = @splited_absolute_path[2]

# 리소스팩 링크
@resourcepack = array(
  'url': get_value('resourcepack')
)

## Resourcepack Downloader
register_command('resourcepackstart', array(
  'description': 'You can download resourcepack',
  'usage': '/resourcepackstart',
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) == 0) {
      send_resourcepack(@player, @resourcepack['url'])
      return(true)
    } else {
      return(false)
    }
  }
))

## Resourcepack Download Checker
bind('resource_pack_status', null, null, @event) {
  @player = @event['player']
  @uuid = puuid(@player)
  switch(@event['status']) {
  case 'DECLINED':
    pkick(@player, _color('#ff4040').'§l서버 리소스팩을 사용하도록 설정해 주시기 바랍니다.\n'._color('#c0c0c0').'§l에바참치 서버를 선택한 후, 수정 버튼을 눌러\n서버 리소스팩을 사용으로 설정해 주세요.\n\n'._color('#ffff80').'§l버그 문의: ')
    break()
  case 'SUCCESSFULLY_LOADED':
    runas(@player, '/resourcepackdone')
    play_named_sound(ploc(@player), array('category': 'MASTER', 'sound': 'music.happy_tune', 'volume': 0.4, 'pitch': 1), array(@player))
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
      @uuid = puuid(@player)
      @reconnecting_data = array(
        'uuid': @uuid,
        'countdown': 10,
        'server': @server,
        'last_sender': '',
        'last_whisper_sender': '',
        'whisper_target': ''
      )
      kafka_send('ch.inform_player_quit', json_encode(@reconnecting_data))
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
    if(ponline(@player)) {
      if(pisop(@player)) {
        if(array_size(@args) == 1) {
          store_value('resourcepack', @args[0])
          @resourcepack['url'] = @args[0]
          @data = array(
            'url': @args[0]
          )
          kafka_send('ch.update_resourcepack_url', @args[0])
          return(true)
        } else {
          return(false)
        }
      } else {
        return(false)
      }
    } else {
      if(array_size(@args) == 1) {
        store_value('resourcepack', @args[0])
        @resourcepack['url'] = @args[0]
        @data = array(
          'url': @args[0]
        )
        kafka_send('ch.update_resourcepack_url', @args[0])
        return(true)
      } else {
        return(false)
      }
    }
  }
))


bind('kafka_receive', null, null, @event, @resourcepack, @server) {
  switch(@event['key']) {
  case 'ch.update_resourcepack_url':
    @url = @event['value']
    @resourcepack['url'] = @url
    store_value('resourcepack', @url)
    break()
  }
}