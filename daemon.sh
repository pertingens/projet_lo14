#!/bin/bash

#variable couleur pour la mise en page du fichier log
blanc='\e[1;37m'
rougefonce='\e[0;31m'
vertfonce='\e[0;32m'
orange='\e[0;33m'
violetclair='\e[1;35m'
#-------------------------------------------------------


#boucle sans fin (à voir comment gérer en rendant le service demons)
while [ 0 = 0]
do

while read user
        #variable pour la date et heure système réelle
        nom_du_jour_reel = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f1)
        jour_reel = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f2)
        mois_reel = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f3)
        heure_reel = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f4)
        minute_reel = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f5)
        seconde_reel = $(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f6)
        date_reel= $(date +%u-%d-%m-%H-%M-%S)
        #-------------------------------------------------------

        #on boucle sur le fichier tacherontab pour lire les commandes
        cat /etc/tacherontab | while read user_programmeur seconde_virtuel minute_virtuel heure_virtuel jour_virtuel mois_virtuel nom_du_jour_virtuel commande
        do
        execution_commande = "faux"
        #on teste si le user qui a indiqué la commande a été banni entre deux
        if ( grep "$user_programmeur" "/etc/tacheron.allow" ) || [ "$(whoami)" == "root" ]
        then
                #test interval seconde réelle
                if [ $seconde_reel -eq 0 ]; 
                then
                        interval_seconde_reel = 0
                elif [ $seconde_reel -gt 0 ] && [ $seconde_reel -le 15 ];
                then 
                        interval_seconde_reel = 1
                elif [ $seconde_reel -gt 15 ] && [ $seconde_reel -ls 30 ];
                then    
                        interval_seconde_reel = 2
                else
                        interval_seconde_reel = 3
                fi

                #on test l'interval des secondes
                if [ "$seconde_virtuel" != "*" ];
                then
                        if [ "$seconde_virtuel" = "$interval_seconde_reel" ] ;
                        then
                                continue #on continue de tester les autres lignes de tacherontab (continue s'applique au while)
                        fi
                fi
        
        else
                echo "L'utilisateur qui a inscrit cette commande a été banni";
                execution_commande = "faux"
        fi

        if [ "$execution_commande" = ""]



        done < /etc/tacherontab #lecture des commandes de tacherontab

done < /etc/tacheron.allow #lecture des users autorisés

done



        if [[ $mois_virtuel = ^[1-12]$ ]]; #format valeur précis
        then
                if [ $mois_reel = $mois_virtuel ];
                then 
                        test jour
                else
                        exit 0
                fi
       
        elif [[ $mois_virtuel = ^([1-12](,[1-12])+)$ ]]; #format liste
        then 
                nb_caractere_liste = echo $mois_virtuel | wc -c;
                position = 0;
                while [ $position != $nb_caractere_liste ];
                do 
                        caractere = echo $mois_virtuel | cut -c$position
                        if [ $caractere = "," ];
                        then
                                position += 1;
                        elif [ $caractere -eq $mois_reel ];
                        then 
                                test jour
                        else
                                position += 1 
                        fi
                done 

        elif [[ $mois_virtuel = ^([12-12]-[1-12](~[1-12])*)$ ]]; #format intervalle avec exceptions pris en compte
        then 
                debut_intervalle = `echo $mois_virtuel | cut -c1`
                fin_intervalle = `echo $mois_virtuel | cut -c3`
                nb_caractere_liste = echo $mois_virtuel | wc -c;
                if [ $nb_caractere_liste -gt 3 ]; #des exceptions sont indiquées
                then
                        récupérer les exceptions et comparé mois reelle aux exceptions
                
                
                elif [ $mois_reel ge $debut_intervalle ] && [ $mois_reelle le $fin_intervalle ]; #pas d'exception, on compare l'interval direct
                then 
                        test jour
                else
                        exit 0
                fi

        elif [ $mois_virtuel = '*' ]; #toutes les valeurs
        then 
                test jour

        elif [[ $mois_virtuel = ^([1-12]-[1-12](~[1-12])*/[1-12])$ ]]; #division intervalle par un nombre précis
        then
                test si le mois fait partie de la division
                si oui, test jour
                sinon on sort

        elif [[ $mois_virtuel = ^(*/[1-12])$ ]]; #division de toutes les valeurs par un nombre
        then
                test si le mois fait partie de la division
                si oui, on test le jour
                sinon on sort

        fi

date_virtuel = $nom_du_jour_virtuel-$jour_virtuel-$mois_virtuel-$heure_virtuel-$minute_virtuel-$seconde_virtuel
        if [ $date_reelle = $date_virtuelle ];
        then
                $commande #affichage commande sur la sortie standard
                if [ $? -eq 0 ];
                then
                        echo -e "- $commande effectué le ${orange}<$date_virtuel> ${blanc}programmé par ${violetclair}$user_programmeur ${vertfonce}[Réussi]${blanc}\n" >> /var/log/tacheron
                        #on ecrit dans le fichier log historique ok
                else
                        error = $($commande 2>&1); #on récupère le message d'erreur dans une variable
                        echo -e "$w8 effectué le ${orange}<$date_virtuel> ${blanc}programmé par ${violetclair}$user_programmeur ${rougefonce}[ECHEC] ${blanc}Erreur: $error \n" >> /var/log/tacheron
                fi
        fi
done
