import "dotenv/config";
import prismaClient from "db/client";

Bun.serve({
    port : 8081,
    fetch(req, server){
         if (server.upgrade(req)) {
        return; // do not return a Response
      }
      return new Response("Upgrade failed", { status: 500 });
    },
    websocket: {
        async message(ws, message) {
            try {
                const newUser = await prismaClient.user.create({
                    data: {
                        username: Math.random().toString(),
                        password: Math.random().toString()
                    }
                });
                console.log("New user created:", newUser);
                ws.send(message);
            } catch (error) {
                console.error("Error creating user:", error);
                ws.send("Error creating user");
            }
        },
    }
})