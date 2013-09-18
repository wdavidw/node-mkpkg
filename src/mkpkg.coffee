
{EventEmitter} = require 'events'
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
      return console.log answers
      dest = options.questions.location.value

      # Check if dir exists
      check = =>
        fs.stat dest, (err, stat) ->
          return mkdir() if err
          options.interface.question "Do you wish to overwrite the directory [#{bold('yes')},no]", (answer) ->
            switch answer
              when 'yes', 'y', '' then git()
              else save()
      mkdir = =>
        dest = options.questions.location.value
        fs.mkdir dest, (err) ->
          return error err, true if err
          git()
      git = ->
        fs.exists "#{dest}/.git", (exists) ->
          return gitignore() if exists
          git = new Git dest
          git.init {}, (err, git) ->
            gitignore()
      gitignore = ->
        content = """
        .*
        /node_modules
        !.travis.yml
        !.gitignore
        """
        fs.writeFile "#{dest}/.gitignore", content, (err) ->
          finish()
      layout = ->
        lib = ->
          fs.mkdir "#{dest}/lib", (err) ->
            src()
        src = ->
        return test() unless options.questions.coffeescript.value
          fs.mkdir "#{dest}/src", (err) ->
            test()
        test = ->
          fs.mkdir "#{dest}/test", (err) ->
            packagedotjson()
        lib()
      packagedotjson = =>
        dest = "#{options.questions.location.value}/package.json"
        content = {}
        # Project name
        content.name = options.questions.name.value
        # Repository
        # https://github.com/wdavidw/node-csv.git
        # git@github.com:wdavidw/node-csv.git
        if options.questions.github
          if match = /\w+@github.com:(.*)\/(.*)\.git/ # SSH
            username = match[1]
            project = match[2]
          else if match = /\w+:\/\/github.com\/(.*)\/(.*)\.git/
            username = match[1]
            project = match[2]
          content.repository =
            type: 'git'
            url: options.questions.github.value
        # Dependencies
        content.dependencies = {}
        dependencies = options.questions.dependencies.value
        if dependencies isnt ''
          for dep in options.questions.dependencies.value.split ','
            content.dependencies[dep] = 'latest'
        # Dev Dependencies
        content.devDependencies = {}
        devDependencies = options.questions.devDependencies.value
        if devDependencies isnt ''
          for dep in options.questions.devDependencies.value.split ','
            content.devDependencies[dep] = 'latest'
        # Optional Dependencies
        content.optionalDependencies = {}
        optional_dependencies = options.questions.optionalDependencies.value
        if optional_dependencies isnt ''
          for dep in options.questions.optionalDependencies.value.split ','
            content.optionalDependencies[dep] = 'latest'
        # Write
        content = JSON.stringify content, null, 4
        fs.writeFile dest, content, 'utf8', (err) ->
          return error err, true if err
          git()
      finish = =>
        @quit()
      check()
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



