#### find

* `lands.find(<hashkey>) ⇒ promise`
* `lands.find({hash: <hashkey>}) ⇒ promise`
* `lands.find(<hashkey>, <callback>)`
* `counties.find({hash: <hashkey>, range: <rangekey>}) ⇒ promise`

*Use: Find items in a table*

Simplest case, just supply a hash key, everything else defaults.

```js
lands
    .find('France')
    .then(function(land) {
        console.log(land);
    });
```

We're incredibly flexible here though, so we can take all manners of input.

A series of examples below:

```js
// an object with a key of hash which represents the hash key
lands
    .find({ hash: 'France' })
    .then(function(land) {
        console.log(land);
    });

// an object with a key of hash and a key of range which represents the hash key
// and range key, for getting items from tables with a hash and range type
// primary key
counties
    .find({ hash: 'Ireland', range: 'Cork' })
    .then(function(land) {
        console.log(land);
    });

// an object with a string hash key and a callback function
lands.find('China', function(err, land) {
    console.log(land);
});

// and so on...
```
