#### update

* `lands.update(<hashkey>, <object>) ⇒ promise`
* `lands.update(<hashkey>, <object>, <callback>)`
* `lands.update({ hash: <hashkey>, range: <rangekey> }, <object>) ⇒ promise`

*Use: Update an item in a table.*

Simplest case, just supply the key and an object specifying the keys/attributes to update.

```js
lands
    .update('China', { population: 1360000000 })
    .then(function(resp) {
        console.log(resp);
    });
```

Can of course provide a traditional node callback.

```js
lands.update('China', { population: 1360000000 }, function(err, resp) {
    console.log(resp);
});
```

Can provide multiple keys/values and each key will be updated on the object
matching your provided key

```js
// Will update both the population and capital for the item with the hash key of
// China in our DynamoDB table
lands
    .update('China', {
        population: 1360000000,
        capital: 'Beijing'
    })
    .then(function(resp) {
        console.log(resp);
    });
```

Can be used with a complex hash/range key as well of course

```js
states
    .update({ hash: 'United States', range: 'Virginia' }, {
        population: 8326289,
        capital: 'Richmond'
    })
    .then(function(resp) {
        console.log(resp);
    });
```

