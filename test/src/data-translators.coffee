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

  it 'looks right when given a blob', () ->
    str = chance.string
      length: 1025
    converted = dataTrans.toDynamo str
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'B': str

  it 'looks right when given a random object', () ->
    obj = {}
    _.times 10, () ->
      obj[chance.string()] = chance.string()
    converted = dataTrans.toDynamo obj
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'B': JSON.stringify obj

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

  it 'looks right when given an array of blobs', () ->
    arr = []
    _.times 10, () ->
      arr.push chance.string({length: 1040})
    converted = dataTrans.toDynamo arr
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'BS': arr

  it 'looks right when given an array of objects', () ->
    arr = []
    _.times 10, () ->
      obj = {}
      obj[chance.string()] = chance.string()
      arr.push obj

    stringified = _.map arr, (i) -> JSON.stringify i
    converted = dataTrans.toDynamo arr
    expect(converted).to.be.an 'object'
    expect(converted).to.deep.equal
      'BS': stringified
