# language: fr
@US-320 @REQ-320 @api
Fonctionnalité: Importer une partition en tâche asynchrone et lire LilyPond et GP6/7 (lots 2 et 3) (US-320)
  # REQ-320 - critères couverts à ce niveau : AC-1, AC-2
  # RÉSOLU (code) : /api/jobs/ingestion_symbolique accepte tout corps (202) ; le contrat des paramètres n'est pas validé. Les workers Celery sont absents : le job reste « en_attente ».
  # RÉSOLU (code, babc922) : LilyPond renvoie « LilyPond n'est pas encore lisible » (lecture non livrée) : AC-2 non implémenté.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Ingestion asynchrone : 202, identifiant et statut consultable
    Quand j'envoie POST "/api/jobs/ingestion_symbolique" avec le corps JSON :
      """
      {"parametres": {"chemin_relatif": "simple-4-mesures.mid"}}
      """
    Alors la réponse a le statut 202
    Et le champ "id" est un UUID
    Et je mémorise le champ "id" sous le nom "jobId"
    Quand j'envoie GET "/api/jobs/{jobId}"
    Alors la réponse a le statut 200
    Et le champ "statut" est l'un de ["en_attente", "en_cours", "termine", "echec"]

  @AC-2 @api @non-implemente
  Scénario: LilyPond simple converti
    Quand j'envoie le fichier "simple.ly" en octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a le statut 200

  @AC-2 @api @non-implemente
  Scénario: Macro Scheme refusée sans partition partielle
    Quand j'envoie le fichier "macro-scheme.ly" en octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a le statut 422
    Et le corps de la réponse ne contient pas "<score-partwise"
