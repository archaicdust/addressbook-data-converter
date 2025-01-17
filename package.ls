#!/usr/bin/env lsc -cj
author:
  name: ['Chen Hsin-Yi']
  email: 'ossug.hychen@gmail.com'
name: 'addressbook-data-converter'
description: 'To convert Taiwan government organization rawdata from multiple sources in popolo specfication.'
version: '0.0.2'
main: \lib/index.js
repository:
  type: 'git'
  url: 'git://github.com/g0v/addressbook-data-converter.git'
scripts:
  test: """
    mocha
  """
  prepublish: """
    lsc -cj package.ls &&
    lsc -cj config.ls &&
    lsc -bdc -o lib src
  """
  # this is probably installing from git directly, no lib.  assuming dev
  postinstall: """
    if [ ! -e ./lib ]; then npm i LiveScript; lsc -bc -o lib src; fi
  """
engines: {node: '*'}
dependencies:
  optimist: \0.6.x
  csv: \0.3.x
  cheerio: \0.13.x
  request: \2.34.x
  async : \0.7.x
  mkdirp: \0.3.x
devDependencies:
  mocha: \1.14.x
  supertest: \0.7.x
  chai: \1.8.x
  LiveScript: \1.2.x
  groc: \0.6.x
