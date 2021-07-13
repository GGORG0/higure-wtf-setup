#!/bin/bash
chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
genstr16() {
  for i in {1..16} ; do
      echo -n "${chars:RANDOM%${#chars}:1}"
  done
}
genstr48() {
  for i in {1..48} ; do
      echo -n "${chars:RANDOM%${#chars}:1}"
  done
}
genstr32() {
  for i in {1..32} ; do
      echo -n "${chars:RANDOM%${#chars}:1}"
  done
}
genstr8() {
  for i in {1..8} ; do
      echo -n "${chars:RANDOM%${#chars}:1}"
  done
}

# Updates
sudo apt update
sudo apt upgrade -y

# Node.js
curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install nodejs -y

npm i pm2 -g 
npm i typescript -g

sudo apt install nginx -y
sudo apt install git -y

sudo apt install snapd -y
sudo snap install core; sudo snap refresh core
sudo snap install go --classic
sudo snap install --classic certbot

# Firewall
sudo ufw allow 22
yes | sudo ufw enable
sudo ufw allow 3000
sudo ufw allow 2005
sudo ufw allow 2000
sudo ufw allow 9000
sudo ufw allow 8080
sudo ufw allow 27071
sudo ufw allow 80
sudo ufw allow 443

# Root directory
mkdir sharex
cd sharex

# Start script
echo 'pm2 stop all
pm2 delete all
cd bot
pm2 start start.sh --name "bot"
cd ../frontend
pm2 start start.sh --name "frontend"
cd ../cdn
pm2 start start.sh --name "cdn"
cd ../backend
pm2 start start.sh --name "backend"
cd ../..
pm2 start minio.sh --name "s3"
pm2 list' > start.sh
chmod +x start.sh

# Git clones
git clone https://github.com/Higure-wtf/Backend backend
git clone https://github.com/Higure-wtf/Bot bot
git clone https://github.com/Higure-wtf/Proxy cdn
git clone https://github.com/Higure-wtf/Frontend frontend

echo -e "\e[1;32mPlease follow this tutorial to setup Cloudflare. https://setup.elixr.host/cloudflare-setup/untitled When you're done, press enter.\e[0m"
read

# Config
cd ..
echo "# Cloudflare
DOMAIN=
CLOUDFLARE_API_KEY=
CLOUDFLARE_ACCOUNT_ID=
CLOUDFLARE_EMAIL=
# Discord
DISCORD_WEBHOOK_URL=
DISCORD_LINK_APP_ID=
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
# Bot
DISCORD_USER_ROLE=            # Discord 'User' role ID
DISCORD_SERVER_ID=
DISCORD_BOT_TOKEN=
ADMIN_ROLE=
OWNERS=                       # Discord user IDs separated by a space
BOOSTER_ROLE=
# Misc
ADMIN_USER_NAME=              # Username for the admin user that will be created
" > config
echo -e "\e[1;32mPlease put in all the values in the 'config' file and press enter\e[0m"
read
source config
echo -e "\e[1;32mNow you can delete the config file\e[0m"
cd sharex

IP="$(ip a show eth0 | grep "inet " | awk '{print $2}' | sed --expression='s/\/24//g')"

# Replacing the domain
find . -type f -exec sed -i "s/[Hh]igure\.wtf/$DOMAIN/g" {} \;

# Frontend
cd frontend

echo "BACKEND_URL=https://api.$DOMAIN
" > .env

# Installing node modules and building
npm i -g
npm i 
npm run build

# Start script for PM2
echo "npm run start" > start.sh
chmod +x start.sh

# Backend
cd ../backend

# Installing node modules and building
npm i -g
npm i 
npm run build

# Start script for PM2
echo "npm run start" > start.sh
chmod +x start.sh

API_KEY="$(genstr48)"
S3_ACCESS_KEY_ID="$(genstr16)"
S3_SECRET_KEY="$(genstr32)"

MONGODB_PASSWORD="$(genstr8)"

echo "PORT=2001
MONGO_URI=mongodb://127.0.0.1:27017/sharex
API_KEY=$API_KEY
BACKEND_URL=https://api.$DOMAIN
FRONTEND_URL=https://$DOMAIN
S3_SECRET_KEY=$S3_SECRET_KEY
S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
S3_ENDPOINT=https://cdn.$DOMAIN:9000
S3_BUCKET=files
CLOUDFLARE_API_KEY=$CLOUDFLARE_API_KEY
CLOUDFLARE_ACCOUNT_ID=$CLOUDFLARE_ACCOUNT_ID
CLOUDFLARE_EMAIL=$CLOUDFLARE_EMAIL
WEBHOOK_URL=$DISCORD_WEBHOOK_URL
CUSTOM_DOMAIN_WEBHOOK=$DISCORD_WEBHOOK_URL
ACCESS_TOKEN_SECRET=ef203360-f032-4643-b5b5-35c6e1399bb5
REFRESH_TOKEN_SECRET=ac27e6c2-0912-4d47-b6e6-17d4ea5f0a05
DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID
DISCORD_CLIENT_SECRET=$DISCORD_CLIENT_SECRET
DISCORD_LOGIN_URL=https://discord.com/api/oauth2/authorize?client_id=$DISCORD_LINK_APP_ID&redirect_uri=https%3A%2F%2Fapi.$DOMAIN%2Fauth%2Fdiscord%2Flogin%2Fcallback&response_type=code&scope=identify
DISCORD_LINK_URL=https://discord.com/api/oauth2/authorize?client_id=$DISCORD_LINK_APP_ID&redirect_uri=https%3A%2F%2Fapi.$DOMAIN%2Fauth%2Fdiscord%2Flink%2Fcallback&response_type=code&scope=identify%20guilds%20guilds.join
DISCORD_LOGIN_REDIRECT_URI=https://api.$DOMAIN/auth/discord/login/callback
DISCORD_LINK_REDIRECT_URI=https://api.$DOMAIN/auth/discord/link/callback
DISCORD_ROLES=$DISCORD_USER_ROLE
DISCORD_SERVER_ID=$DISCORD_SERVER_ID
DISCORD_BOT_TOKEN=$DISCORD_BOT_TOKEN

" > .env

# MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt update
sudo apt install mongodb-org -y
sudo systemctl enable --now mongod.service
sleep 2
systemctl status mongod.service
mongo --eval 'db.runCommand({ connectionStatus: 1 })'
echo "use admin
db.createUser(
  {
    user: \"admin\",
    pwd: \"$MONGODB_PASSWORD\",
    roles: [ { role: \"userAdminAnyDatabase\", db: \"admin\" } ]
  }
)
use sharex
db.counter.insert({_id:\"counter\",count:1})
db.counters.insert({_id:\"counter\",counters:1,count:0,storageUsed:0})
db.createCollection(\"domains\")
db.createCollection(\"files\")
db.createCollection(\"invisibleurls\")
db.createCollection(\"invites\")
db.createCollection(\"passwordresets\")
db.createCollection(\"permissions\")
db.createCollection(\"refreshtokens\")
db.createCollection(\"shorteners\")
db.createCollection(\"users\")
" | mongo
echo '{"_id":"6ed52f08-0619-4057-bc22-f2ad9107893c","invitedUsers":[],"uid":453,"username":"'"$ADMIN_USER_NAME"'","password":"$argon2i$v=19$m=4096,t=3,p=1$0z9v19NfpvBEiZi/hG3z9Q$XPzL4u0glI5ibMAREttWRy5Yz3ylDKo3E+DvLA6IVHQ","invite":"4249d4c8e5-249d4c8e5a9-9d4c8e","key":"'"$ADMIN_USER_NAME"'_b169e9bc871ba02daca274a5133d62","premium":false,"lastDomainAddition":null,"lastKeyRegen":null,"lastUsernameChange":null,"lastFileArchive":null,"email":"adminemail@gmail.com","emailVerified":true,"emailVerificationKey":"970ba8c23c506b7a30661063f3a710","discord":{"id":null,"avatar":null},"strikes":0,"disabled":false,"blacklisted":{"status":false,"reason":null},"uploads":0,"invites":1,"invitedBy":"GGORG","registrationDate":{"$date":"2021-07-07T17:08:39.607Z"},"lastLogin":null,"admin":true,"bypassAltCheck":false,"settings":{"domain":{"name":"i.'"$DOMAIN"'","subdomain":null},"randomDomain":{"enabled":false,"domains":[]},"embed":{"enabled":true,"color":"#13ed7c","title":"default","description":"default","author":"default","randomColor":true,"sitename":"default"},"embedprofile2":{"enabled":true,"color":"#13ed7c","title":"default","description":"default","author":"default","randomColor":true,"sitename":"default"},"embedprofile3":{"enabled":true,"color":"#13ed7c","title":"default","description":"default","author":"default","randomColor":true,"sitename":"default"},"fakeUrl":{"enabled":false,"url":"example.com"},"autoWipe":{"enabled":false,"interval":3600000},"showLink":false,"invisibleUrl":false,"longUrl":false},"__v":0}' > /tmp/user.json
# echo 'use sharex
# var o = JSON.parse("{"_id":"6ed52f08-0619-4057-bc22-f2ad9107893c","invitedUsers":[],"uid":453,"username":"'"$ADMIN_USER_NAME"',"password":"$argon2i$v=19$m=4096,t=3,p=1$0z9v19NfpvBEiZi/hG3z9Q$XPzL4u0glI5ibMAREttWRy5Yz3ylDKo3E+DvLA6IVHQ","invite":"4249d4c8e5-249d4c8e5a9-9d4c8e","key":"'"$ADMIN_USER_NAME"'_b169e9bc871ba02daca274a5133d62","premium":false,"lastDomainAddition":null,"lastKeyRegen":null,"lastUsernameChange":null,"lastFileArchive":null,"email":"adminemail@gmail.com","emailVerified":true,"emailVerificationKey":"970ba8c23c506b7a30661063f3a710","discord":{"id":null,"avatar":null},"strikes":0,"disabled":false,"blacklisted":{"status":false,"reason":null},"uploads":0,"invites":1,"invitedBy":"GGORG","registrationDate":{"$date":"2021-07-07T17:08:39.607Z"},"lastLogin":null,"admin":true,"bypassAltCheck":false,"settings":{"domain":{"name":"i.'"$DOMAIN"'","subdomain":null},"randomDomain":{"enabled":false,"domains":[]},"embed":{"enabled":true,"color":"#13ed7c","title":"default","description":"default","author":"default","randomColor":true,"sitename":"default"},"embedprofile2":{"enabled":true,"color":"#13ed7c","title":"default","description":"default","author":"default","randomColor":true,"sitename":"default"},"embedprofile3":{"enabled":true,"color":"#13ed7c","title":"default","description":"default","author":"default","randomColor":true,"sitename":"default"},"fakeUrl":{"enabled":false,"url":"example.com"},"autoWipe":{"enabled":false,"interval":3600000},"showLink":false,"invisibleUrl":false,"longUrl":false},"__v":0}");
# db.users.insert(o)
# ' | mongo
mongoimport --db sharex --collection users --file /tmp/user.json
echo -e "\e[1;32mYour MongoDB login URI is: mongodb://admin:$MONGODB_PASSWORD@$IP/admin\e[0m"

# CDN
cd ../cdn

# Replacing the db name
sed -i "s/client\.Database(\"higure\")/client\.Database(\"sharex\")/g" main.go

# Building
go mod init module-path
go mod tidy
go build

echo "PORT=2005
MONGO_URI=mongodb://127.0.0.1:27017/sharex
AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$S3_SECRET_KEY
S3_ENDPOINT=http://127.0.0.1:9000
S3_BUCKET_NAME=files
" > .env

# Start script for PM2
echo "go run main.go" > start.sh
chmod +x start.sh

# MinIO
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
echo "MINIO_ROOT_USER=$S3_ACCESS_KEY_ID MINIO_ROOT_PASSWORD=$S3_SECRET_KEY ./minio server /mnt/data" > minio.sh
chmod +x minio.sh
pm2 start minio.sh --name "s3"
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
./mc alias set myminio/ http://127.0.0.1:9000 $S3_ACCESS_KEY_ID $S3_SECRET_KEY
./mc mb myminio/files
./mc policy set download myminio/files/*
./mc policy set none myminio/files/


# Bot
cd ../bot

echo "BOT_TOKEN=$DISCORD_BOT_TOKEN
API_KEY=$API_KEY
API_KEY=607cdbae-73b6-49d2-b023-5d3667083766
PREFIX=!
ADMIN_ROLE=$ADMIN_ROLE
BACKEND_URL=https://api.$DOMAIN
OWNERS=$OWNERS
BOOSTER_ROLE=$BOOSTER_ROLE
IGNORED_CHANNELS=0
" > .env

# Installing node modules and building
npm i -g
npm i 
npm run build

# Start script for PM2
echo "npm run start" > start.sh
chmod +x start.sh

# Nginx
cd ..

echo "server {
        server_name i.$DOMAIN;
        listen 80;
        listen [::]:80;
        return 301 https://\$host\$request_uri;


}


server {
  server_name i.$DOMAIN;

  location / {
    proxy_pass http://localhost:2005;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }


}
server {
        server_name api.$DOMAIN;
        listen 80;
        listen [::]:80;
        return 301 https://\$host\$request_uri;


}


server {
  server_name api.$DOMAIN;

  location / {
    proxy_pass http://localhost:2001;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }

}
server {
        server_name $DOMAIN;
        listen 80;
        listen [::]:80;
        return 301 https://\$host\$request_uri;


}


server {
  server_name $DOMAIN;

  location / {
    proxy_pass http://localhost:3000;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }

}
server {
        server_name cdn.$DOMAIN;
        listen 80;
        listen [::]:80;
        return 301 https://\$host\$request_uri;


}


server {
  server_name cdn.$DOMAIN;

  location / {
    proxy_pass http://localhost:9000;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }

}
" > /etc/nginx/sites-available/default

sudo nginx -t

echo -e "\e[1;32mPlease go to Cloudflare and disable proxy for every DNS record. When you're done, press enter.\e[0m"
read
yes "" | sudo certbot --nginx
sudo nginx -t
sudo systemctl restart nginx

# Cors
cd backend/src

sed -i "s/app\.use\(
    cors\(\{
      credentials: true,
      origin: \[
        'https:\/\/www.$DOMAIN',
        'https:\/\/$DOMAIN',
        'http:/\/localhost:3000',
        'http:\/\/localhost:3000',
      \],
      methods: \['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'\],
    \}\)
  \);/app.use\(
    cors\(\{
      credentials: true,
      origin: \[
        'https:\/\/www.$DOMAIN',
        'https:\/\/$DOMAIN',
        'https:\/\/cdn.$DOMAIN',
        'https:\/\/api.$DOMAIN',
        'http:\/\/api.$DOMAIN',
        'http:\/\/localhost:2001',
	      'http:\/\/localhost:2005'
        'http:\/\/localhost:3000',
        'http:\/\/localhost:3000',
      \],
      methods: \['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'\],
    \}\)
  \);/g" app.ts

# Done!
cd ../..
./start.sh
echo -e "\e[1;32mDONE!! Login at https://$DOMAIN/ with the username '$ADMIN_USER_NAME' and password 'adminpassword123'. Link your discord and change the password. Done!\e[0m"
