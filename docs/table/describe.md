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

The return value for `describe()` is currently unaltered from the format Amazon sends. For consistency with the rest of this library it would probably make sense to reformat it into a cleaner format, but it's rather large so it would take a lot of work to figure out cleaner analogues for every key (and we haven't done that work yet) so currently we just send it back raw.

Look in [their docs](http://vq.io/GEFijX) for more details.
