FROM node:4.4.3-slim

COPY package.json .

RUN npm install --silent

COPY ./src /src

EXPOSE 3000

CMD ["node", "/src/server.js"]
