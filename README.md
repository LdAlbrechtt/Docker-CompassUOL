# Docker-CompassUOL 

## 📌Descrição
Este projeto descreve a implantação de uma aplicação WordPress em uma arquitetura de alta disponibilidade na AWS. Utiliza Docker, Amazon RDS para MySQL, Amazon EFS para armazenamento persistente e um Application Load Balancer para distribuir o tráfego.

## 📌Tecnologias
* WSL 
* AWS EC2
* AWS RDS
* AWS EFS
* AWS ALB
* Docker
* Docker Compose

## 📌Arquitetura
- EC2 Instances: Rodam o WordPress em containers Docker.
- Amazon RDS: Hospeda o banco de dados MySQL para o WordPress.
- Amazon EFS: Armazena arquivos estáticos e uploads do WordPress.
- Application Load Balancer (ALB): Distribui o tráfego entre as instâncias EC2 para garantir alta disponibilidade e balanceamento de carga.
- Auto Scaling Group: Para garantir alta disponibilidade e escalabilidade automática das instâncias EC2.


## 📌Como usar
### Requisitos
* Conta AWS
* AWS CLI configurado
* Conhecimento em Docker e AWS
  
## 📌Passos
1. ### Configuração da VPC:
    * Crie uma VPC com sub-redes privadas e publicas em diferentes zonas de disponibilidade (2 AZs).
    * Configure o Internet Gateway associando as subnets publicas através da rota publica gerada no tabela de rotas.
    * Configure um NAT Gateway associando as sub-redes privadas através de uma rota privada para cada sub-rede. 
      

    ![image](https://github.com/user-attachments/assets/acc55c32-39d3-4e5d-b2b4-ca6cce348266)

2. ### Security groups:
   
    #### EC2
      NOME | INBOUND RULES | OUTBOUND RULES
      :--------- | :------: | -------:
      SG_EC2 | HTTP e HTTPS para SG_LB e SSH para qualquer endereço de IPV4 | Default
            
    #### RDS
      NOME | INBOUND RULES | OUTBOUND RULES
      :--------- | :------: | -------:
      SG_RDS | MYSQL/Aurora para SG_EC2 | Default

    #### EFS
      NOME | INBOUND RULES | OUTBOUND RULES
      :--------- | :------: | -------:
      SG_EFS | NFS para SG_EC2 | Default

    #### Load Balancer
      NOME | INBOUND RULES | OUTBOUND RULES
      :--------- | :------: | -------:
      SG_LB | HTTP e HTTPS para qualquer endereço IPV4 | Qualquer destino
   
    
  
4. ### Amazon RDS:
   * Através do subnet groups crie um DB subnet group.
      - Selecione a VPC criada.
      - Selecione as duas zonas de disponibilidades criadas junto a VPC assim como as sub-redes privadas de cada zona.
   * Crie o DB subnet group.

   * Criando database:
      - database creation method: Standard create
      - Engine type: Mysql
      - Templates: free tier
      - Availability and durability: Single-AZ DB instance deployment (1 instance)
      - DB instance identifier: {nome de preferencia}
      - Master username: admin
      - Credentials management: Self managed
      - Password: {sua senha} 
      - DB instance class: Db.t3.micro
      - Compute resource: Don’t connect to an EC2 compute resource
      - Virtual private cloud (VPC): VPC crianda na primeira etapa 
      - DB subnet group: DB subnet group criado anteriormente
      - Public access: NO
      - Existing VPC security groups: SG_RDS
      - Initial database name: wordpress 
   * ⚠️ Se atentar aos recursos adicionais do RDS devido a aumento no custo do serviço, cheque a documentação antes de habilitar algum recurso. 
   
 

5. ### Amazon EFS: 
    * Criar sistema de arquivos
    * Clique na opção customize
    * Nome: {Opcional}
    * File system type: regional
    * Throughput mode: bursting
    * Selecione a VPC criada
    * Selecione as zonas de disponibilidade e suas sub-redes privadas
    * Secutiry group: SG_EFS para ambas sub-redes privadas
    * Crie o sistema de arquivos 
    

 

6. ### Instâncias EC2:
   1. Crie uma instância pública(Bastion Host) para se conectar a instância privada
      - AMI: Ubuntu
      - Tipo: t3.micro
      - Subnet: Publica
      - VPC: vpc criada na primeira etapa
      - Security group: SG_EC2
   
   2. Crie a instancia privada atraves do launch templates
      - AMI: Ubuntu
      - Tipo: t3.micro
      - Subnet: privada
      - VPC: vpc criada na primeira etapa
      - Security group: SG_EC2
      - Utilizar script do User Data:
        ![image](https://github.com/user-attachments/assets/8acd59d6-07f4-46d8-8a5a-07d631d7def5)
      - UserData.sh:

        
         ´´´
         
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
        ´´´
      
      - Revise e crie

    
8. ### Application Load Balancer:
    * Clique em create Load Balancer
    * Selecione o classic load balancer
    * Nome: {nome}
    * VPC: selecionar vpc criada na primeira etapa
    * listeners: HTTP na porta 80
    * Security group: SG_LB
    * Health check: /healthcheck.php
    * Crie o CLB

9. ### Auto Scaling Group:
    * Auto Scaling group name: {nome}
    * Launch template: Selecione o template que você criou anteriormente
    * Selecione a VPC criada na primeira etapa
    * Selecione as sub-redes privadas
    * vailability Zone distribution: Balanced only
    * Load balancing: Associe ao classic load balancer que você criou
    * Capacidade min: 2
    * Capacidade max: 4
    * Automatic scaling: Crie targets tracking scaling policy de seu criterio
    * Instance maintenance policy: no policy
    * Revise e crie
      
10. ### Teste da aplicação:
    * Va no load balancer que você criou e copie o DNS name
    * Cole no navegador e verifique se teve acesso a aplicação do wordpress

    * ⚠️ Você pode acessar sua instancia privada pra verificar se os serviços estão rodando corretamente
      - Se conecte via ssh na sua bastion host:

        ˋˋˋ

              ssh -i chave.pem Ubuntu@IP-BASTION

        ˋˋˋ
      - Dentro da sua bastion host se conecte com sua instância privada: 

        ˋˋˋ

              ssh -i chave.pem Ubuntu@IP-EC2-PRIVADA

        ˋˋˋ
      - Teste se o docker esta rodando corretamente:

        ˋˋˋ

              docker ps 

        ˋˋˋ

   
## 📌Monitoramento: 


### Autor: 

  * Lucas Albrecht 
