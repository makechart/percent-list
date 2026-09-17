module.exports =
  pkg:
    name: 'percent-list', version: '0.0.1'
    extend: {name: "@makechart/base"}
    dependencies: []
    i18n:
      "zh-TW": "other": "其它"
  init: ({root, context, pubsub, t}) ->
    pubsub.fire \init, mod: mod {context, t}

mod = ({context, t}) ->
  {chart,d3,wrapSvgText,debounce} = context
  sample: ->
    raw: [
      "Bachchan Pandey", "The Good Maharaja", "Ramprasad Ki Tehrvi",
      "Madam Chief Minister", "Satya Sai Baba", "Lahore Confidential",
      "Sandeep Aur Pinky Faraar", "Silence... Can You Hear It?"
      "Hum Bhi Akele Tum Bhi Akele", "Radhe", "Shaadisthan",
      "Chandigarh Kare Aashiqui", "Gangubai Kathiawadi", "Attack",
      "The Battle of Bhima Koregaon", "Tadap", "Looop Lapeta"
      ].map (val) ~> {val: Math.random!, name: val}
    binding:
      name: {key: \name}
      value: {key: \val}
  config: chart.utils.config.from({
    preset: \default
    label: \label
  })
  dimension:
    value: {type: \R, name: "value", priority: 20}
    name: {type: \N, name: "name", priority: 10}
  init: ->
    @g =
      view: d3.select @layout.get-group \view
      link: d3.select @layout.get-group \link
      legend: d3.select @layout.get-group \legend
    @tint = tint = new chart.utils.tint!
    @scale =
      y: d3.scaleLinear!
    @layout.get-group \view .addEventListener \mousemove, (evt) ~>
      if !((n = evt.target) and n.nodeName.toLowerCase! == \rect) => return
      @idx = Array.from(n.parentNode.childNodes).indexOf(n)
      @render-debounced!
    @render-debounced = debounce 350, ~> @render!

  parse: ->
    @cfg.{}collapse.enabled = false
    @parsed = @data.map -> {} <<< it
    @parsed.sort (a,b) -> b.value - a.value
    if @cfg.collapse.enabled =>
      if @cfg.collapse.method == \count =>
        other = @parsed.splice(@cfg.collapse.threshold or 7)
        if other.length => @parsed.push {name: t("other"), value: other.reduce(((a,b) -> a + b.value),0)}
      else # == \percent
        [total,sum] = [@parsed.reduce(((a,b) -> a + b.value),0), 0]
        for idx from 0 til @parsed.length =>
          sum += @parsed[idx].value
          if (sum / total) > (@cfg.collapse.threshold or 0.75) => break
        other = @parsed.splice(idx + 1)
        if other.length => @parsed.push {name: t("other"), value: other.reduce(((a,b) -> a + b.value),0)}
    @tint.reset!
    @parsed.map ~> @tint.get(it.name or it._idx)

    offset = 0
    for i from 0 til @parsed.length =>
      ret = @parsed[i]
      ret.offset = offset
      offset += ret.value
    @total = offset or 1

  resize: ->
    @layout.update false
    node = @layout.get-node \legend
    node.textContent = ""
    @parsed.map ~>
      div = document.createElement \div
      p = (100 * (it.value / @total)).toFixed(1)
      div.textContent = it.text = "#{it.name} / #p%"
      node.appendChild div

    @local.measure!
    @lbox = @layout.get-box \link
    box = @layout.get-box \view
    @layout.update false
    box = @layout.get-box \view
    [w,h] = [box.width, box.height]
    size = Math.min(w,h)
    @scale.y.range [0, box.height] .domain [0, @total]
    @resized = true


  render: ->
    # 標籤的位置是從 legend 那份 html 量出來的. 量是在 resize 做的, 但字型晚一步載入、
    # 根字級改變這類事情會讓文字重排卻不會觸發 resize, 量到的值就過期了 -
    # 過期的 rbox 會讓整組標籤往下飄, 一路飄到圖外. 每次畫之前重量一次, 就幾個
    # getBoundingClientRect, 本來 resize 也是這樣量的
    @local.measure!
    {total,cfg,layout,tint,scale,nboxes,rbox,lbox,resized} = @
    self = @
    picked-of = (d) ~> @local.picked-of d
    # partial: 每一條色塊沿寬度切, 左邊那段是被選中的部分. 色塊的高度 ( 也就是占比 )
    # 來自未篩選的全體, 所以別張圖的篩選不會讓這裡的項目消失或重排
    partial = (@subset.mode! == \partial) and !!@_subset
    color-of = (d, i) -> tint.get Math.ceil(((d.offset + d.value/2) / total) * 5)
    ratio-of = (d) -> if !(d.subset and d.value) => 0 else (0 >? ((d.subset.value or 0) / d.value) <? 1)
    if @cfg? and @cfg.palette => @tint.set(@cfg.palette.colors.map -> it.value or it)
    box = @layout.get-box \view
    offset = 0
    if (@idx?) and nboxes.length =>
      @idx = (@idx <? @nboxes.length - 1 >? 0)
      offset = nboxes[@idx]y - rbox.y
      last = nboxes[* - 1].y + nboxes[* - 1].height - rbox.y
      if last - offset < rbox.height => offset = last - rbox.height
      # offset 是「把標籤往上捲多少」, 給項目太多放不下時用的. 上面那條夾擠是不讓它捲過頭,
      # 但全部放得下時 last < rbox.height, 夾出來的是負數 - 負的等於往下推,
      # 整組標籤會被推到區塊底部然後掉出圖外. 全部放得下就不該捲, 也就是 0
      offset = offset >? 0

    @g.view.selectAll \rect.data .data @parsed
      ..exit!remove!
      ..enter!append \rect .attr \class, \data
    @g.view.selectAll \rect.data
      ..attr \x, -> 0
      ..attr \y, (d,i) -> scale.y(d.offset)
      ..attr \width, -> box.width
      ..attr \height, (d,i) -> (scale.y(d.offset + d.value) - scale.y(d.offset) - 1) >? 1
      ..attr \fill-opacity, (d,i) -> picked-of d
      ..attr \fill, (d,i) ->
        c = color-of d, i
        return if partial => self.subset.color(c) else c
        ret = tint.get 0, (((i % 3) - 1) / 5)
        if cfg.collapse.enabled =>
          nbox = nboxes[i]
          y1 = (nbox.y - rbox.y) + (nbox.height / 2)
          if y1 < rbox.height => return ret
          ret = ldcolor.hcl(ret)
          ret.c = ret.c * 0.1
          ret.l = ret.l * 1.1
        return ldcolor.web(ret)
    # partial 的那一層: 蓋在上面但不吃事件, 點擊一律由底下那條處理
    subsets = if !partial => [] else @parsed
    @g.view.selectAll \rect.subset .data subsets
      ..exit!remove!
      ..enter!append \rect .attr \class, \subset .style \pointer-events, \none
    @g.view.selectAll \rect.subset
      ..attr \x, -> 0
      ..attr \y, (d,i) -> scale.y(d.offset)
      ..attr \width, (d,i) -> box.width * ratio-of(d)
      ..attr \height, (d,i) -> (scale.y(d.offset + d.value) - scale.y(d.offset) - 1) >? 1
      ..attr \fill-opacity, (d,i) -> picked-of d
      ..attr \fill, (d,i) -> color-of d, i

    @g.legend.selectAll \g.label.data .data @parsed
      ..exit!remove!
      ..enter!append \g .attr \class, 'label data'
    @g.legend.selectAll \g.label.data
      .each (d,i) ->
        if resized or @_text != d.text =>
          @_text = d.text
          n = layout.get-node \legend .childNodes[i]
          ret = wrap-svg-text node: n, use-range: true
          @textContent = ""
          @appendChild ret
      .transition!duration 350
      .attr \opacity, (d,i) ->
        nbox = nboxes[i]
        y = nbox.y - rbox.y - offset
        if y < 0 or y > rbox.height - nbox.height/2 => 0 else picked-of d
      .attr \transform, (d,i) ->
        nbox = nboxes[i]
        "translate(#{nbox.x - rbox.x}, #{nbox.y - rbox.y - offset})"
    @g.link.selectAll \path .data @parsed
      ..exit!remove!
      ..enter!append \path
        .attr \fill, \none
        .attr \stroke-width, 1
    @g.link.selectAll \path
      #.attr \stroke, cfg.line
      .attr \stroke, (d,i) ->
        return tint.get Math.ceil(((d.offset + d.value/2) / total) * 5)
      .transition!duration 350
      .attr \d, (d,i) ->
        x0 = 0
        x1 = lbox.width / 10
        x2 = 9 * lbox.width / 10
        x3 = lbox.width
        y0 = scale.y(d.offset + d.value / 2)
        nbox = nboxes[i]
        y1 = (nbox.y - rbox.y) + (nbox.height / 2) - offset
        if Math.abs(y1 - y0) < 2 => y1 = y0
        "M#x0 #y0 L#x1 #y0 L#x2 #y1 L#x3 #y1"
      .attr \opacity, (d,i) ->
        nbox = nboxes[i]
        y0 = scale.y(d.offset + d.value / 2)
        y1 = (nbox.y - rbox.y) + (nbox.height / 2) - offset
        if Math.abs(y1 - y0) < 2 => y1 = y0
        return if y1 > (rbox.height) or y1 < 0 => 0 else picked-of d
    @resized = false

  # 這張圖自己的工具方法. `local` 是核心保留給圖表的位置, 核心不管裡面有什麼,
  # 建構時會綁到實例上, 所以呼叫端寫 `@local.xxx()` 就好
  local:

    # 量出每個標籤在 legend 那份 html 裡的位置. svg 的標籤照這份結果擺,
    # 所以這份一過期, 標籤就會擺錯地方
    measure: ->
      node = @layout.get-node \legend
      if !node or node.childNodes.length != @parsed.length => return
      @nboxes = @parsed.map (d,i) ~> node.childNodes[i].getBoundingClientRect!
      @rbox = node.getBoundingClientRect!

    # 這張圖自己不發 filter ( 點選由 host 用 select 代打 ), 但 host 會把選取灌回
    # binding.name.filter, 所以我們知道自己身上哪幾項被選中, 可以畫出來
    picked-of: (d) ->
      f = ((@binding.name or {}).filter or {}).value
      # f 是 [] 表示「什麼都沒選」, 跟「沒有篩選」不一樣
      if !f => return 1
      if d.name in f => 1
      else (((@cfg.common or {}).subset or {}).opacity ? 0.2)
