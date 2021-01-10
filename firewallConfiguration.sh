#!/bin/bash


source bin/group1user-openrc.sh

# IPs
IP_SADMIN="$(openstack stack output show stackscenario s_admin_private_ip_net1 -c output_value -f value)"
IP_LB="$(neutron lbaas-loadbalancer-show lb | awk 'FNR == 14 {print $4}')"
PORT_ID="$(openstack port list --fixed-ip subnet=subnet1,ip-address=10.1.1.1 -c ID -f value)"

#Permitir acceso desde el exterior al puerto SSH(22) de s_admin 
openstack firewall group rule create --protocol tcp --destination-port 2020 --destination-ip-address "${IP_SADMIN}" --action allow --name fw_rule_sadmin

#Permitir acceso desde el interior (10.1.1.0/24 - 10.1.2.0/24) a cualquier destino con cualquier protocolo
openstack firewall group rule create --protocol any --source-ip-address 10.1.1.0/24 --action allow --name fw_rule_net1
openstack firewall group rule create --protocol any --source-ip-address 10.1.2.0/24 --action allow --name fw_rule_net2

#Permitir acceso desde el exterior al puerto WWW(80) del Balanceador de carga
openstack firewall group rule create --protocol tcp --destination-port 80 --destination-ip-address "${IP_LB}" --action allow --name fw_rule_lb
sleep 3

#Crear los firewall policy y añadir las reglas al policy
openstack firewall group policy create --firewall-rule fw_rule_sadmin --firewall-rule fw_rule_lb my-ingress-policy
openstack firewall group policy create --firewall-rule fw_rule_net1 --firewall-rule fw_rule_net2 my-egress-policy
sleep 3

#Crear el firewall group
#openstack firewall group create --ingress-firewall-policy "fwcnvr" --no-port
openstack firewall group create --ingress-firewall-policy my-ingress-policy --egress-firewall-policy my-egress-policy --port "${PORT_ID}"
