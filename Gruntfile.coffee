module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'dynasty.js': ['src/**/*.coffee']
    coffeelint:
      app: ['src/**/*.coffee']
    watch:
      files: ['Gruntfile.coffee', 'src/**/*.coffee']
      tasks: ['coffeelint', 'coffee']

  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['watch']
        