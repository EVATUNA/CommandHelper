export('Cho', split(' ', 'ㄱ ㄲ ㄴ ㄷ ㄸ ㄹ ㅁ ㅂ ㅃ ㅅ ㅆ ㅇ ㅈ ㅉ ㅊ ㅋ ㅌ ㅍ ㅎ'))
export('Cho.eng', split(' ', 'r R s e E f a q Q t T d w W c z x v g'))
export('Jung', split(' ', 'ㅏ ㅐ ㅑ ㅒ ㅓ ㅔ ㅕ ㅖ ㅗ ㅘ ㅙ ㅚ ㅛ ㅜ ㅝ ㅞ ㅟ ㅠ ㅡ ㅢ ㅣ'))
export('Jung.eng', split(' ', 'k o i O j p u P h hk ho hl y n nj np nl b m ml l'))
@temp = split(' ', 'ㄱ ㄲ ㄳ ㄴ ㄵ ㄶ ㄷ ㄹ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅁ ㅂ ㅄ ㅅ ㅆ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ ㅎ')
array_insert(@temp, ' ', 0)
export('Jong', @temp)

proc _is_korean(string @txt) {
	if(length(reg_match('[가-힣]', @txt)) <= 0) {
		return(false)
	}
	return(true)
}

proc _uncrafting(string @txt) {
	@code = unicode_from_char(substr(@txt, 0, 1)) - 44032
	@var = array_resize(array(), 3)
	@var[0] = floor(@code / 588)
	@var[1] = floor((@code % 588) / 28)
	@var[2] = floor((@code % 588) - (@var[1] * 28))
	return(array(import('Cho')[@var[0]], import('Jung')[@var[1]], import('Jong')[@var[2]]))
}

proc _crafting(string @cho, string @jung, string @jong) {
	if(!array_contains(import('Cho'), @cho) || !array_contains(import('Jung'), @jung) || !array_contains(import('Jong'), @jong)) {
		return(@cho.''.@jung.''.@jong)
	}
	@choi = multiply(array_index(import('Cho'), @cho), 588)
	@jungi = multiply(array_index(import('Jung'), @jung), 28)
	@jongi = array_index(import('Jong'), @jong)
	@txt = char_from_unicode(add(@choi, @jungi, @jongi, 44032))
	return(@txt)
}

proc _txt_backspace(@txt) {
	if(@txt == '', return(''));
	@arr = split('', @txt);
	@ret = ''
	for(@i = 0, @i < subtract(array_size(@arr), 1), @i++){
		@ret = concat(@ret, @arr[@i]);
	}
	return(@ret);
}

proc _deduction_jong(string @txt) {
	@txt1 = replace(replace(replace(replace(replace(replace(@txt, 'ㄱㅅ', 'ㄳ'), 'ㄴㅈ', 'ㄵ'), 'ㄴㅎ', 'ㄶ'), 'ㄹㄱ', 'ㄺ'), 'ㄹㅁ', 'ㄻ') ,'ㄹㅂ', 'ㄼ')
	@txt2 = replace(replace(replace(replace(replace(@txt1, 'ㄹㅅ', 'ㄽ'), 'ㄹㅌ', 'ㄾ'), 'ㄹㅍ', 'ㄿ'), 'ㄹㅎ', 'ㅀ'), 'ㅂㅅ', 'ㅄ')
	return(@txt2)
}

proc _deduction_jung(string @txt) {
	@txt1 = replace(replace(replace(replace(replace(replace(replace(@txt, 'ㅗㅏ', 'ㅘ'), 'ㅗㅐ', 'ㅙ'), 'ㅗㅣ', 'ㅚ'), 'ㅜㅓ', 'ㅝ'), 'ㅜㅣ', 'ㅟ'), 'ㅡㅣ', 'ㅢ'), 'ㅜㅔ', 'ㅞ');
	return(@txt1)
}

proc _convert_eng_to_kor(string @txt) {
	foreach(@k:@t in split('', @txt)) { //한국어섞이면 번역 X
		if(_is_korean(@t), return(false))
	}
	@txts = split(' ', @txt); //스페이스바로 번역할 영어들 구분
	@txtarr = array();
	for(@i = 0, @i < array_size(@txts), @i++) { //영어에서 한글로 이동.
		@txtpush = '';
		foreach(@k:@t in split('', @txts[@i])) {
			if(array_contains(import('Cho.eng'), @t)) {
				@key = array_index(import('Cho.eng'), @t);
				@txtpush = concat(@txtpush, import('Cho')[@key])
			}else if(array_contains_ic(import('Cho.eng'), @t)) {
				@key = array_index(import('Cho.eng'), to_lower(@t));
				@txtpush = concat(@txtpush, import('Cho')[@key]);
			}else if(array_contains(import('Jung.eng'), @t)) {
				@key = array_index(import('Jung.eng'), @t);
				@txtpush = concat(@txtpush, import('Jung')[@key])
			}else if(array_contains_ic(import('Jung.eng'), @t)) {
				@key = array_index(import('Jung.eng'), to_lower(@t));
				@txtpush = concat(@txtpush, import('Jung')[@key])
			}else{@txtpush = concat(@txtpush, @t); }
		}
		array_push(@txtarr, @txtpush)
	}
	foreach(@k:@t in @txtarr) { // 모음들 중 ㅘ 같은 합성들을 조합.
		array_set(@txtarr, @k, _deduction_jung(@t));
	}
	@txtarr2 = array();
	for(@i = 0, @i < array_size(@txtarr), @i++) { // 받침없는 글자 조합.
		@txtpush = '';
		foreach(@k:@t in split('', @txtarr[@i])) {
			if(array_contains(import('Jung'), @t) && @k != 0) {
				@cho = split('', @txtarr[@i])[subtract(@k, 1)];
				@jung = @t;
				@txtpush = _txt_backspace(@txtpush)
				@dummytxt = _crafting(@cho, @jung, ' ')
			}else{ @dummytxt = @t; }
			@txtpush = concat(@txtpush, @dummytxt)
		}
		array_push(@txtarr2, @txtpush)
	}
	@txtarr3 = array();
	foreach(@k:@t in @txtarr2) { // 받침들 중 ㄶ 같은 합성들을 조합.
		array_push(@txtarr3, _deduction_jong(@t));
	}
	@txtarr4 = array();
	for(@i = 0, @i < array_size(@txtarr3), @i++) { //글자와 받침 조합.
		@txtpush = '';
		@split = split('', @txtarr3[@i]); array_reverse(@split);
		foreach(@k:@t in @split) {
			if(array_contains(import('Jong'), @t)) {
				if(array_index_exists(@split, @k+1) && _is_korean(@split[@k+1])) {
					@chojung = _uncrafting(@split[@k+1])
					array_set(@chojung, 2, @t);
					array_remove(@split, @k+1);
					@dummytxt = _crafting(@chojung[0], @chojung[1], @chojung[2]);
				}else{ @dummytxt = @t; }
			}else{ @dummytxt = @t }
			@txtpush = concat(@txtpush ,@dummytxt)
		}
		array_push(@txtarr4, @txtpush)
	} // 글자가 뒤집어져서 반환.
	@result = '';
	foreach(@k:@t in @txtarr4) { //뒤집어진걸 정상화 시킨후 String화
		@rettxt = '';
		@split = split('', @t);
		array_reverse(@split);
		foreach(@t2 in @split){
			@rettxt = concat(@rettxt, @t2);
		}
		if(@k == 0, @result = concat(@result, @rettxt), @result = sconcat(@result, @rettxt))
	}
	return(@result)
}