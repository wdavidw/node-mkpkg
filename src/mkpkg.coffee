
{EventEmitter} = require 'events'
{exec} = require 'child_process'
fs = require 'fs'
rl = require 'readline'
util = require 'util'
{Git} = require 'git/lib/git'
qa = require './qa'
dft_options = require './options'
require './set_prompt'

# Present in my git but 0.10.10 doesnt ship it
# rl.getStringWidth = (str) -> str.length
bold = (text) -> "\x1b[1m#{text}\x1b[22m"

mkpkg = (options={}) ->
  # Merge options
  for k, v of dft_options then options[k] ?= v
  # Extends Node.js event emitter
  EventEmitter.call @, options
  # Initialize interface
  rli = options.interface = rl.createInterface options.input, options.output, options.completer, options.terminal
  options.input.on 'keypress', (s, key) =>
    if key?.name is 'escape'
      options.interface._questionCallback = null
      @questions.disable() if @questions
      @help()
    else if key?.name is 'down'
      options.index++
      @create()
    else if key?.name is 'up'
      options.index-- if options.index
      @create()
  @intro = =>
    options.interface.write options.intro
    options.interface.write '\n'
    @[options.action]()
  @quit = =>
    @emit 'quit'
    if options.exit
      @emit 'exit'
      process.exit()
  @error = (msg, exit) =>
    options.interface.write msg
    exit = 1 if exit is true
    @quit exit if exit
  @help = =>
    options.interface.write "\n#{options.commands}\n"
    options.interface.question '', (answer) =>
      switch answer
        when 'quit', 'q' then @quit()
        when 'load', 'l' then @load()
        when 'reset', 'r' then @reset()
        when 'save', 's' then @save()
        when 'view', 'v' then @view()
        when 'create', 'c', '' then @create()
        else @error 'Invalid command'
  @view = =>
    for question, i in options.questions
      break if i is options.max_index
      options.interface.write "#{question.name}: #{question.value}\n"
  @create = =>
    unless @questions
      @questions = qa options, (err, answers) ->
        generate answers
    else
      @questions.ask()
    generate = (answers) =>
      # Check if dir exists
      do_check = =>
        fs.stat answers.location, (err, stat) ->
          return do_mkdir() if err
          options.interface.question "Do you wish to overwrite the directory [#{bold('yes')},no]", (answer) ->
            switch answer
              when 'yes', 'y', '' then do_git()
              else save()
      do_mkdir = =>
        fs.mkdir answers.location, (err) ->
          return error err, true if err
          do_git()
      do_git = ->
        fs.exists "#{answers.location}/.git", (exists) ->
          return gitignore() if exists
          repository = require 'git/lib/git/repository'
          # this generate a bare repository
          # git = new Git answers.location
          # git.init {bare: false, is_bare: false}, (err, git) ->
          #   do_gitignore()
          exec "cd #{answers.location} && git init", (err, stdout, stderr) ->
            return next err if err
            do_gitignore()
      do_gitignore = ->
        content = """
        .*
        /node_modules
        !.travis.yml
        !.gitignore
        """
        fs.writeFile "#{answers.location}/.gitignore", content, (err) ->
          return next err if err
          do_layout()
      do_layout = ->
        do_lib = ->
          fs.mkdir "#{answers.location}/lib", (err) ->
            fs.writeFile "#{answers.location}/lib/index.js", """

            module.exports = function(callback) {
              return process.setImmediate(function() {
                return callback(null, 'Hello world');
              });
            };

            """, (err) ->
              return next err if err
              do_src()
        do_src = ->
          return do_test() unless answers.coffeescript
          fs.mkdir "#{answers.location}/src", (err) ->
            fs.writeFile "#{answers.location}/src/index.coffee", """

            module.exports = (callback) ->
              process.setImmediate ->
                callback null, 'Hello world'

            """, (err) ->
              return next err if err
              do_test()
        do_test = ->
          fs.mkdir "#{answers.location}/test", (err) ->
            env = answers.name.toUpperCase().replace '-', '_'
            env = "#{env}_COV"
            if answers.coffeescript
              fs.writeFile "#{answers.location}/test/index.coffee", """
              should = require 'should'
              index = if process.env['#{env}'] then require '../lib-cov' else require '../lib'

              describe '#{answers.name}', ->

                it 'pass hello world', (next) ->
                  index (err, value) ->
                    return next err if err
                    value.should.eql 'Hello world'
                    next()
              """, (err) ->
            else
              fs.writeFile "#{answers.location}/test/index.js", """
              var should = require('should');
              var index = process.env['#{env}'] ? require('../lib-cov') : require('../lib');

              describe('#{answers.name}', function() {
                return it('pass hello world', function(next) {
                  return index(function(err, value) {
                    if (err) {
                      return next(err);
                    }
                    value.should.eql('Hello world');
                    return next();
                  });
                });
              });
              """, (err) ->
            do_packagedotjson()
        do_lib()
      do_packagedotjson = =>
        dest = "#{answers.location}/package.json"
        content = {}
        # Project name
        content.name = answers.name
        # Repository
        # https://github.com/wdavidw/node-csv.git
        # git@github.com:wdavidw/node-csv.git
        if answers.github
          if match = /\w+@github.com:(.*)\/(.*)\.git/ # SSH
            username = match[1]
            project = match[2]
          else if match = /\w+:\/\/github.com\/(.*)\/(.*)\.git/
            username = match[1]
            project = match[2]
          content.repository =
            type: 'git'
            url: answers.github
        # Dependencies
        content.dependencies = {}
        dependencies = answers.dependencies
        if dependencies isnt ''
          for dep in answers.dependencies.split ','
            content.dependencies[dep] = 'latest'
        # Dev Dependencies
        content.devDependencies = {}
        devDependencies = answers.devDependencies
        if devDependencies isnt ''
          for dep in answers.devDependencies.split ','
            content.devDependencies[dep] = 'latest'
        # Optional Dependencies
        content.optionalDependencies = {}
        optional_dependencies = answers.optionalDependencies
        if optional_dependencies isnt ''
          for dep in answers.optionalDependencies.split ','
            content.optionalDependencies[dep] = 'latest'
        # Write
        content = JSON.stringify content, null, 4
        fs.writeFile dest, content, 'utf8', (err) ->
          return error err, true if err
          do_finish()
      do_finish = =>
        @quit()
      do_check()
  @load = =>
    ask = =>
      options.interface.question 'Where is the project file? ', (answer) ->
        answer = answer.trim()
        return ask() if answer is ''
        read answer
    read = (src) =>
      fs.readFile src, (err, content) =>
        return enoent() if err and err.code is 'ENOENT'
        return @error err if err
        old_options = options
        options = JSON.parse content
        for k, v of old_options then options[k] ?= v
        @questions = null
        @intro()
    enoent = =>
      options.interface.write "#{options.enoent}\n"
      ask()
    ask()
  @reset = =>
    for question in options.questions
      delete question.value
    options.index = 0
    @create()
  @error = (err) =>
    process.stderr.write """
    Sorry, an unexpected error occured.
    Please fill a bug report https://github.com/wdavidw/node-csv-parser/issues.
    About to exit.\n
    """
    @emit 'error', err
  @save = =>
    where = ->
      options.interface.question options.save_where, (answer) ->
        save answer
    write = (dest)->
      content = JSON.stringify options
      fs.writeFile dest, content, (err) ->
        options.interface.write "#{options.save_successfull}.\n"
    return @view()
  process.nextTick =>
    if options.intro then @intro() else @[options.action]()
  @
util.inherits mkpkg, EventEmitter

module.exports = (options) ->
  new mkpkg options



