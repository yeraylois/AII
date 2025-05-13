# OFFICIAL STABLE node.js IMAGE
FROM node:22.14

# SET THE WORKING DIRECTORY
WORKDIR /app

# COPY package.json AND package-lock.json FILES
COPY package*.json ./

# INSTALL DEPENDENCIES
RUN npm install -g @angular/cli
RUN npm install entities@latest
RUN npm install

# COPY THE REST OF THE APP
COPY . .

# SERVE THE APP
CMD ["ng", "serve", "--host", "0.0.0.0"]
