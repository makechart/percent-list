(function(){
  var mod;
  module.exports = {
    pkg: {
      name: 'percent-list',
      version: '0.0.1',
      extend: {
        name: "base",
        version: "0.0.1"
      },
      dependencies: [],
      i18n: {
        "zh-TW": {
          "other": "其它"
        }
      }
    },
    init: function(arg$){
      var root, context, pubsub, t;
      root = arg$.root, context = arg$.context, pubsub = arg$.pubsub, t = arg$.t;
      return pubsub.fire('init', {
        mod: mod({
          context: context,
          t: t
        })
      });
    }
  };
  mod = function(arg$){
    var context, t, chart, d3, wrapSvgText, debounce;
    context = arg$.context, t = arg$.t;
    chart = context.chart, d3 = context.d3, wrapSvgText = context.wrapSvgText, debounce = context.debounce;
    return {
      sample: function(){
        return {
          raw: ["Bachchan Pandey", "The Good Maharaja", "Ramprasad Ki Tehrvi", "Madam Chief Minister", "Satya Sai Baba", "Lahore Confidential", "Sandeep Aur Pinky Faraar", "Silence... Can You Hear It?", "Hum Bhi Akele Tum Bhi Akele", "Radhe", "Shaadisthan", "Chandigarh Kare Aashiqui", "Gangubai Kathiawadi", "Attack", "The Battle of Bhima Koregaon", "Tadap", "Looop Lapeta"].map(function(val){
            return {
              val: Math.random(),
              name: val
            };
          }),
          binding: {
            name: {
              key: 'name'
            },
            value: {
              key: 'val'
            }
          }
        };
      },
      config: chart.utils.config.from({
        preset: 'default',
        label: 'label'
      }),
      dimension: {
        value: {
          type: 'R',
          name: "value",
          priority: 20
        },
        name: {
          type: 'N',
          name: "name",
          priority: 10
        }
      },
      init: function(){
        var tint, this$ = this;
        this.g = {
          view: d3.select(this.layout.getGroup('view')),
          link: d3.select(this.layout.getGroup('link')),
          legend: d3.select(this.layout.getGroup('legend'))
        };
        this.tint = tint = new chart.utils.tint();
        this.scale = {
          y: d3.scaleLinear()
        };
        this.layout.getGroup('view').addEventListener('mousemove', function(evt){
          var n;
          if (!((n = evt.target) && n.nodeName.toLowerCase() === 'rect')) {
            return;
          }
          this$.idx = Array.from(n.parentNode.childNodes).indexOf(n);
          return this$.renderDebounced();
        });
        return this.renderDebounced = debounce(350, function(){
          return this$.render();
        });
      },
      parse: function(){
        var ref$, other, total, sum, i$, to$, idx, offset, i, ret, this$ = this;
        ((ref$ = this.cfg).collapse || (ref$.collapse = {})).enabled = false;
        this.parsed = this.data.map(function(it){
          return import$({}, it);
        });
        this.parsed.sort(function(a, b){
          return b.value - a.value;
        });
        if (this.cfg.collapse.enabled) {
          if (this.cfg.collapse.method === 'count') {
            other = this.parsed.splice(this.cfg.collapse.threshold || 7);
            if (other.length) {
              this.parsed.push({
                name: t("other"),
                value: other.reduce(function(a, b){
                  return a + b.value;
                }, 0)
              });
            }
          } else {
            ref$ = [
              this.parsed.reduce(function(a, b){
                return a + b.value;
              }, 0), 0
            ], total = ref$[0], sum = ref$[1];
            for (i$ = 0, to$ = this.parsed.length; i$ < to$; ++i$) {
              idx = i$;
              sum += this.parsed[idx].value;
              if (sum / total > (this.cfg.collapse.threshold || 0.75)) {
                break;
              }
            }
            other = this.parsed.splice(idx + 1);
            if (other.length) {
              this.parsed.push({
                name: t("other"),
                value: other.reduce(function(a, b){
                  return a + b.value;
                }, 0)
              });
            }
          }
        }
        this.tint.reset();
        this.parsed.map(function(it){
          return this$.tint.get(it.name || it._idx);
        });
        offset = 0;
        for (i$ = 0, to$ = this.parsed.length; i$ < to$; ++i$) {
          i = i$;
          ret = this.parsed[i];
          ret.offset = offset;
          offset += ret.value;
        }
        return this.total = offset || 1;
      },
      resize: function(){
        var node, box, ref$, w, h, size, this$ = this;
        this.layout.update(false);
        node = this.layout.getNode('legend');
        node.textContent = "";
        this.parsed.map(function(it){
          var div, p;
          div = document.createElement('div');
          p = (100 * (it.value / this$.total)).toFixed(1);
          div.textContent = it.text = it.name + " / " + p + "%";
          return node.appendChild(div);
        });
        this.nboxes = this.parsed.map(function(d, i){
          return this$.layout.getNode('legend').childNodes[i].getBoundingClientRect();
        });
        this.rbox = this.layout.getNode('legend').getBoundingClientRect();
        this.lbox = this.layout.getBox('link');
        box = this.layout.getBox('view');
        this.layout.update(false);
        box = this.layout.getBox('view');
        ref$ = [box.width, box.height], w = ref$[0], h = ref$[1];
        size = Math.min(w, h);
        this.scale.y.range([0, box.height]).domain([0, this.total]);
        return this.resized = true;
      },
      render: function(){
        var total, cfg, layout, tint, scale, nboxes, rbox, lbox, resized, box, offset, ref$, ref1$, ref2$, last, x$, y$, z$, z1$;
        total = this.total, cfg = this.cfg, layout = this.layout, tint = this.tint, scale = this.scale, nboxes = this.nboxes, rbox = this.rbox, lbox = this.lbox, resized = this.resized;
        if (this.cfg != null && this.cfg.palette) {
          this.tint.set(this.cfg.palette.colors.map(function(it){
            return it.value || it;
          }));
        }
        box = this.layout.getBox('view');
        offset = 0;
        if (this.idx != null && nboxes.length) {
          this.idx = (ref$ = (ref1$ = this.idx) < (ref2$ = this.nboxes.length - 1) ? ref1$ : ref2$) > 0 ? ref$ : 0;
          offset = nboxes[this.idx].y - rbox.y;
          last = nboxes[nboxes.length - 1].y + nboxes[nboxes.length - 1].height - rbox.y;
          if (last - offset < rbox.height) {
            offset = last - rbox.height;
          }
        }
        x$ = this.g.view.selectAll('rect.data').data(this.parsed);
        x$.exit().remove();
        x$.enter().append('rect').attr('class', 'data');
        y$ = this.g.view.selectAll('rect.data');
        y$.attr('x', function(){
          return 0;
        });
        y$.attr('y', function(d, i){
          return scale.y(d.offset);
        });
        y$.attr('width', function(){
          return box.width;
        });
        y$.attr('height', function(d, i){
          var ref$;
          return (ref$ = scale.y(d.offset + d.value) - scale.y(d.offset) - 1) > 1 ? ref$ : 1;
        });
        y$.attr('fill', function(d, i){
          var ret, nbox, y1;
          return tint.get(Math.ceil(((d.offset + d.value / 2) / total) * 5));
          ret = tint.get(0, (i % 3 - 1) / 5);
          if (cfg.collapse.enabled) {
            nbox = nboxes[i];
            y1 = (nbox.y - rbox.y) + nbox.height / 2;
            if (y1 < rbox.height) {
              return ret;
            }
            ret = ldcolor.hcl(ret);
            ret.c = ret.c * 0.1;
            ret.l = ret.l * 1.1;
          }
          return ldcolor.web(ret);
        });
        z$ = this.g.legend.selectAll('g.label.data').data(this.parsed);
        z$.exit().remove();
        z$.enter().append('g').attr('class', 'label data');
        this.g.legend.selectAll('g.label.data').each(function(d, i){
          var n, ret;
          if (resized || this._text !== d.text) {
            this._text = d.text;
            n = layout.getNode('legend').childNodes[i];
            ret = wrapSvgText({
              node: n,
              useRange: true
            });
            this.textContent = "";
            return this.appendChild(ret);
          }
        }).transition().duration(350).attr('opacity', function(d, i){
          var nbox, y;
          nbox = nboxes[i];
          y = nbox.y - rbox.y - offset;
          if (y < 0 || y > rbox.height - nbox.height / 2) {
            return 0;
          } else {
            return 1;
          }
        }).attr('transform', function(d, i){
          var nbox;
          nbox = nboxes[i];
          return "translate(" + (nbox.x - rbox.x) + ", " + (nbox.y - rbox.y - offset) + ")";
        });
        z1$ = this.g.link.selectAll('path').data(this.parsed);
        z1$.exit().remove();
        z1$.enter().append('path').attr('fill', 'none').attr('stroke-width', 1);
        this.g.link.selectAll('path').attr('stroke', function(d, i){
          return tint.get(Math.ceil(((d.offset + d.value / 2) / total) * 5));
        }).transition().duration(350).attr('d', function(d, i){
          var x0, x1, x2, x3, y0, nbox, y1;
          x0 = 0;
          x1 = lbox.width / 10;
          x2 = 9 * lbox.width / 10;
          x3 = lbox.width;
          y0 = scale.y(d.offset + d.value / 2);
          nbox = nboxes[i];
          y1 = (nbox.y - rbox.y) + nbox.height / 2 - offset;
          if (Math.abs(y1 - y0) < 2) {
            y1 = y0;
          }
          return "M" + x0 + " " + y0 + " L" + x1 + " " + y0 + " L" + x2 + " " + y1 + " L" + x3 + " " + y1;
        }).attr('opacity', function(d, i){
          var nbox, y0, y1;
          nbox = nboxes[i];
          y0 = scale.y(d.offset + d.value / 2);
          y1 = (nbox.y - rbox.y) + nbox.height / 2 - offset;
          if (Math.abs(y1 - y0) < 2) {
            y1 = y0;
          }
          return y1 > rbox.height || y1 < 0 ? 0 : 1;
        });
        return this.resized = false;
      }
    };
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
