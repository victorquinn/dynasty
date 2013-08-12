module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files: [
          'dynasty.js': ['src/**/*.coffee']
          'test/test.dynasty.js': ['test/src/**/*.coffee']
        ]
    coffeelint:
      app: ['src/**/*.coffee']
    simplemocha:
      options:
        globals: ['should']
        timeout: 3000
        ignoreLeaks: false
        ui: 'bdd'
        reporter: 'spec'
      all:
        src: ['test/*.js']
    watch:
      files: ['Gruntfile.coffee', 'src/**/*.coffee', 'test/src/**/*.coffee']
      tasks: ['coffeelint', 'coffee', 'simplemocha']

  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'test', ['simplemocha']
  grunt.registerTask 'default', ['watch']
        