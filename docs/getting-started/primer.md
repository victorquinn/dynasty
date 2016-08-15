But first, a bit of background...

This is not a full DynamoDB primer, but it makes some sense to give a high
level overview for the rest of this document to make sense.

Ideally, you should never have to visit the underlying DynamoDB docs in order
to use it, **Dynasty** should provide everything you need. So this is not
exhaustive, but should be enough to get you going.

#### Tables

DynamoDB stores items in *Tables*. A *Table* in Dynamo is
analogous to a Table in [SQL][SQL] or a Collection in [Mongo][Mongo].

Though of course unlike a SQL table, DynamoDB is NoSQL so there is no Schema here.

It is the fundamental bucket into which items are pushed.

Each *Table* has a name and a [Key Schema](#keyschema) (explained below).

Example:

*If you wanted to store data on a series of Users, it may make sense to create
a `UserData` table to hold the data for each user.*


#### Items

*Items* are put into *Tables*.

They are analogous to rows in SQL or documents in Mongo.

Each *Item* must at minimum have the keys/values specified in the *Key Schema*
but they may have any number of other key/value pairs.

Aside from the *Key Schema*, there is no need to be consistent across items.

Example:

*For user with username `victorquinn` you may want an item that looks like:*

```json
{
    "username": "victorquinn",
    "first": "Victor",
    "last": "Quinn",
    "motorcycle": "Harley"
}
```

*whereas for someone else:*

```json
{
    "username": "john",
    "first": "John",
    "car": "Ford"
}
```

*Note how one has motorcycle, the other has car, one has a last name, the other
doesn't, this is fine as long as they both meet the Key Schema.*

#### Key Schema <a id="keyschema"></a>

DynamoDB allows 2 different Key Schemas:

- Hash Type Primary Key
- Hash and Range Type Primary Key

##### Hash Type Primary Key

Should be used when you have a single unique identifier used in the *Table* to
look up the *Item*.

It's better to use a Hash and Range Type Primary Key when possible (as it can
be better on performance, more below) but if you have only a single identifier
a Hash Type Primary Key is perfect.

*Example: A table of UserData, the username may be a Hash Type Primary Key.
Given this username you can uniquely identify the user and retrieve their
data.*

##### Hash and Range Type Primary Key

A composite key. Made up of 2 keys, the so called Hash and Range keys.

This can be more performant as Amazon wil shard the database based on the Hash
key making lookups in very large databases faster. (thankfully you never have to
worry about any of this, it all happens magically in the background)

*Example: A table of certifications of User by state. Hash key could be State,
Range key could be Username. This will help as rather than looking through every
record for the State/Username combo, DynamoDB can quickly narrow it down by
49 states.*


For more examples, see [Amazon's list of examples][Examples]. For more info
generally on these topics, check out [Amazon's docs.][More]

[Examples]: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/SampleTablesAndData.html
[More]: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DataModel.html#DataModelTableItemAttribute
[SQL]: https://en.wikipedia.org/wiki/SQL
[Mongo]: http://mongodb.org
