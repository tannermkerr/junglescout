FROM node:15.9.0-alpine3.10

# Create app directory
WORKDIR /usr/src/app

# A wildcard is used to ensure both package.json AND package-lock.json are copied
# copy all js
COPY package*.json ./
COPY *.js .

# install app dependencies
# If you are building your code for production
# RUN npm ci --only=production
RUN npm install

EXPOSE 3000
CMD [ "node", "server.js" ]