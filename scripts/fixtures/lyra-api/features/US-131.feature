# language: fr
@api @US-131 @REQ-131 @non-implemente
Fonctionnalité: Génération symphonique : œuvre orchestrale complète à partir d'œuvres orchestrales

  # CONSTAT : le type de job existe (JobType.java:16 GENERATION_SYMPHONIQUE("generation_symphonique", CPU, 21600)) mais aucune autre
  # référence dans lyra-api/src/main ni lyra-ml/app (grep « generation_symphonique ») : pas de consommateur ni de moteur de génération
  # symphonique identifié. Seul le contrat de création/consultation de job (JobController) est ancré.

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/jobs/JobController.java:45 (POST /api/jobs/{type}), :63 (GET /api/jobs/{id}), :100 (reprendre) ; JobStatut.java:5-10 ; JobType.java:16
  @AC-1 @api @non-resolu
  Scénario: Un job est créé et son état est consultable
    # A CONFIRMER : forme de "parametres" (références des œuvres sources, durée cible) : aucun schéma trouvé
    Quand j'envoie POST "/api/jobs/generation_symphonique" avec un corps "parametres" contenant une œuvre source et une durée cible
    Alors la réponse a le statut 202
    Et l'en-tête "Location" désigne "/api/jobs/{id}"
    Et le champ "type" vaut "generation_symphonique"
    Quand j'interroge GET "/api/jobs/{id}" jusqu'à un statut terminal (termine, echec ou annule)
    # A CONFIRMER : nécessite un worker et un moteur qui n'existent pas dans le code lu ; le test peut seulement observer en_attente/échec 503 à la création
    Alors le statut final est "termine"

  @AC-2 @api @non-testable
  Scénario: Conducteur et parties contiennent toutes les doublures écrites comme parties
    # A CONFIRMER : fonctionnalité non trouvée dans le code
    Quand j'exporte le conducteur et les parties de l'œuvre produite
    Alors chaque doublure est écrite comme partie

  @AC-3 @api @non-testable
  Scénario: Sans durée ni mouvements, valeurs par défaut calculées depuis les sources
    # A CONFIRMER : fonctionnalité non trouvée dans le code ; oracle clair (moyenne arrondie à la minute, mode des mouvements parmi sources >= 2 mouvements sinon 4)
    Quand je crée un job symphonique sans durée ni nombre de mouvements à partir de 3 sources
    Alors la durée vaut la moyenne des durées des sources arrondie à la minute

  @AC-4 @api @non-testable
  Scénario: Un échec pendant un mouvement ne refait pas les mouvements terminés à la reprise
    # A CONFIRMER : reprise (POST /api/jobs/{id}/reprendre, JobController.java:100) existe, mais pas de granularité par mouvement ; nécessite injection de panne
    Quand le job échoue pendant le mouvement 3 puis est repris
    Alors les mouvements 1 et 2 ne sont pas régénérés
