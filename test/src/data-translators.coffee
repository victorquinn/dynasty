chai = require('chai')
expect = require('chai').expect
Chance = require('chance')
chance = new Chance()
_ = require('lodash')
dataTrans = require('../lib/lib')['data-translators']

describe 'toDynamo()', () ->

  it 'should throw an error if called with no arguments', () ->
    expect(() -> dataTrans.toDynamo()).to.
      throw(/does not support mapping undefined/)

  it 'looks right when given a number', () ->
    num = chance.integer()
    converted = dataTrans.toDynamo num
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'N': num.toString()

  it 'looks right when given a string', () ->
    str = chance.string()
    converted = dataTrans.toDynamo str
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'S': str

  it 'looks right when given a long string', () ->
    str = chance.string
      length: 1025
    converted = dataTrans.toDynamo str
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'S': str

  it 'should convert objects to Maps', () ->
    expect(dataTrans.toDynamo({foo: 'bar'})).to.eql({M: {foo: {S: 'bar'}}})

  it 'looks right when given an array of numbers', () ->
    arr = [0, 1, 2, 3]
    converted = dataTrans.toDynamo arr
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      NS: ['0', '1', '2', '3']

  it 'looks right when given an array of strings', () ->
    arr = []
    _.times 10, () ->
      arr.push chance.string()
    converted = dataTrans.toDynamo arr
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'SS': arr

  it 'looks right when given an array of objects', () ->
    arr = [{foo: 'bar'}, {bar: 'foo'}]
    converted = dataTrans.toDynamo arr
    expect(converted).to.be.an 'object'
    expect(converted).to.eql({ L: [{M: {foo: {S: 'bar'}}},{M: {bar: {S: 'foo'}}}]})

  it 'looks right when given an array of nested objects', () ->
    arr = [{foo: [1,2,3]}, {bar: {amazon: 'aws'}}]
    converted = dataTrans.toDynamo arr
    expect(converted).to.be.an 'object'
    expect(converted).to.eql({ L: [{M: {foo: {NS: ['1', '2', '3']}}},{M: {bar: {M: {amazon: {S: 'aws'}}}}}]})

  it 'converts an empty array to a list', () ->
    expect(dataTrans.toDynamo([])).to.eql(
      L: []
    )

  it 'should throw an error when given a hetrogeneous array', () ->
    arr = []
    _.times 10, (n) ->
      if n % 2
        arr.push chance.string()
      else
        arr.push chance.integer()
    expect(() -> dataTrans.toDynamo(arr)).to.
      throw('Expected homogenous array of numbers or strings')

  it 'supports null values', () ->
    expect(dataTrans.toDynamo({foo: null})).to.deep.equal
      'M':
        foo:
          'NULL': true

  it 'throws an error for undefined values', () ->
    expect(-> dataTrans.toDynamo({foo: undefined})).to.throw(/does not support mapping undefined/)

describe 'fromDynamo()', () ->

  it 'converts dynamo NULLs to javascript nulls' , () ->
    expect(dataTrans.fromDynamo({NULL: true})).to.be.null

  it 'converts string lists correctly', () ->
    dynamoData =
      L: [
        S: 'foo'
      ,
        S: 'bar'
      ]
    expect(dataTrans.fromDynamo(dynamoData)).to.eql(['foo', 'bar'])

  it 'converts numbered lists correctly',() ->
    dynamoData =
      M:
        foo:
          L: [
            N: 0
          ,
            N: 1
          ]
    expect(dataTrans.fromDynamo(dynamoData)).to.eql({foo: [0, 1]})
