#!/bin/bash
# Atualizar pacotes e instalar Docker
sudo yum update -y
sudo yum install -y docker amazon-efs-utils
sudo systemctl enable docker
sudo systemctl start docker

# Adicionar usuário ec2-user ao grupo do Docker
sudo usermod -aG docker ec2-user

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Criar diretório para o EFS
sudo mkdir -p /mnt/efs/wordpress

# Montar o EFS (Substitua fs-XXXXXX pela ID correta do seu EFS)
EFS_ID="fs-0123456789abcdef"
REGION="us-east-1"

# Adicionar ao fstab para montagem persistente
echo "$EFS_ID.efs.$REGION.amazonaws.com:/ /mnt/efs/wordpress efs defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# Montar o EFS
sudo mount -a

# Criar arquivo docker-compose.yml
cat <<EOF > /mnt/efs/wordpress/docker-compose.yml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: (Substitua pelo EndPoint do seu RDS)
      WORDPRESS_DB_USER: {usuario}
      WORDPRESS_DB_PASSWORD: {senha}
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /mnt/efs/wordpress:/var/www/html
EOF

# Subir os containers do WordPress
cd /mnt/efs/wordpress
docker-compose up -d

# Criar arquivo de Health Check
echo "Criando o arquivo healthcheck.php..."
sudo tee /mnt/efs/projetopress/healthcheck.php > /dev/null <<EOF
<?php
http_response_code(200);
header('Content-Type: application/json');
echo json_encode(["status" => "OK", "message" => "Health check passed"]);
exit;
?>
EOF


if sudo docker exec -i wordpress ls /var/www/html/healthcheck.php > /dev/null 2>&1; then
  echo "Arquivo healthcheck.php criado com sucesso!"
else
  echo "Falha ao criar o arquivo healthcheck.php."
fi

echo "Instalação concluída!"
