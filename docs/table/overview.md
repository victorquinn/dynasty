All of the methods in this section act on **Tables**.

As such, for all the following examples, we'll assume the setup has been,
so there's a dynasty object with credentials already instantiated.

In other words, we're going to assume the following code has been run already:

```js
var credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
};

var dynasty = require('Dynasty')(credentials);
```

Further, all of these **Table** methods operate one of two ways:

1. You can create and build a **Table** object, then call the method on that table
   object to enact the method.
   
   -- OR --
   
2. You can call them directly on the dynasty object, passing in as an argument
   an object which represents the attributes of the **Table** on which you'd
   like to perform the operation.
   
We'll show examples of both modes of operation below.
