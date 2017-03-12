#### dropAll

* `dynasty.dropAll() ⇒ promise`
* `dynasty.dropAll(<callback>)`

*Use: Drop all Dynamo tables on this account.*

**NOTE: It should be apparent, but this is potentially very dangerous. Call at your own risk/peril**

Simplest case, just call it.

```js
dynasty
    .dropAll()
    .then(function(resp) {
        // All of your tables have been dropped!
    });
```

Optionally specify a callback function

```js
dynasty.dropAll(function(err, resp) {
    if (err) {
        // Something went wrong!
    } else {
        // All of your tables have been dropped
        console.log(resp);
    }
});
```
