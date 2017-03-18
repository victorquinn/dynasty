#### alter

* `dynasty.alter('Lands', { throughput: { read: 25, write: 50 } }) ⇒ promise`
* `dynasty.alter('Lands', { throughput: { read: 25, write: 50 } }, <callback>)`
* `table.alter({ throughput: { read: 25, write: 50 } }) ⇒ promise`
* `table.alter({ throughput: { read: 25, write: 50 } }, <callback>)`

*Use: Alter a table with the specified options.*

##### With dynasty object

You can call this method on the main dynasty object, specifying the table name
as the first argument when calling it.

Note: The only use case Amazon supports for altering is changing the throughput.
There is no way, at current, to rename a table or alter its key schema with
this method in this library.

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

##### With table object

You can also create a table object then use that to call this method. When
calling it this way, there is no need to specify the name of the table since
it is in the table object.

For example:

```js
// Create a table object
lands = dynasty.table('Lands');

// Then call alter on it
dynasty
  .alter({ throughput: { read: 25, write: 50 } })
  .then((resp) => {
    // Your table has been altered!
  });
```

Of course this can be called with async/await on Node 7.x+ or with Babel

```js
// Create a table object
lands = dynasty.table('Lands');

// Then call alter on it
alterResponse = await dynasty.alter({ throughput: { read: 25 } })

// Your table has been altered!
```

