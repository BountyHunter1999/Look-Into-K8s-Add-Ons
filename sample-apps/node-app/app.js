const http = require("http");
const PORT = process.env.PORT || 3000;

const requestHandler = (request, response) => {
  response.end(`Hello World! This is my ${process.env.NODE_ENV} environment`);
};

const server = http.createServer(requestHandler);

server.listen(PORT, (err) => {
  if (err) {
    console.log("Error starting server", err);
  } else {
    console.log(`Server is running on port ${PORT}`);
  }
});
