#### remove

* `lands.remove(<hashkey>) ⇒ promise`
* `lands.remove({hash: <hashkey>}) ⇒ promise`
* `lands.remove(<hashkey>, <callback>)`
* `counties.remove({hash: <hashkey>, range: <rangekey>}) ⇒ promise`

*Use: Remove an item.*

Same flexible format as [find()](#find) above, can take any series of:
string/object, object/callback, callback

Simplest case, just supply a hash key, everything else defaults.

```js
lands
    .remove('Russia')
    .then(function(land) {
        console.log(land.name + ' has been deleted');
    });
```
