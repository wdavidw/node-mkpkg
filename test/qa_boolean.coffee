
should = require 'should'
fs = require 'fs'
test = require '../lib/test'

describe 'qa boolean', ->

  it 'default true', (next) ->
    test [
      (chunk, input) ->
        if /^1\./.test chunk
          input.push '\n'
          true
      (chunk, input) ->
        if /^2\.  if_yes/.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'q\n'
          true
    ], 
      questions: [
        name: 'boolean_question'
        type: 'boolean'
        default: true
      ,
        name: 'if_yes'
        if: (answers) -> answers.boolean_question
      ,
        name: 'if_no'
      ]
    ,(err, out) ->
      next err

  it 'true', (next) ->
    test [
      (chunk, input) ->
        if /^1\./.test chunk
          input.push 'oui\n'
          true
      (chunk, input) ->
        if /^2\.  if_yes/.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'q\n'
          true
    ],
      yes: 'oui'
      no: 'non'
      questions: [
        name: 'boolean_question'
        type: 'boolean'
        default: true
      ,
        name: 'if_yes'
        if: (answers) -> answers.boolean_question
      ,
        name: 'if_no'
      ]
    , (err, out) ->
      return next err if err
      next err

  it 'no', (next) ->
    test [
      (chunk, input) ->
        if /^1\./.test chunk
          input.push 'non\n'
          true
      (chunk, input) ->
        if /^3\.  if_no/.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'q\n'
          true
    ],
      yes: 'oui'
      no: 'non'
      questions: [
        name: 'boolean_question'
        type: 'boolean'
        default: true
      ,
        name: 'if_yes'
        if: (answers) -> answers.boolean_question
      ,
        name: 'if_no'
      ]
    , (err, out) ->
      return next err if err
      next err


