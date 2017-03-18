#### describe

* `dynasty.describe('Lands') ⇒ promise`
* `dynasty.describe('Lands', <callback>)`

*Use: Describe a table.*

Call it from the dynasty object

```js
dynasty
    .describe('Lands')
    .then(function(resp) {
        // Log the description
        console.log(resp);
    });
```

The response will be a cleanly formatted object which looks like this:

```js
{
  arn: "arn:aws:dynamodb:ddblocal:000000000000:table/my_table_name",
  attributes: [ [ 'my_hash_key', 'string' ] ],
  bytes: 0,
  count: 0,
  created_at: 2017-03-18T15:54:08.814Z,
  key_schema: { hash: [ 'my_hash_key', 'string' ] },
  name: 'my_table_name',
  status: 'ACTIVE',
  throughput: {
     write: 5,
     read: 10,
     last_increased_at: 1970-01-01T00:00:00.000Z,
     last_decreased_at: 1970-01-01T00:00:00.000Z,
     decreases_today: 0
  }
}
```

Note: This is a change from Dynasty < 1.x. In prior versions, Dynasty returned the messy Amazon response directly, but now it will always return a nice clean response. However, this may require updating some code if you expect the response to be in the [Amazon format](http://vq.io/GEFijX).

Or create a table object and call it on that table object

```js
var lands = dynasty.table('Lands');

lands
    .describe()
    .then(function(resp) {
        // Log the description
        console.log(resp);
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
