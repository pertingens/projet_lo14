#!/bin/bash

blanc='\e[1;37m'
rougefonce='\e[0;31m'
vertfonce='\e[0;32m'
orange='\e[0;33m'
violetclair='\e[1;35m'

nom_du_jour_reelle = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f1)
jour_reelle = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f2)
mois_reelle = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f3)
heure_reelle = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f4)
minute_reelle = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f5)
seconde_reelle = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f6)

date_reelle= $(date +%u-%d-%m-%H-%M-%S)
 

cat /etc/tacherontab | while read w1 w2 w3 w4 w5 w6 w7 w8
do
user_programmeur = $(echo $w1)

mois_virtuel = $(echo $w6)
if [[ $w6 = ^[1-12]$ ]]; 
then
       debut_intervalle = `echo $w1 | cut -d'-' -f1`
       fin_intervalle = `echo $w1 | cut -d'-' -f2`
       if [ $mois_reelle ge $debut_intervalle ] && [ $mois_reelle le $fin_intervalle ];
       then 

        else
                exit 0
        fi
elif 

fi
nom_du_jour_virtuel = $(echo $w7)
jour_virtuel = $(echo $w5)
heure_virtuel = $(echo $w4)
minute_virtuel = $(echo $w3)
seconde_virtuel = $(echo $w2)
date_virtuelle = $nom_du_jour_virtuel-$jour_virtuel-$mois_virtuel-$heure_virtuel-$minute_virtuel-$seconde_virtuel
        if [ date_reelle = date_virtuelle ];
        then
                ""$w8"" #affichage commande sur la sortie standard
                if [ $? -eq 0 ];
                then
                        echo -e "- $w8 effectué le ${orange}<$date_virtuelle> ${blanc}programmé par ${violetclair}$user_programmeur ${vertfonce}[Réussi]${blanc}\n" >> /var/log/tacheron
                        #on ecrit dans le fichier log historique ok
                else
                        error = $(w8);
                        echo -e "$w8 effectué le ${orange}<$date_virtuelle> ${blanc}programmé par ${violetclair}$user_programmeur ${rougefonce}[ECHEC] ${blanc}Erreur: $error \n" >> /var/log/tacheron
                fi
        fi
done
