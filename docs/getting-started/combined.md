Ok, so putting all these snippets together, we have:

```js
var credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
};

// Set up Dynasty with the AWS credentials
var dynasty = require('dynasty')(credentials);

// Get the Dynasty table object representing the table you want to work with
var users = dynasty.table('UserData');

// Fire off the query, putting its result in the promise
var promise = users.find('victorquinn');

// Add a promise success handler for when the call returns
promise.then(function(user) {
    console.log(user.first);
});
```

And that's it! Many more examples below for each specific method.
