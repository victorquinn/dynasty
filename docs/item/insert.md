#### insert

* `lands.insert(<object>) ⇒ promise`
* `lands.insert(<object>, <callback>)`

*Use: Insert an item into a table.*

Simplest case, just supply the item, everything else defaults.

```js
lands
    .insert({ name: 'China' })
    .then(function(resp) {
        console.log(resp);
    });
```

Note, your hash key and/or range key must be specified on the object you are inserting or it will fail.

In other words, if your hash key is `name` and you try to insert any object without a `name` key, you will get an error because the key must appear in the object so it can be properly inserted and indexed by DynamoDB.

```js
lands
    .insert({ population: 1375000000 })
    .then(function(resp) {
        console.log(resp);
    })
    .catch(function(err) {
        // Will get an error here about not including the hashKey!
    });
```


Can optionally supply a traditional node callback

```js
lands.insert({ name: 'China' }, null, function(err, resp) {
    console.log(resp);
});
```
