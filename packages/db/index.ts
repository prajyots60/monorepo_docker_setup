import dotenv from 'dotenv';
dotenv.config();
import  {PrismaClient}  from '@prisma/client';
// import {withPgAdapter} from 'prisma-pg-adapter';
// import {Pool} from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

const connectionString = process.env.DATABASE_URL || '';

const pgPool = new pg.Pool({
    connectionString,
});

const adapter = new PrismaPg(pgPool);

const prismaClient = new PrismaClient({adapter});

export default prismaClient;