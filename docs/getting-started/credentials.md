## credentials

There are several ways in Dynasty to supply your credentials to Amazon DynamoDB. Some of these are more secure and others afford greater convenience while developing an application. 

Here are the ways you can supply your credentials in order of recommendation:

- Loaded from AWS Identity and Access Management (IAM) roles for Amazon EC2 or ECS

- Loaded from the shared credentials file (~/.aws/credentials)

- Loaded from environment variables

- Explicitly provided in the Dynasty constructor

Please see the AWS Node.js SDK documentation to learn more about specifying [credential][SDK] and [region][Region] values.

### Explicitly providing your credentials and region

Amazon uses a 2 key system for access to its APIs. They are the *Access Key Id* and
the *Secret Access Key*.

Simply create an object with at least these 2 keys and your specific keys as the
values:

```js
var credentials = {
    accessKeyId: '<YOUR ACCESS_KEY_ID>',
    secretAccessKey: '<YOUR_SECRET_ACCESS_KEY>',
    region: '<YOUR_REGION_VALUE>'
};
```

Your `accessKeyId` and `secretAccessKey` can be obtained in the
[AWS console][AWS] under the IAM (Identity Account Management) menu which has
a green key as its icon.

Amazon recommends that you create a new User to limit access to DynamoDB
if you haven't already.

[More info on getting started with credentials][GettingStarted]

So rather than the text strings appearing in your code (and worse, getting
committed to your repo!), set them as environment variables and load them
in your code as follows:

```js
var credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    region: process.env.AWS_DEFAULT_REGION
};
```

For example, to use the *eu-west-1* region based in Ireland, use the following
credentials:

```js
var credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: 'eu-west-1'
};
```

Only this short string is necessary to specify the region, **Dynasty** will convert
it into the full endpoint URL for you.

[SDK]: https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-credentials-node.html
[Region]: https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-region.html
[AWS]: https://console.aws.amazon.com/iam/home?#users
[GettingStarted]: http://docs.aws.amazon.com/IAM/latest/UserGuide/IAMGettingStarted.html
