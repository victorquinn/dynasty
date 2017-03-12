#### count

* `lands.count() ⇒ promise`
* `lands.count(<callback>)`

*Use: Count the number of items in a table*

Simplest case, just call the count

```js
lands
    .count()
    .then(function(cnt) {
        // Will be the number of items in the lands table
        console.log(cnt);
    });
```

Optionally, supply a callback

```js
lands.count(function(err, cnt) {
    if (err !== null) {
        console.log("There was some error with the count", err);
    } else {
        // Will be the number of items in the lands table
        console.log(cnt);
    }
});
```
