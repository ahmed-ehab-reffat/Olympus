import * as vega from 'vega';
const tid = t => vega.tupleid(t);
const spec = {
  signals: [
    {name: 'src', value: [{k: 'a', v: 1}, {k: 'b', v: 2}]},
    {name: 'push', value: null, on: [{events: {signal: 'trig'}, update: "setdata('e', trig)"}]},
    {name: 'trig', value: null}
  ],
  data: [
    {name: 'd', key: 'k', values: [{k: 'a', v: 1, x: 5}, {k: 'b', v: 2}, {k: 'c', v: 3}]},
    {name: 'dd', source: 'd', transform: [{type: 'formula', expr: 'datum.v * 10', as: 'w'}]},
    {name: 'agg', source: 'd', transform: [{type: 'aggregate', ops: ['sum'], fields: ['v'], as: ['s']}]},
    {name: 'e', key: 'k'},
    {name: 'l', key: 'k', values: {signal: 'src'}}
  ]
};
const view = new vega.View(vega.parse(spec), {renderer: 'none'});
await view.runAsync();
const show = n => JSON.stringify(view.data(n).map(t => ({id: tid(t), ...t})));
console.log('d0', show('d'), show('dd'), show('agg'));
const before = view.data('d');
await view.data('d', [{k: 'c', v: 30}, {k: 'a', v: 1}, {k: 'z', v: 9}]).runAsync();
console.log('d1', show('d'), 'sameA', view.data('d')[1] === before[0]);
console.log('dd1', show('dd'), show('agg'));
const cur = view.data('d'); cur[0].v = 100;
await view.data('d', cur).runAsync();
console.log('d2 repassed', show('d'), show('dd'), show('agg'));
await view.signal('trig', [{k: 'q', v: 1}, {k: 'r', v: 2}]).runAsync();
const e0 = view.data('e');
await view.signal('trig', [{k: 'r', v: 5}]).runAsync();
console.log('setdata', show('e'), 'same r', view.data('e')[0] === e0[1]);
const l0 = view.data('l');
await view.signal('src', [{k: 'b', v: 7}, {k: 'a', v: 1}]).runAsync();
console.log('load1', show('l'), view.data('l')[0] === l0[1]);
await view.signal('src', [{k: 'a', v: 3}]).runAsync();
console.log('load2', show('l'), view.data('l')[0] === l0[0]);
const st = view.getState();
st.data.d = [{k: 'a', v: 42}];
view.setState(st); await view.runAsync();
console.log('setState', show('d'), view.data('d')[0] === before[0]);
