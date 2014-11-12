// We only use default nodejs libraries
var http = require('http'),
    url = require('url'),
    fs = require('fs'),
    sys  = require('sys');

// Bind to this port
var port = 8008;
// Timeout of proxy requests
var timeout = 3000;
// Read the file we need to insert into the head of the page
// We don't want to add a link to a script as that delays the execution and might
// miss some errors
var scriptInsert = fs.readFileSync("proxy_insert.html").toString();
var scriptRegex = /(<head[^>]*>)/i
// Create a webserver
http.createServer(function(request, response) {
    try {
        var isHTML = false;
        // Log the incomming request
        sys.log(request.connection.remoteAddress + ": " + request.method + " " + request.url);

        // Delete any requested encoding, we don't want gzipped data as
        // it uses more resources to decode the body
        delete request.headers['accept-encoding'];
        // Parse the URL for information
        url_parts = url.parse(request.url);

        // Build a request options object
        options = {
            "method" : request.method,
            "host" : url_parts.hostname,
            "path" : url_parts.path,
            "port" : url_parts.port || 80,
            "headers" : request.headers
        }

        // Actually do the error handling
        var proxy_request = http.request(options,
            function (proxy_response) {
                // Is this response a HTML page?
                isHTML = proxy_response.headers['content-type'] && proxy_response.headers['content-type'].match('text/html');

                // Listen on incoming data
                proxy_response.addListener('data', function(chunk) {
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
                // If the proxy is done so is the original request
                proxy_response.addListener('end', function() {
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

        // We don't like to wait for more than 3 seconds
        proxy_request.setTimeout(timeout);
        request.setTimeout(timeout);

        // Send all data from the request to the proxy request
        request.addListener('data', function(chunk) {
            proxy_request.write(chunk, 'binary');
        });

        // Any errors should halt the request
        proxy_request.addListener('error', function(){
            proxy_request.end();
        })

        // If the request ends so does the proxy request
        request.addListener('end', function() {
            proxy_request.end();
        });
    } catch(err) {
        // Catch any stupid mistakes...
    }
}).listen(port);
