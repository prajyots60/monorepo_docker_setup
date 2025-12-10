import 'dotenv/config';
import prismaClient from 'db/client';
import express from 'express';


const app = express();
app.use(express.json());

app.get('/', async(req, res) => {
     await prismaClient.user.findMany()
    .then(users => {
        res.json(users);
    })
    .catch(error => {
        res.status(500).json({ error: 'Internal Server Error' });
    });
})

app.get('/todos', async(req, res) => {
    await prismaClient.todo.findMany()
   .then(todos => {
       res.json(todos);
   })
   .catch(error => {
       res.status(500).json({ error: 'Internal Server Error' });
   });
})

app.post('/', async(req, res) => {
    const {username, password} = req.body;

    if(!username || !password) {
        return res.status(400).json({error: "Username and password are required"});
    }
    await prismaClient.user.create({
        data: {
           username,
           password
        }
    })
    .then(user => {
        res.status(201).json(user);
    })
    .catch(error => {
        res.status(500).json({ error: 'Internal Server Error' });
    });
})


app.post('/todos', async(req , res) => {
    const {task, userId, done} = req.body;

    if(!task || !userId) {
        return res.status(400).json({error: "Task and userId are required"});
    }

    await prismaClient.todo.create({
        data: {
            task,
            userId,
            done
        }
    })
    .then(todo => {
        res.status(201).json(todo);
    })
    .catch(error => {
        res.status(500).json({ error: 'Internal Server Error' });
    });
})


app.listen(8080)