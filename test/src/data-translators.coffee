chai = require('chai')
expect = require('chai').expect
Chance = require('chance')
chance = new Chance()
_ = require('lodash')
dataTrans = require('../lib/lib')['data-translators']

describe 'toDynamo()', () ->

  it 'should throw an error if called with no arguments', () ->
    expect(() -> dataTrans.toDynamo()).to.
      throw('Cannot call convert_to_dynamo() with no arguments')

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
    arr = chance.rpg '10d100'
    converted = dataTrans.toDynamo arr
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'NS': arr

  it 'looks right when given an array of strings', () ->
    arr = []
    _.times 10, () ->
      arr.push chance.string()
    converted = dataTrans.toDynamo arr
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'SS': arr

  it 'should throw an error when given a hetrogeneous array', () ->
    arr = []
    _.times 10, (n) ->
      if n % 2
        arr.push chance.string()
      else
        arr.push chance.integer()
    expect(() -> dataTrans.toDynamo(arr)).to.
      throw('Expected homogenous array of numbers or strings')

  it 'should throw an error when given an array of objects', () ->
    arr = []
    _.times 10, () ->
      obj = {}
      obj[chance.string()] = chance.string()
      arr.push obj
    expect(() -> dataTrans.toDynamo(arr)).to.
      throw('Expected homogenous array of numbers or strings')
