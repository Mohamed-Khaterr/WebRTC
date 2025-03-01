// Import OS to get machine IP Address
const { networkInterfaces } = require('os');

function getLocalIPAddress() {
    const nets = networkInterfaces();
    let localIP = 'Not Found';

    for (const interfaceName of Object.keys(nets)) {
        for (const net of nets[interfaceName]) {
            // Look for IPv4 addresses that are not internal (ignores loopback 127.0.0.1)
            if (net.family === 'IPv4' && !net.internal) {
                localIP = net.address;
                return localIP; // Return the first non-internal IPv4 address found
            }
        }
    }

    return localIP;
}

// Import HTTP library to start the Server
const http = require('http');
// Specify the port we are using
const PORT = process.env.PORT || 8080;
const HOST = "0.0.0.0"; // To make Mobile Access by IP Address
// Import WebSocket library
const { WebSocketServer } = require('ws');
// Import URL library to extract URL queries
const url = require('url');
// Import UUID library to identify each user
const UUID = require('uuid').v4;
// Import FileSystem to load files
const FileSystem = require('fs');

// Create HTTP Server
const server = http.createServer(function(req, res) {
    // Handle Request(req) and Response(res)

    // Load index.html file
    FileSystem.readFile("../Web/index.html", function(error, data){
        res.writeHead(200, {"Content-Type": "text/html"});
        res.write(data);
        res.end();
    })
});

// Setup the server to listen on the port we specify
server.listen(PORT, HOST, function(error) {
    // if error occur when listening on the port
    if (error) {
        console.log("Something went wrong listening on port:", PORT, error);
    } else {
        console.log("Server is listening on http://" + HOST + ":" + PORT);
        console.log("Machine IP Address:", getLocalIPAddress())
    }
});

// Create WebSocket Server
const wsServer = new WebSocketServer({server});

wsServer.on("connection", onConnection);

// Store connections of WebSocket
const connections = {};
// Store users that connect to WebSocket
const users = {};

// Handle WebSocket Connection HandShake
function onConnection(connection, request) {
    // Extract Query parameters
    const { username } = url.parse(request.url, true).query;

    // Create UUID for connected client
    const uuid = UUID();

    // Set new connection if is not already exist
    connections[uuid] = connection;

    const user = {
        name: username,
        id: uuid,
        isConnected: true
    };
    users[uuid] = user;

    broadcast(uuid, user);
    connection.on("message", message => onMessage(uuid, message));
    connection.on("close", () => onClose(uuid));
};

function onMessage(uuid, bytes) {
    const message = JSON.parse(bytes.toString());
    broadcast(uuid, message);
}

function onClose(uuid) {
    const user = users[uuid];
    user.isConnected = false;
    broadcast(uuid, user);
    delete users[uuid];
    delete connections[uuid];
}

// Send Message from all connections except the sender
function broadcast(fromUUID, message) {
    const defaultMessage = {
        user: users[fromUUID], // Sender
        message: message
    };

    const json = JSON.stringify(defaultMessage);

    Object.keys(connections).forEach(function(uuid) {
        if (fromUUID != uuid) {
            connections[uuid].send(json);
        }
    })
}