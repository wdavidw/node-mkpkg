
should = require 'should'
fs = require 'fs'
test = require '../lib/test'

describe 'help', ->

  it 'load missing', (next) ->
    test [
      (chunk, input) ->
        if /^1\./.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'l\n'
          true
      (chunk, input) ->
        if /^Where/.test chunk
          input.push 'toto\n'
          true
      (chunk, input) ->
        if /^Where/.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'q\n'
          true
    ], (err, out) ->
      next err

  it 'load file', (next) ->
    content = JSON.stringify
      index: 3
      max_index: 3
    fs.writeFile "#{__dirname}/test.mkp", content, (err) ->
      test [
        (chunk, input) ->
          if /^1\./.test chunk
            input.push '\x1B'
            true
        (chunk, input) ->
          if /^Press \[enter\]/.test chunk
            input.push 'l\n'
            true
        (chunk, input) ->
          if /^Where/.test chunk
            input.push "#{__dirname}/test.mkp\n"
            true
        (chunk, input) ->
          if /^4\./.test chunk
            input.push '\x1B'
            true
        (chunk, input) ->
          if /^Press \[enter\]/.test chunk
            input.push 'q\n'
            true
      ], (err, out) ->
        return next err if err
        fs.unlink "#{__dirname}/test.mkp", (err) ->
          next err






