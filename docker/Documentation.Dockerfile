FROM node:18

WORKDIR /usr/src/app

COPY . .

RUN npm install --production

EXPOSE 8322
CMD ["npx", "elm-doc-preview", "--no-browser", "--port", "8322"]
