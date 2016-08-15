#### batchFind

* `states.batchFind([<hashkey>, <hashkey>]) ⇒ promise`
* `counties.batchFind([{hash: <hashkey>, range: <rangekey>}, {hash: <hashkey>, range: <rangekey>}, ... ]) ⇒ promise`
* `states.batchFind([<hashkey>, <hashkey>], <callback>)`

*Use: Find multiple items in batch via a single call. That is find all the
items in a table associated with a hash key.*

Promise resolves with an array including all items matching your search.

```js
// Simplest case, table with only hash keys:
var promise = states.batchFind(['Virginia', 'Maryland', 'New York']);

promise.then(function(states) {
    // The states variable is an array including the full info on the
    // state that had a HashKey of 'Virginia', 'Maryland', or 'New York'
    states.forEach(function(state) {
        console.log(state.population);
    });
});

// Prints to the console:
// 8326289
// 5976407
// 19746227
```

In a more complex case, you can specify both the hash and range keys for each item you'd like returned:

```js
// More complex case, table with hash and range keys
counties
    .batchFind([
        { hash: 'Ireland', range: 'Cork' },
        { hash: 'Ireland', range: 'Galway' }
    ])
    .then(function(counties) {
        // The counties variable is an array including the full info on the
        // counties matching the supplied hash and range keys
        counties.forEach(function(county) {
            console.log(county);
        });
    });
```

Of course this method, like the others, can take a traditional node callback as well:

```js
// Simplest case, table with only hash keys:
states.batchFind(['Virginia', 'Maryland', 'New York'], function(err, states) {
    if (err) {
        // Handle error
    } else {
        // The states variable is an array including the full info on the
        // state that had a HashKey of 'Virginia', 'Maryland', or 'New York'
        states.forEach(function(state) {
            console.log(state.population);
        });
    }
});
```
