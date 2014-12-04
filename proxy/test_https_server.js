var https = require('https');
var path = require('path');
var fs = require('fs');

var options = {
    key : fs.readFileSync(path.join(__dirname, 'certs', 'server.key'), 'utf8'),
    cert : fs.readFileSync(path.join(__dirname, 'certs', 'server.crt'), 'utf8'),
};

https.createServer(options, function (request, response) {
    fs.readFile(path.join(process.cwd(),"index.html"), "binary", function(err, file) {
        if(err) {
            response.writeHead(500, {"Content-Type": "text/plain"});
            response.write(err + "\n");
            response.end();
            return;
        }

        response.writeHead(200, {"Content-Type": "text/html"});
        response.write(file, "binary");
        response.end();
    });
}).listen(8000);
