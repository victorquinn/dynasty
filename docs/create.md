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
        // resp contains the details of the newly created table:
        //
        // {
        //   arn: 'arn:aws:dynamodb:ddblocal:000000000000:table/Lands',
        //   bytes: 0,
        //   count: 0,
        //   created_at: 2017-03-12T22:03:06.922Z,
        //   key_schema: { hash: [ 'name', 'string' ] },
        //   name: 'Lands',
        //   status: 'ACTIVE',
        //   throughput: {
        //     write: 5,
        //     read: 10,
        //     last_increased_at: 1970-01-01T00:00:00.000Z,
        //     last_decreased_at: 1970-01-01T00:00:00.000Z,
        //     decreases_today: 0
        //   },
        // }
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

Of course this can be used with async/await in Node 7.x+ (or with Babel on earlier versions of Node):

```js

async function createTable() {
    var table_options = {
        key_schema: { hash: ['name', 'string'] },
        throughput: { write: 5, read: 10 }
    };
    const table = await dynasty.create('Lands', table_options);
    console.log(table);
}

createTable();

```
