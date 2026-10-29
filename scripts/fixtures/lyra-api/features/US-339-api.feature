# language: fr
@US-339 @REQ-339 @api
Fonctionnalité: Installer Lyra seul sur une machine neuve par un installeur guidé (US-339)
  # REQ-339 - critères couverts à ce niveau : AC-1, AC-2, AC-5
  # Aucun de ces scénarios n'est exécuté : ./lyra installer télécharge plusieurs Go et modifie l'installation de la machine (disque < 3 Go de marge, miroir factice et volume restreint non disponibles). Étiquetés @requiert-machine-neuve (environnement), NOT_TESTED.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @cli @lent @non-deterministe-env @requiert-machine-neuve
  Scénario: ./lyra installer : composants obligatoires, code 0, sans confirmation
    Quand j'exécute la commande "./lyra installer" depuis la racine du dépôt
    Alors le code de sortie vaut 0

  @AC-2 @api @cli @requiert-machine-neuve
  Scénario: Empreinte SHA-256 différente : fichier refusé
    Quand j'exécute la commande "./lyra installer" depuis la racine du dépôt
    Alors le code de sortie n'est pas 0

  @AC-5 @api @cli @requiert-machine-neuve
  Scénario: Espace disque insuffisant : refus avant le premier octet, code 4
    Quand j'exécute la commande "./lyra installer" depuis la racine du dépôt
    Alors le code de sortie vaut 4
