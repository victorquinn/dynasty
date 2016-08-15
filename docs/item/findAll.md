#### findAll

* `counties.findAll(<hashkey>) ⇒ promise`
* `counties.findAll(<hashkey>, <callback>)`

*Use: Find items in a table with a range key via the hash key. That is find all the items in a table associated with a hash key.*


```js
counties
    .findAll('Virginia')
    .then(function(counties) {
        counties.forEach(console.log);
    });
```

Rather than using the promise, you can use a traditional node callback

```js
counties.findAll('Virginia', function(err, counties) {
    if (err) {
        // Handle error
    } else {
        counties.forEach(console.log);
    }
});
```
