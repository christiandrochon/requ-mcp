# language: fr
@US-340 @REQ-340 @api
Fonctionnalité: Connaître l'état de l'installation et diagnostiquer un problème (US-340)
  # REQ-340 - critères couverts à ce niveau : AC-1, AC-2
  # Hypothèse (non contrôlée par le test) : ./lyra etat lit l'installation par défaut de la machine, pas le répertoire isolé de la pile de test.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @cli
  Scénario: ./lyra etat : chaque composant a un statut du vocabulaire spécifié
    Quand j'exécute la commande "./lyra etat" depuis la racine du dépôt
    Alors chaque ligne de composant de la sortie a un statut parmi "ok, absent, incomplet, empreinte_differente, bloque"

  @AC-1 @api @cli
  Scénario: ./lyra etat : code de sortie 1 quand un composant obligatoire n'est pas ok
    Quand j'exécute la commande "./lyra etat" depuis la racine du dépôt
    Alors le code de sortie vaut 1

  # La pile de test est dans l'état « composants obligatoires manquants » (10 manquants) : précondition de l'AC-2.
  @AC-2 @api
  Scénario: /health de lyra-ml : 200 même si un composant obligatoire manque
    Quand j'envoie GET "/health" directement à lyra-ml
    Alors la réponse a le statut 200
    Et le champ "installation.statut" ne vaut pas "complet"
