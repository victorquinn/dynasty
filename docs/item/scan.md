#### scan

* `lands.scan() ⇒ promise`
* `lands.scan(<callback>)`
* `lands.scan({ExclusiveStartKey: <startkey>}) = promise`

Scans and returns all items in a table as an array of objects.

You can optionally pass in the LastEvaluatedKey from a previously executed scan operation as the ExclusiveStartKey to implement paginated scans (when you have more than 1 MB of date and can't get it all in one go).

```js
lands
    .scan()
    .then(function(allLands) {
        // Iterate through allLands here and do stuff with it.
    });
```
