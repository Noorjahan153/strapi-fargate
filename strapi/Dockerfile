FROM node:18

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy remaining code and build
COPY . .
RUN npm run build

EXPOSE 1337

CMD ["npm", "run", "start"]
