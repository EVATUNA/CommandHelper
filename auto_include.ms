proc _send_plugin_message(@player, @channel_messages) {
  @byte_array = byte_array()
  foreach(@channel_message in @channel_messages) {
    ba_put_string(@byte_array, @channel_message)
  }
  send_plugin_message(@player, 'BungeeCord', @byte_array)
}

proc _array_to_page(@array, @size) {
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

proc _json_escape(@json) {
  return(replace(replace(@json, '"', '\"'), '\\', '\\\\'))
}

proc _json_unescape(@string) {
  return(replace(replace(@string, '\"', '"'), '\\\\', '\\'))
}

proc _particle(@player, @particle, @pos, @delta, @speed, @count) {
  sudo(@player, '/particle'@particle @pos['x'] @pos['y'] @pos['z'] @delta['x'] @delta['y'] @delta['z'] @speed @count 'force')
}