{BAD_REQUEST, UNAUTHORIZED} = require 'http-status-codes'
prometheusMetrics = require 'express-prom-bundle'
{spawn} = require 'child-process-promise'
status = require 'express-status-monitor'
promisePipe = require 'promisepipe'
bodyParser = require 'body-parser'
tmpWrite = require 'temp-write'
tmpFile = require 'tempfile'
parallel = require 'bluebird'
express = require 'express'
http = require 'http'
auth = require 'http-auth'
log = require 'morgan'
_ = require 'lodash'
fs = require 'fs'
app = express()

basic = auth.basic {}, (user, pass, cb) ->
  cb(user == process.env.USER && pass == process.env.PASS)

app.use auth.connect(basic)
app.use status()
app.use prometheusMetrics()
app.use log('combined')
app.use '/', express.static(__dirname + '/documentation')

app.post '/', bodyParser.json(), (req, res) ->

  console.log('1..')

  decode = (base64) ->
    new Buffer.from(base64, 'base64').toString 'utf8' if base64?

  decodeWrite = _.flow(decode, _.partialRight tmpWrite, '.html')

  # compile options to arguments
  argumentize = (options) ->
    return [] unless options?
    _.flatMap options, (val, key) ->
      if val then ['--' + key, val]
      else ['--' + key]

  console.log('2..')

  # async parallel file creations
  parallel.join tmpFile('.pdf'),
  decodeWrite(req.body.footer),
  decodeWrite(req.body.contents),
  (output, footer, content) ->
    # combine arguments and call pdf compiler using shell
    # injection save function 'spawn' goo.gl/zspCaC
    spawn 'wkhtmltopdf', (argumentize(req.body.options)
    .concat(['--footer-html', footer], [content, output]))
    .then ->
      res.setHeader 'Content-type', 'application/pdf'
      promisePipe fs.createReadStream(output), res
    .catch ->
      res.status(BAD_REQUEST).send 'invalid arguments'

app.set('port', process.env.PORT or 5555);
#app.listen(app.get('port'), '127.0.0.1');
#app.listen process.env.PORT or 5555

#server = http.createServer(app);
#server.listen(app.get('port'), 'localhost');
#server.on('listening', -> 
#    	console.log('Express server started on port %s at %s', server.address().port, server.address().address);
#	);

#app.listen(app.get('port'), '127.0.0.1', -> 
#  console.log('app listening on port %d in %s mode', app.get('port'), app.get('env'));
#);

app.listen(app.get('port'),"0.0.0.0");

console.log('Listening..')

module.exports = app
