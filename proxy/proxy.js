// We only use default nodejs libraries
var http = require('http'),
    https = require('https'),
    path = require('path'),
    net = require('net'),
    fs = require('fs'),
    URL = require('url'),
    sys  = require('sys');

// Bind to this port
var port = 8008;
// The internal SSL Man-in-the-Middle port
var ssl_port = 8009;

// Timeout of proxy requests
var timeout = 3000;
// Read the file we need to insert into the head of the page
// We don't want to add a link to a script as that delays the execution and might
// miss some errors
var scriptInsert = fs.readFileSync("proxy_insert.html").toString();
var scriptRegex = /(<head[^>]*>)/i;


var har = new HAR();

function HAR(){
    this.addPage = function(id, title, comment){

        this._currentPage = id
        this.log.pages.push({
            "startedDateTime": new Date().toISOString(),
            "id": id,
            "title": title,
            "comment": comment,
            "pageTimings": {
                "onContentLoad": -1,
                "onLoad": -1,
                "comment": ""
            }
        })
    }

    this.addEntry = function(entry){
        this.log.entries.push(entry);
    }

    this.toJson = function(){
        return JSON.stringify(this, null, 4);
    }
    this.log = {
        "version" : "1.2",
        "version" : "1.2",
        "creator" : {
            "name" : "spriteCloud Proxy",
            "version" : "0.0.1",
            "comment" : "Used for capturing test cases"
        },
        "pages": [],
        "entries": [],
        "comment": "spriteCloud Proxy"
    }
    this.log.browser = this.log.creator
    this.addPage("start_page", "Proxy Start", "No page set.")
}

function HAREntry(){
    this.updateHeaders = function(type, headers){
        var result = [];
        for(var key in headers){
            value = headers[key];
            if (type == "response" && key == "content-type" && value){
                this.response.content.mimeType = value.toString();
            }

            if (key == "cookie") {
                this[type].cookies = this.nameValue(value, ";","=");
                result.push({"name":key, "value": value || ""});
            } else if(key == "set-cookie"){
                for(var i in value){
                    var cookie = {
                        "name" : "",
                        "value" : "",
                        "path" : "",
                        "domain" : "",
                        "expires" : "",
                        "httpOnly" : false,
                        "secure" : false
                    }
                    var split = this.nameValue(value[i],";","=");
                    for(var j in split){
                        var item = split[j];
                        item.name = item.name.toLowerCase();
                        if(j == 0){
                            cookie.name = item.name;
                            cookie.value = item.value;
                        } else if(cookie.hasOwnProperty(item.name)){
                            if(item.name == "expires"){
                                cookie.expires = new Date(item.value.replace("-"," ","g")).toISOString();
                            } else if (item.name == "httpOnly"){
                                cookie.httpOnly = true;
                            } else if (item.name == "secure"){
                                cookie.secure = true;
                            } else {
                                cookie[item.name] = item.value
                            }
                        }
                    }
                    this[type].cookies.push(cookie);
                    result.push({"name":key, "value": value[i] || ""});
                }
            //} else if(value && value.indexOf("://") > -1){
            //    result.push({"name":key, "value": (value? encodeURIComponent(value):"")});
            } else {
                result.push({"name":key, "value": value || ""});
            }
            // Caculate size of key=value;
            this.request.headersSize += key.length + 2 + value.length
        }
        this[type].headers = result;
    }

    this.nameValue = function(string, delimiter, splitter){
        var result = []
        var parts = string.split(delimiter)
        for(var i in parts){
            item = parts[i].trim();
            if(!item){continue}
            item_parts = item.split(splitter)
            result.push(
                {
                    "name": item_parts[0].trim(),
                    "value": (item_parts[1] && item_parts[1].indexOf("://") > -1 ?
                        encodeURIComponent(item_parts[1]) :
                        item_parts[1] || "")
                });
        }
        return result
    }

    this.updateQuery = function(query_string){
        if(!query_string){ return }

        this.request.queryString = this.nameValue(query_string, "&","=")
    }

    this.createResponse = function(){
        if(!this.response){
            this.response = {
                "headers": [],
                "cookies": [],
                "redirectURL": "",
                "headersSize": 0,
                "bodySize": -1,
                "content": {
                    "size" : 0,
                    "text" : "",
                    "mimeType" : ""
                }
            }
        }
    }

    this.updateResponse = function(response){
        this.createResponse();
        this.response["status"] = response.statusCode;
        this.response["statusText"] = http.STATUS_CODES[response.statusCode];
        this.response["httpVersion"] = "HTTP/" + response.httpVersion;
        this.updateHeaders("response", response.headers);
    }

    this.updateData = function(chunk) {
        this.firstChunk();
        this.createResponse();
        text = chunk.toString();
        if(chunk || text){
            this.response.content.size += text.length;
            if(this.response.content.mimeType.indexOf("text") > -1 ||
                this.response.content.mimeType.indexOf("application") > -1){
                    this.response.content.text += text;
            } else {
                this.response.content.text = "";
            }
        }
    }

    this.firstChunk = function(){
        if(this.timings.wait == -1){
            var diff = process.hrtime(this._startTime)
            var seconds = diff[0] * 1e9 + diff[1]
            this.timings.wait = (seconds / 1e6) - this.timings.send
        }
    }

    this.doneSending = function(){
        var diff = process.hrtime(this._startTime)
        var seconds = diff[0] * 1e9 + diff[1]
        this.timings.send = seconds / 1e6
    }

    this.doneReceiving = function(){
        var diff = process.hrtime(this._startTime)
        var seconds = diff[0] * 1e9 + diff[1]
        this.time = seconds / 1e6
        this.timings.receive = this.time - this.timings.wait - this.timings.send
        this.response.bodySize = this.response.content.size
    }

    this.toJson = function(){
        return JSON.stringify(this, null, 4);
    }

    this.updateOptions = function(type, options){
        url = type +"://" + options.host + ":" + options.port + options.path
        url_info = URL.parse(url);
        this._startTime = process.hrtime();
        this.startedDateTime = new Date().toISOString();
        this.pageref = har._currentPage;
        this.timings = {
            "send": -1,
            "receive": -1,
            "wait": -1,
            "ssl": -1,
            "connect": -1,
            "wait": -1,
            "blocked" : -1,
            "comment": "Proxy Timings"
        };
        this.cache = {}
        this.time = -1; //TODO:endTime - startTime
        this.request = {
            "method" : options.method,
            "url" : url,
            "httpVersion" : "HTTP/1.1", //TODO: Is it always 1.1? can we get it from proxy_request
            "headers" : [], //updated by updateHeaders
            "queryString" : [], //updated by updateQuery
            "cookies" : [], //updated by updateHeaders
            "headersSize" : 0, //updated by updateHeaders
            "bodySize" : 0 //TODO: Test with POST
        }

        this.updateHeaders("request",options.headers)
        this.updateQuery(url_info.query)
    }
}

function handleProxy(request, response, type, options){
    // Log the incomming request
    sys.log("["+(type == https? "HTTPS":"HTTP") + "] " + options.host + ": " + options.method + " " + options.path);
    var harentry = new HAREntry();
    harentry.updateOptions((type == https? "https":"http"), options)

    // Actually do the error handling
    var proxy_request = type.request(options,
        function (proxy_response) {
            proxy_response.setTimeout(timeout, function(){
                proxy_response.end();
            });
            harentry.updateResponse(proxy_response);
            // Is this response a HTML page?
            var isHTML = proxy_response.headers['content-type'] && proxy_response.headers['content-type'].match('text/html');

            // Listen on incoming data
            proxy_response.addListener('data', function(chunk) {
                harentry.updateData(chunk);
                // We need HTML
                if (isHTML) {
                    // check if the data contains a head
                    chunk = chunk.toString();
                    if (chunk.match(scriptRegex)){
                        // Replace the http placeholder for the actual data
                        insert = scriptInsert.replace(
                            "http: null",
                            "http: " +JSON.stringify({
                                "head" : proxy_response.headers,
                                "statusCode" : proxy_response.statusCode
                            })
                        );
                        // do the insert
                        chunk = chunk.replace(scriptRegex, "$1" + insert);
                    }
                }
                // Write the chunk to the client
                response.write(chunk, 'binary');
            });
            proxy_response.addListener('timeout', function(){
                proxy_response.end();
            })
            // If the proxy is done so is the original request
            proxy_response.addListener('end', function() {
                harentry.doneReceiving();
                harentry.updateResponse(proxy_response);
                har.addEntry(harentry);
                response.end();
            });
            // On error end the proxy request
            proxy_response.addListener('error', function(){
                proxy_request.end();
            });
            // Delete the content-length header
            // This ensures that browsers do not crop the page
            delete proxy_response.headers['content-length']
            // Set the statusCode and header
            response.writeHead(proxy_response.statusCode, proxy_response.headers);
        }
    );
    harentry.doneSending();

    // We don't like to wait for more than 3 seconds
    proxy_request.setTimeout(timeout, function(){
        proxy_request.end();
    });
    request.setTimeout(timeout, function(){
        request.end();
    });

    // Send all data from the request to the proxy request
    request.addListener('data', function(chunk) {
        proxy_request.write(chunk, 'binary');
    });

    // Any errors should halt the request
    proxy_request.addListener('error', function(err){
        if (err){
            sys.error("["+err.toString()+"]["+(type == https? "HTTPS":"HTTP") + "] " + options.host + ": " + options.method + " " + options.path);
        }
        proxy_request.end();
    });
    // If the request ends so does the proxy request
    proxy_request.addListener('end', function() {
        request.end();
    });
    // If the request ends so does the proxy request
    request.addListener('end', function() {
        proxy_request.end();
    });
}

function internalPage(request, response){
    url_parts = URL.parse(request.url);
    if(url_parts.pathname == "/addPage"){
        //Add a page to the HAR
        var options = {
            "id" : Date.now(),
            "title" : "",
            "comment" : ""
        }
        query = url_parts.query.split("&")
        for(var i in query){
            var item = query[i].split("=")
            if(options.hasOwnProperty(item[0])){
                options[item[0]] = decodeURIComponent(item[1])
            }
        }
        har.addPage(options.id, options.title, options.comment);
        response.writeHead(200);
        response.end(JSON.stringify(options));
    } else{
        response.writeHead(404);
        response.end("Incorrect Page");
    }
}

// Create a webserver
server = http.createServer(function(request, response) {
    try {
        // Delete any requested encoding, we don't want gzipped data as
        // it uses more resources to decode the body
        delete request.headers['accept-encoding'];
        // Parse the URL for information
        url_parts = URL.parse(request.url);
        if(!url_parts.host){
            //internal page
            internalPage(request, response);
        } else {
            // Build a request options object
            options = {
                "method" : request.method,
                "host" : url_parts.hostname,
                "path" : url_parts.path,
                "port" : url_parts.port || 80,
                "headers" : request.headers
            }
            handleProxy(request, response, http, options)
        }
    } catch(err) {
        // Catch any stupid mistakes...
        response.writeHead(500);
        response.end("Internal Proxy Error: \n"  + err.stack.toString());
    }
});

server.addListener('connect', function(request, socket, head){
    var proxy = net.createConnection(8009,"localhost");
    proxy.on('connect',function(){
        socket.write(
            'HTTP/1.1 200 Connection Established\r\n' +
            'Proxy-agent: Node-Proxy\r\n' +
            '\r\n');
        proxy.write(head);
    })
    socket.pipe(proxy);
    proxy.pipe(socket);
})
server.addListener('error', function() {
    sys.log("error on server?");
});
server.addListener('upgrade', function(req, socket, upgradeHead) {
    sys.log("Upgrading HTTPS");
});
server.listen(port);
sys.log("Started proxy on port " + port);

https_options = {
    key : fs.readFileSync(path.join(__dirname, 'certs', 'server.key'), 'utf8'),
    cert : fs.readFileSync(path.join(__dirname, 'certs', 'server.crt'), 'utf8'),
};

// Create a webserver
var ssl_server = https.createServer(
    https_options,
    function(request, response) {
        try {
            // Delete any requested encoding, we don't want gzipped data as
            // it uses more resources to decode the body
            delete request.headers['accept-encoding'];
            host = request.headers.host.split(":");
            delete request.headers['host'];
            // Build a request options object
            options = {
                "method" : request.method,
                "host" : host[0],
                "path" : request.url,
                "port" : parseInt(host[1]) || 443,
                "headers" : request.headers,
                // Ignore all certificate errors
                // TODO: Configuration point?
                "rejectUnauthorized" : false
            }
            handleProxy(request, response, https, options)
        } catch(err) {
            // Catch any stupid mistakes...
            response.writeHead(500);
            response.end("Internal Proxy Error: \n"  + err.stack.toString());
        }
    }
);

ssl_server.addListener('error', function() {
    sys.log("error on server?");
});

ssl_server.listen(ssl_port);
sys.log("Started HTTPS internal proxy on port " + ssl_port);

process.on('SIGINT', function(){
    process.exit();
})

process.on('exit', function(){
    fs.writeFileSync("output.har",har.toJson());
})
