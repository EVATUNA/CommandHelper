@ch_items = json_decode(comp_read("items.json"))

proc _give_item_random_qty(@player, @category, @ch_item_name, @default_qty, @extra_qty, @ch_items) {
  if(array_index_exists(@ch_items, @category, @ch_item_name)) {
    @item = @ch_items[@category][@ch_item_name]
    @qty = integer(round(@default_qty + rand() * @extra_qty))
    if(@qty < 0) { @qty = 0 }
    @item['qty'] = @qty
    @item['qty'] = pgive_item(@player, @item)
    if(@item['qty'] > 0) { drop_item(@player, @item) }
    return(@qty)
  } else {
    return(0)
  }
}

register_command('giveitemrand', array(
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) == 5) {
      @target_name = @args[0]
      @target_uuid = puuid(@target_name)
      @category = @args[1]
      @ch_item_name = @args[2]
      @default_qty = double(@args[3])
      @extra_qty = double(@args[4])
      @qty = _give_item_random_qty(@target_name, @category, @ch_item_name, @default_qty, @extra_qty, @ch_items)
      if(@qty > 0) {
        @item = @ch_items[@category][@ch_item_name]
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = @item['meta']['display']
        } else {
          @item_name = @item['name']
        }
        @prefix = @text['prefix']['success']
        if(@qty == 1) {
          tmsg(@target_name, "@prefix @item_name§f를 받았습니다")
        } else {
          tmsg(@target_name, "@prefix @item_name§7(x@qty)§f를 받았습니다")
        }
      }
    }
  }
))

register_command('giveitemone', array(
  'tabcompleter': closure(@command, @player, @args) { return(array()) },
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) > 2) {
      @target_name = @args[0]
      @target_uuid = puuid(@target_name)
      @category = @args[1]
      @ch_item_name = array_implode(array_get(@args, cslice(2, array_size(@args) - 1)), ' ')
      broadcast(@ch_item_name)
      if(array_index_exists(@ch_items, @category, @ch_item_name)) {
        pgive_item(@target_name, @ch_items[@category][@ch_item_name])
      }
      /*
      @default_qty = double(@args[3])
      @extra_qty = double(@args[4])
      @qty = _give_item_random_qty(@target_name, @category, @ch_item_name, @default_qty, @extra_qty, @ch_items)
      if(@qty > 0) {
        @item = @ch_items[@category][@ch_item_name]
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = @item['meta']['display']
        } else {
          @item_name = @item['name']
        }
        @prefix = @text['prefix']['success']
        if(@qty == 1) {
          tmsg(@target_name, "@prefix @item_name§f를 받았습니다")
        } else {
          tmsg(@target_name, "@prefix @item_name§7(x@qty)§f를 받았습니다")
        }
      }
       */
    }
  }
))