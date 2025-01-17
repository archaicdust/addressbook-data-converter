# # Utilities
require! fs
require! time
require! csv
require! url
require! path

export function date(y, m, d)
  new time.Date y, m, d, 'Asia/Taipei' .toString!

export function parse_roc_date(d)
  [_, y, m, d] = d.match /^(\d\d\d?)(\d\d)(\d\d)/
  [+y + 1911, +m , +d]

export function date_from_rocdate(d)
  return null unless d
  date ...(parse_roc_date d)

export function from_csv(path, opts, transform_cb, done)
  csv!
    .from path, opts
    .transform (record, index, callback) ->
      process.nextTick -> callback null, transform_cb record
    .on \error, -> console.log it.message
    .to.array done

export function process_nativedata(acc, src, done)
  throw "acc is not valid" unless acc.data? or acc.count?
  data = JSON.parse (fs.readFileSync src, \utf-8)
  acc.count += [e for e in data].length
  acc.data <<< data
  done acc

export function guess-processor(category, set)
  basename = path.basename (url.parse set.url .path)
  return process_nativedata if basename is /^native/
  modname = match category
    | /organization/ => \org
    | /person/ => \person
    | otherwise => throw "can not find module name."
  if set.processor
    fnname = set.processor
  else
    fnname = match set.url
      | /data.gov.tw/ => "process_twgovdata_#{basename}"
      | otherwise => throw "can not guess set name"
  try
    pkg = require "./#{modname}"
    throw "#modname is not a module." unless pkg?
    fn = pkg[fnname]
    throw "#fnname is not a function." unless typeof fn is \function
    fn
  catch err
    #@FIXME: should output debug message
    return null

export function travel-data(acc, data, transform_cb, done)
  for record in data
    acc.data.push transform_cb acc.orgids, record
    acc.count +=1
  done acc
