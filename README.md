# Docker-CompassUOL
### - Atividade do programa de bolsas da CompassUOL -

## Descrição
Este projeto descreve a implantação de uma aplicação WordPress em uma arquitetura de alta disponibilidade na AWS. Utiliza Docker, Amazon RDS para MySQL, Amazon EFS para armazenamento persistente e um Application Load Balancer para distribuir o tráfego.

## Arquitetura
- EC2 Instances: Rodam o WordPress em containers Docker.
- Amazon RDS: Hospeda o banco de dados MySQL para o WordPress.
- Amazon EFS: Armazena arquivos estáticos e uploads do WordPress.
- Application Load Balancer (ALB): Distribui o tráfego entre as instâncias EC2 para garantir alta disponibilidade e balanceamento de carga.

   ![image](https://github.com/user-attachments/assets/d1a3ffc7-560d-4a13-a56e-76ca1756ba18)


## Tecnologias
- WSL 
- AWS EC2
- AWS RDS
- AWS EFS
- AWS ALB
- Docker
- Docker Compose

## Como usar
### Requisitos
- Conta AWS
- AWS CLI configurado
- Conhecimento em Docker e AWS
  
### Passos
1. **Configuração da VPC:**
    - Crie uma VPC com sub-redes privadas em diferentes zonas de disponibilidade.
    - Crie uma subrede publica usada para o NAT Gateway e o Load Balancer.
    - Configure Internet Gateway e NAT Gateway.

    ![image](https://github.com/user-attachments/assets/0562474f-7a1e-4f6e-a854-d04ec6255d96)
    
  
2. **Amazon RDS:**
    - Crie uma instância de banco de dados MySQL.
    - Configure o Security Group para permitir conexões das sub-redes das instâncias EC2.

    ![image](https://github.com/user-attachments/assets/70814ea7-8d84-4142-b0ba-1c4ecd638c5c)




3. **Amazon EFS:** 
    - Crie um sistema de arquivos EFS e conecte a VPC criada (Montagem automatizada no script do User Data)
    - Configure o security group.

    ![image](https://github.com/user-attachments/assets/792aa833-088e-4d9f-996f-09caf5244e37)


4. **Instâncias EC2:**
    - Crie e configure o security group para as instancias de ip privados
    - Utilize o script user_data.sh para a instalação e configuração automática do Docker, Docker Compose, wordpress, RDS e EFS.

    ![image](https://github.com/user-attachments/assets/1654193b-efb5-41ba-9640-92a695b78641)

    - Lance as instâncias com o Amazon Linux 2 AMI.
    - Lance uma instâcia Bastion Host para se conectar as instancias privadas via ssh (Caso precise acessar a instancia via ssh)
    - Configure o security group da Bastion Host - Inbound Rules: tipo SSH permitindo acesso apenas do seu ip ou da VPC

    
6. **Application Load Balancer:**
    - Configure um ALB para balancear o tráfego entre as instâncias EC2.
    - configure o security group.

## Scripts e Automatização 
   
### user_data.sh:
  - Script para automatizar a instalação do Docker, configurações iniciais e arquivo usado para configurar e rodar os containers do WordPress e MySQL.

## Escalabilidade
### Auto Scaling: 
  - Configure Auto Scaling para as instâncias EC2 para gerenciar mudanças no tráfego.

## Autor 
  - Lucas Albrecht 
