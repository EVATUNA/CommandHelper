// 나중에 지워야 함
proc _get_empty_inventory(@width, @height) {
  if(@width < 1) {@width = 1}
  if(@width > 5) {@width = 5}
  if(@height < 1) {@height = 1}
  if(@height > 3) {@height = 3}

  @structure_void = array(
    'name': 'STRUCTURE_VOID',
    'meta': array(
      'display': ' ',
      'model': 1
    )
  )
  @air = array(
    'name': 'AIR'
  )

  @set_line = array()
  @empty_line = array()
  for(@index = 0, @index < 9, @index++) {
    if(!(@index > 4 - @width && @index < 4 + @width)) {
      @item = @structure_void
    } else {
      @item = @air
    }
    @set_line[] = @item
    @empty_line[] = @structure_void
  }

  switch(@height) {
  case 1:
    @items = array_merge(@empty_line, @set_line, @empty_line)
    break()
  case 2:
    @items = array_merge(@set_line, @set_line, @empty_line)
    break()
  case 3:
    @items = array_merge(@set_line, @set_line, @set_line)
    break()
  }

  return(@items)
}