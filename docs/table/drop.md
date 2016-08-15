#### drop

* `dynasty.drop('Lands') ⇒ promise`
* `dynasty.drop('Lands', <callback>)`

*Use: Drop a table.*

Simplest case, just provide the name of the table to be dropped.

```js
dynasty
    .drop('Lands')
    .then(function(resp) {
        // Your table has been dropped!
    });
```

Optionally specify a callback function

```js
dynasty.drop('Lands', function(err, resp) {
    if (err) {
        // Something went wrong!
    } else {
        // Your table has been created!
        console.log(resp);
    }
});
```
