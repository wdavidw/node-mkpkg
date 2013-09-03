
rl = require 'readline'
pad = require 'pad'
require './set_prompt'

bold = (text) -> "\x1b[1m#{text}\x1b[22m"

###
QA, Questions & Answers
=======================
A small framework to ask question and retrieve answers.

Usage:
`ask(questions, [options], callback)`
`ask([questions], options, callback)`

Options include
*   `questions`     Array of questions when not provided as a separate argument, required in such case.
*   `interface`     Readline interface, optional.
*   `input`         The readable stream to listen to, used to initialize the readline interface unless provided, default to `process.stdin`.
*   `output`        The writable stream to listen to, used to initialize the readline interface unless provided, default to `process.stdout`.
*   `completer`     Optional function that is used for Tab autocompletion, used to initialize the readline interface unless provided. 
###
QA = (questions, options, callback) ->
  # Get arguments
  if arguments.length is 3
    options.questions = questions
  else if arguments.length is 2
    callback = options
    if Array.isArray questions
      options = questions: questions
    else
      options = questions
  else
    return callback new Error 'Invalid arguments'
  # Validate arguments
  return callback new Error 'No question asked' unless options.questions?
  @callback = callback
  # Options default
  options.input ?= process.stdin
  options.output ?= process.stdout
  options.completer ?= null
  options.terminal ?= !!options.output.isTTY
  options.close_interface = !options.interface
  options.interface ?= rl.createInterface options.input, options.output, options.completer, options.terminal
  options.yes ?= ['yes']
  options.yes ?= [options.yes] unless Array.isArray options.yes
  options.no ?= ['no']
  options.yes ?= [options.no] unless Array.isArray options.no
  options.index ?= 0
  options.max_index ?= options.index
  # Index questions by name
  for question in options.questions
    options.questions[question.name] = question
    question.label ?= question.name
  # Expose options
  @options = options
  @answers = {}
  process.nextTick => @ask()

QA::disable = ->
  @disabled = true

QA::end = (i) ->
  if @options.close_interface
    @options.interface.close()
    @options.interface.on 'close', =>
      @callback null, @answers
  else
    @callback null, @answers

QA::ask = (i) ->
  @disabled = false
  ask = =>
    return if @disabled
    @options.index = i if i?
    question = @options.questions[@options.index]
    return @end() unless question
    # Condition
    if question.if?
      nif = question.if
      if typeof nif is 'function'
        answers = {}
        answers[q.name] = q.value for q in @options.questions
        nif = nif answers
      unless nif
        @options.index++
        return ask()
    # Add position to label
    pos = "#{@options.index+1}."
    label = "#{pad pos, 3} #{question.label}"
    # Normalize default
    if question.default
      dft = question.default
      if typeof question.default is 'function'
        answers = {}
        answers[q.name] = q.value for q in @options.questions
        dft = question.default answers
        # dft = question.default @options
    # Add default to label
    if question.type is 'boolean'
      if dft?
        y = if dft then bold @options.yes else @options.yes
        n = unless dft then bold @options.no else @options.no
        label += "[#{y},#{n}]"
    else if question.values
        label += ' ['
        for val, i in question.values
          # val = val.toUpperCase() if dft is val
          val = bold val if dft is val
          label += val
          label += ',' unless i+1 is question.values.length
        label += ']'
    else if dft
      label += " [#{dft}]"
    # Optional
    if not question.required and not question.default
      label += " [optional]"
    # Close label
    label += ': '
    @options.interface.question label, (answer) =>
      answer = answer.trim() unless question.no_trim
      if answer is '' and question.default
        answer = dft
      if answer is '' and question.required
        # Print required line
        @options.interface.write @options.required
        # Move back to origin position
        rl.moveCursor @options.interface.output, label.length - @options.required.length, -1
        # Wait a bit
        setTimeout =>
          rl.moveCursor @options.interface.output, 0, 1
          @options.interface._deleteLineLeft()
          rl.moveCursor @options.interface.output, 0, -1
          @options.interface._deleteLineRight()
          ask()
        , @options.wait
        return
      if question.match
        valid = false
        for m in question.match
          valid = true if m.exec answer
        unless valid
          # Print required line
          @options.interface.write @options.invalid
          # Move back to origin position
          rl.moveCursor @options.interface.output, label.length - @options.required.length, -1
          # Wait a bit
          setTimeout ->
            rl.moveCursor @options.interface.output, 0, 1
            @options.interface._deleteLineLeft()
            rl.moveCursor @options.interface.output, 0, -1
            @options.interface._deleteLineRight()
            ask()
          , @options.wait
        return
      if question.type is 'boolean' and typeof answer isnt 'boolean'
        answer = answer.toLowerCase()
        switch
          when @options.yes.indexOf(answer) isnt -1
            answer = true
          when @options.no.indexOf(answer) isnt -1
            answer = false
          else return ask()
      question.value = answer
      @answers[question.name] = answer
      @options.index++
      @options.max_index = Math.max @options.max_index, @options.index
      ask()
  ask()

module.exports = (config, callback) ->
  new QA config, callback
module.exports.QA = QA

