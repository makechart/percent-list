# percent-list 的 test case ( @makechart/viewer 的 mctest )
names = <[Taipei Taichung Kaohsiung Tainan Taoyuan Hsinchu Keelung Chiayi Yilan Hualien Taitung Nantou Miaoli Changhua Yunlin Pingtung Penghu]>
# 每份資料用自己的種子, 跟產生的先後順序無關
mk = (n) ->
  rnd = mctest.random n
  raw: names.slice(0, n).map (name) -> {name, val: Math.round(rnd! * 1000)}
  binding: {name: {key: \name}, value: {key: \val}}
with-subset = (d) ->
  r = mctest.random 8
  d.subset = d.raw.map -> {name: it.name, val: Math.round(it.val * r!)}
  d

mctest.suite do
  size: [520, 360]
  # hover 的重畫有 350ms debounce
  quiet: 500
  data:
    few: mk 4
    many: mk 17
    subset: with-subset mk 8
  cases:
    * name: "few", data: \few
    * name: "many", data: \many
    * name: "partial", data: \subset, config: {common: {subset: {mode: \partial}}}
    * name: "dim", data: \subset, config: {common: {subset: {mode: \dim}}}
    * name: "picked", data: \many
      steps: [(c) -> c.filter {name: {type: \index, value: <[Taipei Tainan]>}}]
    # 標籤放不下時, hover 某一條會把標籤捲到它那裡
    * name: "short", data: \many, size: [520, 200]
    * name: "hover-scroll", data: \many, size: [520, 200]
      steps:
        * (c, ctx) ->
            rects = ctx.root.querySelectorAll 'rect.data'
            rects[12].dispatchEvent new MouseEvent(\mousemove, {bubbles: true})
    * name: "update", data: \few
      steps: [(c) -> d = mk 6; c.set-raw d.raw, d.binding]

# lite 版才有: 用 anim 的 manual 時鐘拍動畫的中間格 ( d3 transition 拍不到 )
mctest.suite do
  size: [520, 360]
  quiet: 500
  data: {few: mk(4)}
  cases:
    * name: "anim:update-frames", data: \few
      steps: (c, ctx) ->
        d = mk 6
        c.set-raw d.raw, d.binding
        for i from 1 to 4
          c.anim.step 70
          ctx.capture "t#{i * 70}"
