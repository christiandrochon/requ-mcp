# language: fr
@US-341 @REQ-341 @api
Fonctionnalité: Être informé des mises à jour sans installation automatique (US-341)
  # REQ-341 - critères couverts à ce niveau : AC-3, AC-4
  # Exige une version amont factice plus récente et un accès réseau : non disponible (LYRA_MAJ_CONTROLE=0 sur la pile). NOT_TESTED, environnement.

  Contexte:
    Soit l'API Lyra joignable

  @AC-3 @api @cli @requiert-machine-neuve
  Scénario: Mise à jour signalée dans /health après verifier-maj
    Quand j'exécute la commande "./lyra verifier-maj" depuis la racine du dépôt
    Alors le code de sortie vaut 0

  @AC-4 @api @cli @requiert-machine-neuve
  Scénario: proposer-reepinglage : quarantaine sans installation
    Quand j'exécute la commande "./lyra proposer-reepinglage minilm-multi" depuis la racine du dépôt
    Alors le code de sortie vaut 0
