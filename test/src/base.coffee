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
          'name',
          'string'
        ]
    dynasty.create(table, options)
  .then () ->
    tables

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

    describe 'list()', () ->
      beforeEach () ->
        @timeout(7500)
        @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
        # create test tables
        createTables(@dynasty, 20)

      it 'can list tables', () ->
        @dynasty.list().then (resp) ->
          expect(resp).to.be.an('object')
          expect(resp).to.have.all.keys('tables', 'offset')
          expect(resp.offset).to.be.a('string')

      it 'has an offset if many tables that works', () ->
        # we need more than 100 tables for paging
        createTables(@dynasty, 100)
          .bind(this)
          .then () ->
            @dynasty.list()
          .then (resp) ->
            @tables = resp.tables
            expect(resp).to.be.an('object')
            expect(resp).to.have.all.keys('tables', 'offset')
            expect(resp.offset).to.be.a('string')
            @dynasty.list(resp.offset)
          .then (resp) ->
            expect(@tables).to.not.deep.equal(resp.tables)
            delete @tables

      afterEach () ->
        @timeout(7500)
        @dynasty.dropAll()

    describe 'create()', () ->

      beforeEach () ->
        @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')

      it 'should return an object with valid key_schema', () ->
        @dynasty.create getKey(),
          key_schema:
            hash: [getKey(), 'string']

        expect(promise).to.be.an('object')

      it 'should accept a hash and range key_schema', () ->
        promise = @dynasty.create getKey(),
          key_schema:
            hash: [getKey(), 'string']
            range: [getKey(), 'string']

        expect(promise).to.be.an('object')

  describe 'Table', () ->

    beforeEach () ->
      @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
      createTables(@dynasty, 1)
        .bind(this)
        .then (tables) ->
          @table = @dynasty.table tables[0]

    describe 'remove()', () ->

      it 'should return an object', () ->
        promise = @table.remove getKey()
        expect(promise).to.be.an('object')

    describe 'batchFind()', () ->

      it 'works with an array of keys', () ->
        promise = @table.batchFind [getKey()]
        expect(promise).to.be.an('object')

    describe 'find()', () ->

      it 'works with just a string', () ->
        promise = @table.find getKey()
        expect(promise).to.be.an('object')

      it 'works with an object with just a hash key', () ->
        promise = @table.find
          hash: getKey()
        expect(promise).to.be.an('object')

      it 'works with an object with both a hash and range key', () ->
        promise = @table.find
          hash: getKey()
          range: getKey()
        expect(promise).to.be.an('object')

    describe 'describe()', () ->

      it 'should return an object', () ->
        promise = @table.describe()
        expect(promise).to.be.an('object')
        promise.bind(this).then (resp) ->
          expect(resp.Table).to.be.an('object')
          expect(resp.Table.TableName).to.equal(@table.name)

    describe 'alter()', () ->

      it 'should work to change throughput', () ->
        promise = @table.describe()
        expect(promise).to.be.an('object')
        promise.bind(this)
          .then (resp) ->
            expect(resp).to.be.an('object')
            @dynasty.alter resp.Table.TableName, { throughput: { read: 50, write: 50 } }
          .then (resp) ->
            expect(resp.TableDescription.ProvisionedThroughput.ReadCapacityUnits).to.equal(50)
            expect(resp.TableDescription.ProvisionedThroughput.WriteCapacityUnits).to.equal(50)
