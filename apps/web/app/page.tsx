import prismaClient from "db/client";

// Force dynamic rendering (no static pre-rendering during build)
export const dynamic = 'force-dynamic';

export default async function Home() {
  const users = await prismaClient.user.findMany();
  return (
    <div>
      {JSON.stringify(users)}
    </div>
  );
}
