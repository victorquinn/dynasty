chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
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

describe 'Dynasty', () ->
  describe 'Base', () ->
    it 'constructor exists and is a function', () ->
      expect(require('../lib/dynasty')).to.be.a('function')

    it 'can construct', () ->
      dynasty = Dynasty(getCredentials())
      expect(dynasty).to.exist
      expect(dynasty.tables).to.exist

    it 'can retrieve a table object', () ->
      dynasty = Dynasty(getCredentials())
      options =
        key_schema:
          hash: [
            'name',
            'string'
          ]
      table_name = getKey()
      # First we need to create this table
      dynasty
        .create(table_name, options)
        .then (resp) ->
          # Then create the table object and see that it exists
          t = dynasty.table table_name
          expect(t).to.be.an('object')

    describe 'list()', () ->
      beforeEach () ->
        @timeout(5000)
        dynasty = Dynasty(getCredentials(), 'http://localhost:8000')
        # create test tables
        tables = chance.n(chance.word, 20, { length: 20 })
        @dynasty = dynasty
        Promise.all tables.map (table) ->
          options =
            key_schema:
              hash: [
                'name',
                'string'
              ]

          dynasty.create(table, options)

      it 'can list tables', () ->
        @dynasty.list().then (resp) ->
          expect(resp).to.be.an('object')
          expect(resp).to.have.all.keys('tables', 'offset')
          expect(resp.offset).to.be.a('string')

      afterEach () ->
        @timeout(5000)
        @dynasty.dropAll()

    describe 'create()', () ->

      beforeEach () ->
        @dynasty = Dynasty(getCredentials(), 'http://localhost:8000')

      it 'should return an object with valid key_schema', () ->
        promise = @dynasty.create getKey(),
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
      @dynasty = Dynasty(getCredentials())
      @table = @dynasty.table getKey()
      @dynamo = @dynasty.dynamo

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

    describe 'alter()', () ->

      it 'should return an object', () ->
        promise = @table.describe()
        expect(promise).to.be.an('object')
