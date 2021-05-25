


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
  create_virtual_inventory(@id, @type, @texture_layer.@message, @inventory)
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