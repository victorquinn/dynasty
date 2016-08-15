#### alter

* `dynasty.alter('Lands', { throughput: { read: 25, write: 50 } }) ⇒ promise`
* `dynasty.alter('Lands', { throughput: { read: 25, write: 50 } }, <callback>)`

*Use: Alter a table.*

Note: The only use case Amazon supports for altering is changing the throughput. There is no way, at current, to rename a table or alter its key schema with this method in this library.

```js
dynasty
    .alter('Lands', { throughput: { read: 25, write: 50 } })
    .then(function(resp) {
        // Throughput has been updated!
    });
```

Optionally specify a callback function

```js
dynasty.alter('Lands', { throughput: { read: 25, write: 50 } }, function(err, resp) {
    if (err) {
        // Something went wrong!
    } else {
        // Throughput has been updated!
        console.log(resp);
    }
});
```
