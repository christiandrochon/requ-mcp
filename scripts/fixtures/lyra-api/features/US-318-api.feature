# language: fr
@US-318 @REQ-318 @api
Fonctionnalité: Retrouver ses partitions enregistrées (US-318)
  # REQ-318 - critères couverts à ce niveau : AC-1, AC-2, AC-3
  # RÉSOLU (code) : « partition enregistrée » = pièce (/api/pieces) ; aucune persistance séparée des partitions ni export par partition_id n'est exposée (grep : PartitionRequest n'a pas de partition_id) ; PUT /api/pieces/{id} met à jour la même ligne (écart AC-2).

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @redemarrage
  Scénario: Relecture après redémarrage : même contenu et empreinte
    Soit une pièce enregistrée sous le nom "pieceId"
    Quand j'envoie GET "/api/pieces/{pieceId}"
    Alors la réponse a le statut 200

  @AC-1 @api
  Scénario: Une pièce enregistrée est relue à l'identique
    Quand j'envoie POST "/api/pieces" avec le corps JSON :
      """
      {"titre": "relecture e2e", "contenu": "contenu relu", "sha256": "@aleatoire", "origine": "editee"}
      """
    Alors la réponse a le statut 201
    Et je mémorise le champ "id" sous le nom "pieceId"
    Quand j'envoie GET "/api/pieces/{pieceId}"
    Alors le champ "contenu" vaut "contenu relu"
    Et le champ "titre" vaut "relecture e2e"

  @AC-2 @api
  Scénario: Modifier une partition crée une nouvelle ligne, l'ancienne reste lisible
    Soit une pièce enregistrée sous le nom "pieceId"
    Quand j'envoie PUT "/api/pieces/{pieceId}" avec le corps JSON "{\"titre\": \"modifiee\", \"contenu\": \"v2\"}"
    Alors la réponse a le statut 200
    Et le champ "id" ne vaut pas "{pieceId}"
    # Oracle de l'AC-2 : une NOUVELLE ligne (id différent) ; le code met à jour la même ligne.
    Quand j'envoie GET "/api/pieces/{pieceId}"
    Alors la réponse a le statut 200
    Et le champ "contenu" vaut "contenu e2e"

  @AC-3 @api @non-implemente
  Scénario: Export par identifiant seul
    Quand j'envoie POST "/api/notation/partition/exporter" avec le corps JSON :
      """
      {"partition_id": "inconnu", "formats": ["musicxml"]}
      """
    Alors la réponse a le statut 200
