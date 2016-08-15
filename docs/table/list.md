#### list

* `dynasty.list() ⇒ promise`
* `dynasty.list(<table name>) ⇒ promise`
* `dynasty.list({limit: <limit>}) ⇒ promise`
* `dynasty.list({start: <table name>, limit: <limit>}) ⇒ promise`
* `dynasty.list({start: <table name>, limit: <limit>}, <callback>) ⇒ promise`
* `dynasty.list(<callback>)`

*Use: List tables*

Simplest case, just call it.

```js
dynasty
    .list()
    .then(function(resp) {
        // List tables
        console.log(resp.TableNames);
    });
```

Optionally specify the name of a table to start the list. This is useful for
paging.

If you had previously done a `list()` command and there were more tables
than a response can handle, you would have received a `LastEvaluatedTableName` with the response which was the last table it could return. Pass this back in a subsequent request to start the list where you left off.

```js
dynasty
    .list('Lands')
    .then(function(resp) {
        // List tables
        console.log(resp.TableNames);
    });
```

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
