// backend/handler.js

exports.user = async (event) => {
    console.log("Received event:", JSON.stringify(event, null, 2));
  
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "User created successfully!" }),
    };
  };
  