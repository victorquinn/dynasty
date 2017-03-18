chai = require('chai')
Promise = require('bluebird')
expect = require('chai').expect
Chance = require('chance')
Dynasty = require('../lib/dynasty')
helpers = require('../lib/lib/helpers')

chance = new Chance()

describe 'Helpers', () ->
  describe 'hasValidFindParams', () ->
    it 'exists', () ->
      expect(helpers).to.have.property('hasValidFindParams')

    it 'works with string', () ->
      str = chance.word({ length: 20 })
      expect(helpers.hasValidFindParams(str)).to.equal(true)

    it 'works with object with only hash key', () ->
      str = chance.word({ length: 20 })
      expect(helpers.hasValidFindParams({ hash: str })).to.equal(true)

    it 'works with object with hash and range key', () ->
      str = chance.word({ length: 20 })
      expect(helpers.hasValidFindParams({ hash: str, range: str })).to.equal(true)

    it 'rejects object with no hash key', () ->
      str = chance.word({ length: 20 })
      params = {}
      params[str] = str
      expect(helpers.hasValidFindParams(params)).to.equal(false)

    it 'rejects object with hash key and random extra key', () ->
      str = chance.word({ length: 20 })
      params = { hash: str }
      params[str] = str
      expect(helpers.hasValidFindParams(params)).to.equal(false)

    it 'rejects object with hash key, range key and random extra key', () ->
      str = chance.word({ length: 20 })
      params = { hash: str, range: str }
      params[str] = str
      expect(helpers.hasValidFindParams(params)).to.equal(false)

    it 'rejects undefined key', () ->
      str = chance.word({ length: 20 })
      expect(helpers.hasValidFindParams(undefined)).to.equal(false)

    it 'rejects null key', () ->
      str = chance.word({ length: 20 })
      expect(helpers.hasValidFindParams(null)).to.equal(false)
