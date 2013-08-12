---
title: credentials
---

Amazon uses a 2 key system for access to its APIs. They are the *Access Key Id* and
the *Secret Access Key*.

Simply create an object with at least these 2 keys and your specific keys as the
values:

{% highlight js %}
var credentials = {
    accessKeyId: '<YOUR ACCESS_KEY_ID>',
    secretAccessKey: '<YOUR_SECRET_ACCESS_KEY>'
};
{% endhighlight %}

Your `accessKeyId` and `secretAccessKey` can be obtained in the
[AWS console][AWS] under the IAM (Identity Account Management) menu which has
a green key as its icon.

Amazon recommends that you create a new User to limit access to DynamoDB
if you haven't already.

[More info on getting started with credentials][GettingStarted]

Recommend storing these credentials in environment variables and loading them
in a config file.

So rather than the text strings appearing in your code (and worse, getting
committed to your repo!), set them as environment variables and load them
in your code as follows:

{% highlight js %}
var credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
};
{% endhighlight %}

Can optionally specify a region. If none is specified, *us-east-1* is the default.

For example, to use the *eu-west-1* region based in Ireland, use the following
credentials:

{% highlight js %}
var credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: 'eu-west-1'
};
{% endhighlight %}

Only this short string is necessary to specify the region, **Dynasty** will convert
it into the full endpoint URL for you.

[AWS]: https://console.aws.amazon.com/iam/home?#users
[GettingStarted]: http://docs.aws.amazon.com/IAM/latest/UserGuide/IAMGettingStarted.html
