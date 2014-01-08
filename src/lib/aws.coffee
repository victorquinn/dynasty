events = require('events')
crypto = require('crypto')
http = require('http')
https = require('https')
Q = require 'q'

aws = (spec)->
  that = new events.EventEmitter();
  that.setMaxListeners(0);
  my = {}
  my.accessKeyId = spec.accessKeyId;
  my.secretAccessKey = spec.secretAccessKey;
  my.endpoint = spec.endpoint || 'dynamodb.us-east-1.amazonaws.com';
  my.port = spec.port || 80;
  my.agent = spec.agent;

  my.retries = spec.retries || 3; 

  if spec.sessionToken && spec.sessionExpires
    my.access = 
      sessionToken: spec.sessionToken
      secretAccessKey: spec.secretAccessKey
      accessKeyId: spec.accessKeyId
      expiration: spec.sessionExpires

  execute = (op, data) ->
    deferred = Q.defer()
    cb = (err, data)->
      if err
        deferred.reject err
      else
        deferred.resolve data
    auth (err) ->
      if err
        cb err
      else
        dtStr = (new Date).toUTCString()
        rqBody = JSON.stringify(data)
        sts = ("POST" + "\n" + "/" + "\n" + "" + "\n" + ("host" + ":" + my.endpoint + "\n" + "x-amz-date" + ":" + dtStr + "\n" + "x-amz-security-token" + ":" + my.access.sessionToken + "\n" + "x-amz-target" + ":" + "DynamoDB_20111205." + op + "\n") + "\n" + rqBody)
        sha = crypto.createHash("sha256")
        sha.update new Buffer(sts, "utf8")
        hmac = crypto.createHmac("sha256", my.access.secretAccessKey)
        hmac.update sha.digest()
        auth = ("AWS3" + " " + "AWSAccessKeyId" + "=" + my.access.accessKeyId + "," + "Algorithm" + "=" + "HmacSHA256" + "," + "SignedHeaders" + "=" + "host;x-amz-date;x-amz-target;x-amz-security-token" + "," + "Signature" + "=" + hmac.digest(encoding = "base64"))
        headers =
          Host: my.endpoint
          "x-amz-date": dtStr
          "x-amz-security-token": my.access.sessionToken
          "X-amz-target": "DynamoDB_20111205." + op
          "X-amzn-authorization": auth
          date: dtStr
          "content-type": "application/x-amz-json-1.0"
          "content-length": Buffer.byteLength(rqBody, "utf8")

        options =
          host: my.endpoint
          port: my.port
          path: "/"
          method: "POST"
          headers: headers
          agent: my.agent

        executeRequest = (cb) ->
          req = http.request(options, (res) ->
            body = ""
            res.on "data", (chunk) ->
              body += chunk

            res.on "end", ->
              
              # Do not call callback if it's already been called in the error handler.
              return  unless cb
              try
                json = JSON.parse(body)
              catch err
                cb err
                return
              if res.statusCode >= 300
                err = new Error(op + " [" + res.statusCode + "]: " + (json.message or json["__type"]))
                err.type = json["__type"]
                err.statusCode = res.statusCode
                err.requestId = res.headers["x-amzn-requestid"]
                err.message = op + " [" + res.statusCode + "]: " + (json.message or json["__type"])
                err.code = err.type.substring(err.type.lastIndexOf("#") + 1, err.type.length)
                err.data = json
                cb err
              else
                cb null, json
          )
          req.on "error", (err) ->
            cb err
            cb = `undefined` # Clear callback so we do not call it twice

          req.write rqBody
          req.end()

        
        # see: https://github.com/amazonwebservices/aws-sdk-for-php/blob/master/sdk.class.php
        # for the original php retry logic used here
        (retry = (c) ->
          executeRequest (err, json) ->
            if err?
              if err.statusCode is 500 or err.statusCode is 503
                if c <= my.retries
                  setTimeout (->
                    retry c + 1
                  ), Math.pow(4, c) * 100
                else
                  cb err
              else if err.statusCode is 400 and err.code is "ProvisionedThroughputExceededException"
                if c is 0
                  retry c + 1
                else if c <= my.retries and c <= 10
                  setTimeout (->
                    retry c + 1
                  ), Math.pow(2, c - 1) * (25 * (Math.random() + 1))
                else
                  cb err
              else
                cb err
            else
              cb null, json

        ) 0
    deferred.promise



  ###
  retrieves a temporary access key and secret from amazon STS
  @param cb callback(err) err specified in case of error
  ###
  auth = (cb) ->
    
    # auth if necessary and always async
    if my.access and my.access.expiration.getTime() < ((new Date).getTime() + 60000)
      
      #console.log('CLEAR AUTH: ' + my.access.expiration + ' ' + new Date);
      delete my.access

      my.inAuth = false
    if my.access
      cb()
      return
    that.once "auth", cb
    return  if my.inAuth
    my.inAuth = true
    cqs = ("AWSAccessKeyId" + "=" + encodeURIComponent(my.accessKeyId) + "&" + "Action" + "=" + "GetSessionToken" + "&" + "DurationSeconds" + "=" + "3600" + "&" + "SignatureMethod" + "=" + "HmacSHA256" + "&" + "SignatureVersion" + "=" + "2" + "&" + "Timestamp" + "=" + encodeURIComponent((new Date).toISOString().substr(0, 19) + "Z") + "&" + "Version" + "=" + "2011-06-15")
    host = "sts.amazonaws.com"
    sts = ("GET" + "\n" + host + "\n" + "/" + "\n" + cqs)
    hmac = crypto.createHmac("sha256", my.secretAccessKey)
    hmac.update sts
    cqs += "&" + "Signature" + "=" + encodeURIComponent(hmac.digest(encoding = "base64"))
    
    #console.log(xml);
    
    #console.log('AUTH OK: ' + require('util').inspect(my.access) + '\n' +
    #            ((my.access.expiration - new Date) - 60000));
    https.get(
      host: host
      path: "/?" + cqs
    , (res) ->
      xml = ""
      res.on "data", (chunk) ->
        xml += chunk

      res.on "end", ->
        st_r = /\<SessionToken\>(.*)\<\/SessionToken\>/.exec(xml)
        sak_r = /\<SecretAccessKey\>(.*)\<\/SecretAccessKey\>/.exec(xml)
        aki_r = /\<AccessKeyId\>(.*)\<\/AccessKeyId\>/.exec(xml)
        e_r = /\<Expiration\>(.*)\<\/Expiration\>/.exec(xml)
        if st_r and sak_r and aki_r and e_r
          my.access =
            sessionToken: st_r[1]
            secretAccessKey: sak_r[1]
            accessKeyId: aki_r[1]
            expiration: new Date(e_r[1])

          my.inAuth = false
          that.emit "auth"
        else
          tp_r = /\<Type\>(.*)\<\/Type\>/.exec(xml)
          cd_r = /\<Code\>(.*)\<\/Code\>/.exec(xml)
          msg_r = /\<Message\>(.*)\<\/Message\>/.exec(xml)
          if tp_r and cd_r and msg_r
            err = new Error("AUTH [" + cd_r[1] + "]: " + msg_r[1])
            err.type = tp_r[1]
            err.code = cd_r[1]
            my.inAuth = false
            that.emit "auth", err
          else
            err = new Error("AUTH: Unknown Error")
            my.inAuth = false
            that.emit "auth", err

    ).on "error", (err) ->
      my.inAuth = false
      that.emit "auth", err
  execute

module.exports = aws
