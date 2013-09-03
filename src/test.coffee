
stream = require 'stream'
mkpkg = require './mkpkg'
merge = require './merge'

module.exports = (steps, options, callback) ->
  if arguments.length is 2
    callback = options
    options = {}
  index = 0
  out = ''
  input = new stream.Readable
  input._read = -> ''
  output = new stream.Writable 
  output.isTTY = true
  output._write = (chunk, encoding, callback) ->
    chunk = chunk.toString()
    out += chunk
    console.log index, JSON.stringify chunk if options.debug
    if steps[index]?(chunk, input) then index++
    callback()
  # Merge options
  opts = input: input, output: output
  for k, v of options
    opts[k] = v
  # Run mkpkg
  mkpkg(opts)
  .on 'quit', (code) ->
    callback null, out
  .on 'error', (err) ->
    callback err