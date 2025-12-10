import dotenv from 'dotenv';
import path from 'path';
import  {PrismaClient}  from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

// Load .env from monorepo root
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const connectionString = process.env.DATABASE_URL as string;

console.log("db url from client", connectionString)

const pgPool = new pg.Pool({
    connectionString,
});

const adapter = new PrismaPg(pgPool);

const prismaClient = new PrismaClient({adapter});

export default prismaClient;