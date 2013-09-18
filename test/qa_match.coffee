
should = require 'should'
fs = require 'fs'
test = require '../lib/test'

describe 'qa match', ->

  it 'is not matching', (next) ->
    test [
      (chunk, input) ->
        if /^1\./.test chunk
          input.push 'This will not match\n'
          true
      (chunk, input) ->
        if /^1\./.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'q\n'
          true
    ], 
      questions: [
        name: 'matching_question'
        match: [
          /^Here is a match/
          /^And this is another match/
        ]
      ,
        name: 'never_get_here'
      ]
    ,(err, out) ->
      next err

  it 'is matching', (next) ->
    test [
      (chunk, input) ->
        if /^1\./.test chunk
          input.push 'Here is a matching answer\n'
          true
      (chunk, input) ->
        if /^2\./.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'q\n'
          true
    ], 
      questions: [
        name: 'matching_question'
        match: [
          /^Here is a match/
          /^And this is another match/
        ]
      ,
        name: 'get_here'
      ]
    ,(err, out) ->
      next err





