#### list

* `dynasty.list() ⇒ promise`
* `dynasty.list(<offset table name>) ⇒ promise`
* `dynasty.list({limit: <limit>}) ⇒ promise`
* `dynasty.list({offset: <table name>, limit: <limit>}) ⇒ promise`
* `dynasty.list({offset: <table name>, limit: <limit>}, <callback>) ⇒ promise`
* `dynasty.list(<callback>)`

*Use: List all of your Dynamo tables*

Simplest case, just call it.

```js
dynasty
    .list()
    .then(function(resp) {
        // List tables
        console.log(resp.tables);
    });
```

Optionally specify the name of a table to start the list. This is useful for
paging.

If you had previously done a `list()` command and there were more tables
than a response can handle, you would have received an `offset` with the response which was the last table it could return. Pass this back in a subsequent request to start the list where you left off.

```js
// First time
dynasty.list()
    .then(function(resp) {
        // Resp looks like:
        // { tables: [...], offset: 'last' }

        // to fetch the next batch, call it again, this time by supplying
        // the offset
        return dynasty.list(resp.offset);
    })
    .then(function(resp) {
        // Now you've got the next batch
        // { tables: [...], offset: 'last2' }
    });
```

If you are at the end of the list or do not have enough tables to get an offset, the offset will be an empty string.

Optionally specify a limit which is the max number of table names to return.

Useful for paging.

```js
dynasty.list({ limit: 3 })
    .then(function(resp) {
        // List 3 tables
        console.log(resp.TableNames);

        // Name of Last Table Returned, to be used if following up with another
        // request so you can start where you left off.
        console.log(resp.LastEvaluatedTableName);
    });
```

Optionally specify a callback function with or without other arguments.

```js
dynasty.list(function(err, resp) {
    if (err) // Something went wrong!
    
    // List tables
    console.log(resp.TableNames);
});
```

Of course this can be used with generators in Node 7.x+ (or with Babel on earlier versions of Node):

```js

async function listTables() {
    const tables = await dynasty.list();
    console.log(tables);
}

listTables();

```
