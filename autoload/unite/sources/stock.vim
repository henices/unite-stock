let s:save_cpo = &cpo
set cpo&vim

let s:candidates = []

let s:source_stock_hq = {
            \ 'name' : 'stock/hq',
            \ 'description' : '新浪股票行情',
            \ 'hooks' : {},
            \ 'syntax' : 'uniteSource__Stock'}

let s:source_stock_5d = {
            \ 'name' : 'stock/5d',
            \ 'description' : '新浪股票五档',
            \ 'hooks' : {}}

let s:source_stock_dp = {
            \ 'name' : 'stock/dp',
            \ 'description' : '新浪股票大盘',
            \ 'hooks' : {}}

let s:unite_source = [s:source_stock_hq, s:source_stock_5d]

function! s:http_get()

    let l:suggest_url = '"http://suggest3.sinajs.cn/suggest/type=&key=' . s:input . '"'
    let l:suggest_ret = system('curl -s ' . suggest_url  . ' | iconv -f gbk -t utf-8')
    let l:suggest_info = matchstr(suggest_ret, '"\zs.\{-}\ze"')
    let l:stock_info_mul = split(l:suggest_info, ';')

    let l:stock_info =
        \ filter(l:stock_info_mul, 'v:val =~ "sh[0-9]" || v:val =~ "sz[0-9]"')

    if len(l:stock_info) == 1
        let s:stock_code = split(l:stock_info[0], ',')[3]
    else
        let l:i = 0
        echo "\n"
        while l:i < len(l:stock_info)
            echo l:i . ': ' . split(l:stock_info[l:i], ',')[4]
            let l:i = l:i + 1
        endwhile

        let l:stock_index = unite#util#input('Enter stock index: ', '')
        let s:stock_code = split(l:stock_info[l:stock_index], ',')[3]
    endif

    let l:content = system('curl -s http://hq.sinajs.cn/list=' . s:stock_code . ' | iconv -f gbk -t utf-8')
    let l:info = matchstr(content, '"\zs.\{-}\ze"')

    let l:list = split(info, ",")
    return list

endfunction

function! s:get_dang_info()

    let l:list = s:http_get()

    if len(l:list) < 10
        return []
    endif

    let l:stock_info = [
            \ "股票名称 : ". l:list[0],
            \ "当前价格 : ". '*'. l:list[3],
            \ "--------------------",
            \ "买一     : ". l:list[10],
            \ "买一报价 : ". l:list[11],
            \ "买二     : ". l:list[12],
            \ "买二报价 : ". l:list[13],
            \ "买三     : ". l:list[14],
            \ "买三报价 : ". l:list[15],
            \ "买四     : ". l:list[16],
            \ "买四报价 : ". l:list[17],
            \ "买五     : ". l:list[18],
            \ "买五报价 : ". l:list[19],
            \ "-------------------",
            \ "卖一     : ". l:list[20],
            \ "卖一报价 : ". l:list[21],
            \ "卖二     : ". l:list[22],
            \ "卖二报价 : ". l:list[23],
            \ "卖三     : ". l:list[24],
            \ "卖三报价 : ". l:list[25],
            \ "卖四     : ". l:list[26],
            \ "卖四报价 : ". l:list[27],
            \ "卖五     : ". l:list[28],
            \ "卖五报价 : ". l:list[29]]

    return map(l:stock_info, "{
            \ 'word' : v:val,
            \ 'kind' : 'url',
            \ 'is_multiline' : 1,
            \ 'source' : 'stock'}")
endfunction

function! s:get_stock_info()
    let l:list = s:http_get()

    if len(l:list) < 10
        return []
    endif


    let l:up =  (str2float(l:list[3]) - str2float(l:list[2])) * 100 / str2float(l:list[2])

    let l:stock_info = [
            \ "股票名称 : ". l:list[0],
            \ "股票代码 : ". s:stock_code,
            \ "当前日期 : ". l:list[30],
            \ "当前时间 : ". l:list[31],
            \ "今日开盘 : ". l:list[1],
            \ "昨日收盘 : ". l:list[2],
            \ "当前价格 : ". '*'. l:list[3],
            \ "上涨幅度 : ". string(l:up) . "%",
            \ "今日最高 : ". l:list[4],
            \ "今日最低 : ". l:list[5],
            \ "成交股票 : ". l:list[8],
            \ "成交金额 : ". l:list[9]]

    return map(l:stock_info, "{
            \ 'word' : v:val,
            \ 'kind' : 'url',
            \ 'is_multiline' : 1,
            \ 'source' : 'stock'}")
endfunction

" sina stock api
"
" http://suggest3.sinajs.cn/suggest/type=&key=lmkj&name=suggestdata_1427680265517
" http://hq.sinajs.cn/list=sz300369
" var suggestdata_1427680265517="lmkj,11,300369,sz300369,绿盟科技,lmkj";
" http://hq.sinajs.cn/rn=1427697590107&list=s_sh000001,s_sz399001
" http://hq.sinajs.cn/rn=1427697590184&list=s_sh601668,s_sh601800

function! s:source_stock_hq.change_candidates(args, context)
    return s:get_stock_info()
endfunction

function! s:source_stock_5d.change_candidates(args, context)
    return s:get_dang_info()
endfunction

function! unite#sources#stock#define()
    return s:unite_source
endfunction

function! s:source_stock_hq.hooks.on_init(args, context)
    let l:input = get(a:args, 0, '')
    let l:input = l:input != '' ? l:input :
                \ unite#util#input('Enter stock code: ', '')
    let s:input = l:input == '' ? 'Invalid input' : l:input
endfunction

function! s:source_stock_5d.hooks.on_init(args, context)
    let l:input = get(a:args, 0, '')
    let l:input = l:input != '' ? l:input :
                \ unite#util#input('Enter stock code: ', '')
    let s:input = l:input == '' ? 'Invalid input' : l:input
endfunction

function! s:source_stock_hq.hooks.on_syntax(args, context)
    syntax match uniteSource__stock_kw /:\|\*/
                \ contained containedin=uniteSource__Stock
    syntax match uniteSource__stock_pos / .\+%/
                \ contained containedin=uniteSource__Stock
    highlight default link uniteSource__stock_kw Keyword
    highlight default link uniteSource__stock_pos Constant
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
