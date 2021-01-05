#!/bin/bash

#variable couleur pour la mise en page du fichier log
blanc='\e[1;37m'
rougefonce='\e[0;31m'
vertfonce='\e[0;32m'
orange='\e[0;33m'
violetclair='\e[1;35m'
bleu='\e[1;34m'
#-------------------------------------------------------

#fonction principale
executer_commande_tacheron()
{
        while read user_programmeur seconde_virtuel minute_virtuel heure_virtuel jour_virtuel mois_virtuel nom_du_jour_virtuel commande
        do
                commande="$(echo $commande | sed s/\"//g)" #supprime les " autour de la commande
                date_virtuel=$nom_du_jour_virtuel-$jour_virtuel-$mois_virtuel-$heure_virtuel-$minute_virtuel-$seconde_virtuel;
                execution_commande="vrai";
                #on teste si le user qui a indiqué la commande a été banni entre deux
                if ( grep "$user_programmeur" "/etc/tacheron.deny" ) >/dev/null 2>&1; #permet de ne pas afficher le grep 
                then
                        #echo "La commande $commande n'a pas été effectué car l'utilisateur qui l'a programmé a été banni";
                        echo -e "- ${bleu}$commande ${blanc}programmé par ${violetclair}$user_programmeur ${rougefonce}[ECHEC] ${blanc}Erreur: Utilisateur programmeur banni\n" >> /var/log/tacheron;
                        execution_commande="faux"
                        continue
                fi
                
                #on test l'interval des secondes
                if [ "$seconde_virtuel" != "*" ]; #si c'est toutes les valeurs, on passe au champ suivant
                then
                        let "minimum=seconde_virtuel*15"
                        let "maximum=seconde_virtuel*15+15"
                        if [ "$minimum" -gt "${date_reel[1]}" ] || [ "${date_reel[1]}" -ge "$maximum" ]; #si les secondes correspondent au passe au champ suivant
                        then
                                execution_commande="faux"
                                continue #si les secondes correspondent pas, on continue de tester les autres lignes de tacherontab (continue s'applique au while)
                        fi
                fi

                        #si l'interval des secondes correspond, on teste les autres champs temporels
                        indice_date_reel="1";
                        for indice in "$minute_virtuel" "$heure_virtuel" "$jour_virtuel" "$mois_virtuel" "$nom_du_jour_virtuel"
                        do 
                                indice_date_reel="$indice_date_reel+1"

                                #format toutes les valeurs
                                if [ "$indice" == "*" ];
                                then
                                        continue #on passe au champ suivant (continue s'applique au for)
                                fi 

                                # test format liste, on détecte les virgules et on les enlève
                                if [ "$( expr index "$indice" "," )" != "0" ]; #expression regulière pour les variables
                                then
                                        indice="${indice//,/ }"  #remplacement de toutes les virgules de la chaine par un blanc
                                fi

                                for possibilite in $indice #on regarde si les valeurs de la liste correspondent à la date
                                do
                                        valeur_possible="vide" #vide au depart
                                        if [ "$possibilite" -eq "${date_reel[indice_date_reel]}" ] 2>/dev/null;  #si c'est une valeur précise qui correspond au champs reel
                                        then 
                                                valeur_possible="$valeur_possible $possibilite"
                                                execution_commande="vrai"
                                                break
                                        fi

                                        #test format division de toutes les valeurs par un nombre
                                        if [ $( expr index "$possibilite" "*/" ) != "0" ]; 
                                        then
                                                division=`expr ${date_reel[indice_date_reel]} % "${possibilite#"*/"}"` #permet de supprimer le */ devant le chiffre pour faire la division
                                                if [  "$division" == "0" ]
                                                then
                                                        valeur_possible="$valeur_possible ${date_reel[indice_date_reel]}"     
                                                fi
                                        fi

                                        #test format interval
                                        if [ $( expr index "$possibilite" "-" ) != "0" ];
                                        then
                                                debut_interval=`echo "$possibilite" | cut -d'-' -f1`
                                                fin_interval=`echo "$possibilite" | cut -d'-' -f2`
                                                fin_interval=`echo "$fin_interval" | cut -d'~' -f1` #on enlève les exclusion s'il y en a
                                                if [ "$debut_interval" -le "${date_reel[indice_date_reel]}" ] && [ "${date_reel[indice_date_reel]}" -le "$fin_interval" ]
                                                then
                                                        valeur_possible="${date_reel[indice_date_reel]}"
                                                fi             
                                        fi

                                        #test format exclusion
                                        if [ $( expr index "$possibilite" "~" ) != "0" ];
                                        then
                                                position=`expr $( expr index "$possibilite" "~" ) + 1`
                                                exclusion="$( expr substr $possibilite $position "120" )" #On recupere les exclusions en fixant la longueur max à 120 (équivaut à enlever toutes les valeur de minutes et les ~)
                                                exclusion="${exclusion//"~"/ }"              
                                                for valeur in $exclusion
                                                do
                                                        valeur_possible="${valeur_possible//$valeur/ }" #On enleve toutes les exclusions de la liste           
                                                done
                        
                                        fi

                                        #test si la date correspond à la date réelle
                                        if [ $( expr index "$valeur_possible" "${date_reel[indice_date_reel]}" ) -eq "0" ];
                                        then
                                                execution_commande="faux"
                                                continue #Le champs ne correspond pas, on change de ligne de tacherontab
                                        else
                                                execution_commande="vrai"
                                                break #Il y a une possiblité bonne, c'est assez
                                        fi
                                done
                                if [ $execution_commande = "faux" ];
                                then
                                        break #le champs ne correspond pas à la date
                                fi
                        done
                        date_reel=$(date +%A-%d-%m-%Y) #mise en page de la date de l'exécution de la commande pour le fichier log
                        heure_reel=$(date +%H-%M-%S) #mise en page de l'heure de l'exécution de la commande pour le fichier log
                        if [ $execution_commande = "vrai" ];
                        then
                                echo "$user_programmeur $date_reel $heure_reel $commande" >> "/etc/tacheron/tacherontabtmp" #on indique la commande dans le fichier temporaire qui execute les commandes valides
                        fi
        
                done < $1 #lecture des commandes de tacherontab user connecte
}
i=0
#boucle sans fin
while [ true ]
do
        temps_debut_execution=$(date +"%s")
        touch /etc/tacheron/tacherontabtmp #création d'un fichier qui accueillera les commandes à exécuter de chaque utilisateur

        #tableau pour la date et heure système réelle
        date_reel[1]=$(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f6) #seconde reel
        date_reel[2]=$(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f5) #minute reel
        date_reel[3]=$(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f4) #heure reel
        date_reel[4]=$(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f2) #jour reel
        date_reel[5]=$(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f3) #mois reel
        date_reel[6]=$(date +%u-%d-%m-%H-%M-%S | cut -d'-' -f1) #nom du jour reel
        date_reel=$(date +%u-%d-%m-%H-%M-%S)
       
        
        user_connecte=$(whoami);
        #vérification si l'utilisateur_connecte est dans la liste des personnes autorisés
        if ( grep "$user_connecte" "/etc/tacheron.allow" ) >/dev/null 2>&1; #permet de ne pas afficher le grep 
        then
                executer_commande_tacheron /etc/tacheron/tacherontab$user_connecte
                executer_commande_tacheron /etc/tacherontab
        else #sinon on exécute seulement les tâches de root
                executer_commande_tacheron /etc/tacherontab
        fi

        #exécution des commandes du fichier temporaire
        while read user_programmeur date_reel heure_reel commande
        do
                if [[ -n $commande ]]; #permet la résolution d'un problème d'écriture dans tmp
                then
                        sudo $commande 2>/dev/null; #affichage commande sur la sortie standard s'il y a lieu
                        if [ $? -eq 0 ]; #vérification s'il y a eu une erreur
                        then
                                echo -e "- ${bleu}$commande ${blanc}effectué le ${orange}<$date_reel> ${blanc}à ${orange}<$heure_reel> ${blanc}programmé par ${violetclair}$user_programmeur ${vertfonce}[Réussi]${blanc}\nAffichage de la commande:\n ${bleu}$($commande)\n" >> /var/log/tacheron
                                #on écrit dans le fichier log historique ok
                        else
                                error=$($commande 2>&1); #on récupère le message d'erreur dans une variable
                                echo -e "- ${bleu}$commande ${blanc}effectué le ${orange}<$date_reel> ${blanc}à ${orange}<$heure_reel> ${blanc}programmé par ${violetclair}$user_programmeur ${rougefonce}[ECHEC] ${blanc}Erreur: $error \n" >> /var/log/tacheron
                        fi
                else
                        break
                fi

        done < /etc/tacheron/tacherontabtmp

        #suppression du fichier temporaire quand les commandes sont exécutées
        if [ -f /etc/tacheron/tacherontabtmp ];
        then
                rm /etc/tacheron/tacherontabtmp
                
        fi

        #pause de la boucle durant 15 secondes
        sleep 15

done