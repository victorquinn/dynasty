chai = require('chai')
Promise = require('bluebird')
expect = require('chai').expect
Chance = require('chance')
Dynasty = require('../lib/dynasty')
_ = require('lodash')

chance = new Chance()

getCredentials = () ->
  accessKeyId: process.env.AWS_ACCESS_KEY
  secretAccessKey: process.env.AWS_SECRET_KEY

getKey = () ->
  chance.word({ length: 20 })

# create test tables
createTables = (dynasty, num) ->
  tables = chance.n(chance.word, num, { length: 20 })
  Promise.all tables.map (table) ->
    options =
      key_schema:
        hash: [
          'my_hash_key',
          'string'
        ]
    dynasty.create(table, options)
  .then () ->
    tables

insertMultiple = (table, num) ->
  rows = chance.n(chance.word, num, { length: 20 })
  Promise.all rows.map (val) ->
    table.insert({ my_hash_key: val })

describe 'Dynasty', () ->
  @timeout(5000)

  describe 'Base', () ->
    it 'constructor exists and is a function', () ->
      expect(require('../lib/dynasty')).to.be.a('function')

    it 'can construct', () ->
      dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
      expect(dynasty).to.exist
      expect(dynasty.tables).to.exist

    it 'can retrieve a table object', () ->
      dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
      # First we need to create this table
      createTables(dynasty, 1)
        .then (tables) ->
          table_name = tables[0]
          # Then create the table object and see that it exists
          t = dynasty.table tables[0]
          expect(t).to.be.an('object')
          dynasty.dropAll()

    describe 'list()', () ->
      beforeEach () ->
        @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
        # create test tables
        createTables(@dynasty, 5)

      it 'can list tables', () ->
        @dynasty.list().then (resp) ->
          expect(resp).to.be.an('object')
          expect(resp).to.have.all.keys('tables', 'offset')
          expect(resp.offset).to.be.a('string')

      it 'can take and obey a limit', () ->
        @dynasty.list({ limit: 2 }).then (resp) ->
          expect(resp).to.be.an('object')
          expect(resp).to.have.all.keys('tables', 'offset')
          expect(resp.offset).to.be.a('string')
          expect(resp.tables.length).to.equal(2)

      it 'has an offset of many tables that works', () ->
        @dynasty.list({ limit: 2 })
          .bind(this)
          .then (resp) ->
            @tables = resp.tables
            expect(resp).to.be.an('object')
            expect(resp).to.have.all.keys('tables', 'offset')
            expect(resp.offset).to.be.a('string')
            @dynasty.list resp.offset
          .then (resp) ->
            expect(@tables).to.not.deep.equal(resp.tables)
            delete @tables

      afterEach () ->
        @dynasty.dropAll()

    describe 'create()', () ->

      beforeEach () ->
        @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')

      it 'should return an object with valid key_schema', () ->
        hashKey = getKey()
        @dynasty.create getKey(),
          key_schema:
            hash: [hashKey, 'string']
        .then (resp) ->
          expect(resp.name).to.be.a('string')
          expect(resp.count).to.be.a('number')
          expect(resp.key_schema).to.be.an('object')
          expect(resp.key_schema).to.have.property('hash')
          expect(resp.key_schema.hash).to.be.an('array')
          expect(resp.key_schema.hash[0]).to.equal(hashKey)
          expect(resp.key_schema.hash[1]).to.equal('string')

      it 'should accept a hash and range key_schema', () ->
        hashKey = getKey()
        rangeKey = getKey()
        @dynasty.create getKey(),
          key_schema:
            hash: [hashKey, 'string']
            range: [rangeKey, 'string']
        .then (resp) ->
          expect(resp.name).to.be.a('string')
          expect(resp.count).to.be.a('number')
          expect(resp.key_schema).to.be.an('object')
          expect(resp.key_schema).to.have.property('hash')
          expect(resp.key_schema.hash).to.be.an('array')
          expect(resp.key_schema.hash[0]).to.equal(hashKey)
          expect(resp.key_schema.hash[1]).to.equal('string')
          expect(resp.key_schema.range).to.be.an('array')
          expect(resp.key_schema.range[0]).to.equal(rangeKey)
          expect(resp.key_schema.range[1]).to.equal('string')

  describe 'Table', () ->

    beforeEach () ->
      @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
      createTables(@dynasty, 1)
        .bind(this)
        .then (tables) ->
          @table = @dynasty.table tables[0]

    describe 'describe()', () ->

      describe 'called with dynasty', () ->

        it 'works', () ->
          @dynasty
            .describe(@table.name)
            .bind(this)
            .then (resp) ->
              # Ensure we've cleaned up the response from Amazon
              expect(resp.Table).to.not.exist
              expect(resp.name).to.be.a('string')
              expect(resp.throughput).to.exist
              expect(resp.throughput.write).to.equal(5)
              expect(resp.attributes).to.be.an('array')

        it 'throws error if called with no name', () ->
          self = @
          expect(() -> self.dynasty.describe()).to.throw('Dynasty: Cannot invoke describe()')

      describe 'called with table object', () ->
  
        it 'works', () ->
          @table
            .describe()
            .bind(this)
            .then (resp) ->
              # Ensure we've cleaned up the response from Amazon
              expect(resp.Table).to.not.exist
              expect(resp.name).to.be.a('string')
              expect(resp.throughput).to.exist
              expect(resp.throughput.write).to.equal(5)
              expect(resp.attributes).to.be.an('array')

    describe 'count()', () ->

      describe 'called with dynasty', () ->

        it 'works', () ->
          # First let's add a few values
          Promise
            .all([
              @table.insert({ my_hash_key: 'a' }),
              @table.insert({ my_hash_key: 'b' }),
              @table.insert({ my_hash_key: 'c' })
            ])
            .bind(@)
            .then () ->
              @dynasty.count(@table.name)
            .then (resp) ->
              # Ensure we've cleaned up the response from Amazon
              expect(resp).to.be.a('number')
              expect(resp).to.equal(3)

        it 'throws error if called with no name', () ->
          self = @
          expect(() -> self.dynasty.count()).to.throw('Dynasty: Cannot invoke count()')

      describe 'called with table object', () ->

        it 'works', () ->
          Promise
            .all([
              @table.insert({ my_hash_key: 'a' }),
              @table.insert({ my_hash_key: 'b' }),
              @table.insert({ my_hash_key: 'c' })
            ])
            .bind(@)
            .then () ->
              @table.count()
            .then (resp) ->
              # Ensure we've cleaned up the response from Amazon
              expect(resp).to.be.a('number')
              expect(resp).to.equal(3)

    describe 'insert()', () ->

      it 'exists', () ->
        expect(@table).to.have.property('insert')

      describe 'works with just a hash key', () ->
        it 'alone', () ->
          value = chance.word({ length: 20 })
          @table
            .insert({ my_hash_key: value })
            .bind(@)
            .then (resp) ->
              # Now look it up and ensure it's in the table
              @table.find(value)
            .then (resp) ->
              expect(resp).to.have.property('my_hash_key')
              expect(resp.my_hash_key).to.equal(value)
  
        it 'and an additional attribute', () ->
          value = chance.word({ length: 20 })
          @table
            .insert({ my_hash_key: value, val: value })
            .bind(@)
            .then (resp) ->
              @table.find(value)
            .then (resp) ->
              expect(resp).to.have.property('my_hash_key')
              expect(resp.my_hash_key).to.equal(value)
              expect(resp.val).to.equal(value)
  
        it 'with a callback', (done) ->
          value = chance.word({ length: 20 })
          table = @table
          table
            .insert({ my_hash_key: value, val: value }, (err, resp) ->
              table.find value, (err, resp) ->
                expect(resp).to.have.property('my_hash_key')
                expect(resp.my_hash_key).to.equal(value)
                expect(resp.val).to.equal(value)
                done(err)
          )
          return null

      describe 'works with a hash and range key', () ->
        beforeEach () ->
          # need to create a table wish a hash and range key
          @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
          options =
            key_schema:
              hash: [
                'my_hash_key',
                'string'
              ]
              range: [
                'my_range_key',
                'number'
              ]
          @dynasty
            .create('hashrangetable', options)
            .bind(@)
            .then (resp) ->
              @table = @dynasty.table 'hashrangetable'

        it 'alone', () ->
          hash_value = chance.word({ length: 20 })
          range_value = chance.natural()
          @table
            .insert({
              my_hash_key: hash_value,
              my_range_key: range_value
            })
            .bind(@)
            .then (resp) ->
              # Now look it up and ensure it's in the table
              @table.find({
                hash: hash_value,
                range: range_value
              })
            .then (resp) ->
              expect(resp).to.have.property('my_hash_key')
              expect(resp.my_hash_key).to.equal(hash_value)
              expect(resp.my_range_key).to.equal(range_value)

        it 'and an additional attribute', () ->
          hash_value = chance.word({ length: 20 })
          range_value = chance.natural()
          @table
            .insert({
              my_hash_key: hash_value,
              my_range_key: range_value,
              random_key: hash_value
            })
            .bind(@)
            .then (resp) ->
              # Now look it up and ensure it's in the table
              @table.find({
                hash: hash_value,
                range: range_value
              })
            .then (resp) ->
              expect(resp).to.have.property('my_hash_key')
              expect(resp.my_hash_key).to.equal(hash_value)
              expect(resp.my_range_key).to.equal(range_value)
              expect(resp.random_key).to.equal(hash_value)

        it 'with a callback', (done) ->
          hash_value = chance.word({ length: 20 })
          range_value = chance.natural()
          table = @table
          table.insert({
            my_hash_key: hash_value,
            my_range_key: range_value
          }, (err, resp) ->
            expect(err).to.not.exist
            table.find({
              hash: hash_value,
              range: range_value
            }, (err, resp) ->
                expect(resp).to.have.property('my_hash_key')
                expect(resp.my_hash_key).to.equal(hash_value)
                expect(resp.my_range_key).to.equal(range_value)
                done(err)
            )
          )
          return null

        it 'rejects find with bogus params'

        afterEach () ->
          @dynasty.drop 'hashrangetable'

    describe 'remove()', () ->

      it 'should return an object', () ->
        promise = @table.remove getKey()
        expect(promise).to.be.an('object')

      it 'should work', () ->
        value = getKey()
        # First insert this item
        @table
          .insert({ my_hash_key: value, val: value })
          .bind(@)
          .then (resp) ->
            # Then check that it exists
            @table.find(value)
          .then (resp) ->
            expect(resp).to.have.property('my_hash_key')
            expect(resp.my_hash_key).to.equal(value)
            expect(resp.val).to.equal(value)
            # Then remove it
            @table.remove(value)
          .then (resp) ->
            # Look for it again
            @table.find(value)
          .then (resp) ->
            # And check that it no longer exists
            expect(resp).to.equal(undefined)

    describe 'batchFind()', () ->

      it 'works with an array of keys', () ->
        promise = @table.batchFind [getKey()]
        expect(promise).to.be.an('object')

    describe 'find()', () ->

      it 'works with just a string', () ->
        value = getKey()
        @table
          .insert({ my_hash_key: value, val: value })
          .bind(@)
          .then (resp) ->
            @table.find(value)
          .then (resp) ->
            expect(resp).to.have.property('my_hash_key')
            expect(resp.my_hash_key).to.equal(value)
            expect(resp.val).to.equal(value)


      it 'works with an object with just a hash key', () ->
        value = getKey()
        @table
          .insert({ my_hash_key: value, val: value })
          .bind(@)
          .then (resp) ->
            @table.find({ hash: value })
          .then (resp) ->
            expect(resp).to.have.property('my_hash_key')
            expect(resp.my_hash_key).to.equal(value)
            expect(resp.val).to.equal(value)

      it 'works with an object with both a hash and range key', () ->
        hash_value = getKey()
        range_value = chance.natural()
        # need to create a table wish a hash and range key
        @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
        options =
          key_schema:
            hash: [
              'my_hash_key',
              'string'
            ]
            range: [
              'my_range_key',
              'number'
            ]
        @dynasty
          .create('hashrangetable', options)
          .bind(@)
          .then (resp) ->
            @table = @dynasty.table 'hashrangetable'
            @table.insert({ my_hash_key: hash_value, my_range_key: range_value })
          .bind(@)
          .then (resp) ->
            @table.find({ hash: hash_value, range: range_value })
          .then (resp) ->
            expect(resp).to.have.property('my_hash_key')
            expect(resp.my_hash_key).to.equal(hash_value)
            expect(resp.my_range_key).to.equal(range_value)

      it 'throws an error if called with bad inputs', () ->
        table = @table
        expect(() -> table.find(null)).to.throw('Dynasty: Invalid parameters specified')

    describe 'alter()', () ->

      it 'should work to change throughput', () ->
        promise = @table.describe()
        expect(promise).to.be.an('object')
        promise.bind(this)
          .then (resp) ->
            expect(resp).to.be.an('object')
            expect(resp.throughput.write).to.equal(5)
            expect(resp.throughput.read).to.equal(10)
            expect(resp.throughput.last_increased_at).to.deep.equal(new Date("1970-01-01T00:00:00.000Z"))
            expect(resp.throughput.last_decreased_at).to.deep.equal(new Date("1970-01-01T00:00:00.000Z"))
            @dynasty.alter resp.name, { throughput: { read: 50, write: 50 } }
          .then (resp) ->
            expect(resp.throughput.read).to.equal(50)
            expect(resp.throughput.write).to.equal(50)

    describe 'count()', () ->
      it 'should exist', () ->
        expect(@table).to.have.property('count')
        expect(@table.count).to.be.a('function')

        @table.count()
          .bind(this)
          .then (cnt) ->
            expect(cnt).to.be.a('number')
            expect(cnt).to.equal(0)
            insertMultiple(@table, 25)
          .then () ->
            @table.count()
          .then (cnt) ->
            expect(cnt).to.be.a('number')
            expect(cnt).to.equal(25)
