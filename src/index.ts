import express, { Request, Response } from 'express';
import { createClient } from 'redis';
import { writeFile, unlink, mkdtemp } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const app = express();
app.use(express.json());

const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://redis:6379'
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));

app.post('/execute', async (req: Request, res: Response) => {
  const { code, language } = req.body;

  if (!code || !language) {
    return res.status(400).json({ error: 'Missing code or language parameter' });
  }

  const supportedLanguages = ['python', 'nodejs'];
  if (!supportedLanguages.includes(language)) {
    return res.status(400).json({ error: 'Unsupported language. Supported: python, nodejs' });
  }

  let ext = language === 'python' ? 'py' : 'js';
  let tempDir: string | undefined;

  try {
    tempDir = await mkdtemp(join(tmpdir(), 'sandbox-'));
    const filePath = join(tempDir, `code.${ext}`);
    await writeFile(filePath, code);

    let dockerImage = language === 'python' ? 'sandbox-python-runner' : 'sandbox-nodejs-runner';
    let command = `docker run --rm --memory=256m --cpus=0.5 -v "${tempDir}:/code" -w /code ${dockerImage} python code.${ext}`;

    if (language === 'nodejs') {
      command = `docker run --rm --memory=256m --cpus=0.5 -v "${tempDir}:/code" -w /code ${dockerImage} node code.${ext}`;
    }

    const { stdout, stderr } = await execAsync(command, { timeout: 30000 });

    await unlink(filePath).catch(() => {});
    await execAsync(`rm -rf "${tempDir}"`).catch(() => {});

    res.json({ output: stdout + stderr, language });
  } catch (error: any) {
    if (tempDir) {
      await execAsync(`rm -rf "${tempDir}"`).catch(() => {});
    }
    res.status(500).json({ error: error.message || 'Execution failed' });
  }
});

const PORT = process.env.PORT || 3000;

redisClient.connect().then(() => {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}).catch(console.error);
