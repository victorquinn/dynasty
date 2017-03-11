#### create

* `dynasty.create('Lands', {key_schema: { hash: ['name', 'string']}, ... }) ⇒ promise`
* `dynasty.create('Lands', {key_schema: { hash: ['name', 'string']}, ... }, <callback>)`

*Use: Create a Dynamo table with the specified key schema.*

Simplest case, the first argument is the name of the table, the second is an
object with at least a key_schema key.

```js
dynasty
    .create('Lands', { key_schema: { hash: ['name', 'string'] } })
    .then(function(resp) {
		// Your table has been created!
    });
```

In this simplest case, we'll default the throughput for you at:

`5 write units/10 read units`

Optionally specify the throughput:

```js
var table_options = {
    key_schema: { hash: ['name', 'string'] },
    throughput: { write: 5, read: 10 }
};

dynasty
    .create('Lands', table_options)
    .then(function(resp) {
        // Your table has been created!
    });
```

Optionally specify a callback function:

```js
dynasty.create('Lands', { key_schema: { hash: ['name', 'string'] } }, function(err, resp) {
    if (err) {
        // Something went wrong!
    } else {    
        // Your table has been created!
        console.log(resp);
    }
});
```

Optionally specify a range key when creating the table:

```js
dynasty
    .create('Counties', { key_schema: {
        hash: ['country', 'string'],
        range: ['county', 'string']
    } })
    .then(function(resp) {
        // Your table has been created!
    });
```
