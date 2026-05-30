FROM node:18-alpine

RUN npm install -g typescript ts-node

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

COPY . .
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
