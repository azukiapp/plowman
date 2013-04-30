#!/usr/bin/env node

"use strict";

var childProcess = require('child_process'),
    spawn = childProcess.spawn;

// Colors base
var reset = '\x1B[0m',
    red   = '\x1B[1;31m',
    green = '\x1B[1;32m';

// 6 has wide pretty gradients
// Inspired: https://github.com/seattlerb/minitest/blob/master/lib/minitest/pride.rb
var colors = new Array(6 * 7);
for(var i = 0; i < colors.length; i++) { colors[i] = i };

colors = colors.map(function(n) {
  n = n * 1.0 / 6;
  var r = parseInt(3 * Math.sin(n) + 3);
  var g = parseInt(3 * Math.sin(n + 2 * (Math.PI/3)) + 3);
  var b = parseInt(3 * Math.sin(n + 4 * (Math.PI/3)) + 3);

  return(36 * r + 6 * g + b + 16);
});

var started = false;
var ended   = false;
var buffer  = "";
var index   = parseInt(Math.random() * colors.length);
var format  = function(data) {
  if (!started && data.match(/^[\.|F]{1,}$/gm)) {
    process.stdout.write("\nRuning test...\n");
    started = true;
  }

  if (started && !ended && (data.indexOf("\n") == -1)) {
    data = data.split('').map(function(e) {
      var color = '\x1B[38;5;' + colors[index % colors.length] + 'm';
      index += 1;
      return (e == "." ? color + '.' : red + 'F') + reset;
    }).join('');
    process.stdout.write(data);
  } else if (started) {
    ended  = true;
    buffer = buffer + data;
  } else {
    process.stdout.write(data);
  }
}

// Test run
var child = spawn('mix', ['test']);
child.stdout.setEncoding('utf8');
child.stdout.on('data', format);
child.stderr.setEncoding('utf8');
child.stderr.on('data', format);

child.on('exit', function(code, signal) {
  process.stdout.write(buffer.split("\n").map(function(line) {
    // Result
    var result = green + '$1 tests' + reset + ', ' + red + '$2 failures.' + reset;
    line = line.replace(/^(.*) tests, (.*) failures$/, result);

    // Expected
    line = line.replace(/expected: (.*)$/, 'expected: ' + green + '$1' + reset);
    line = line.replace(/^(\s*to be[^:|.]*:)(.*)$/, '$1' + red  + '$2' + reset);

    return line;
  }).join("\n"))
  process.stdout.write("\n");
  process.exit(code);
});
