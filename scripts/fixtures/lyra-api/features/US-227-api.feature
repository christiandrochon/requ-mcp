# language: fr
@US-227 @REQ-227 @api @non-implemente
Fonctionnalité: Générer une chanson entière par les règles à partir de partitions sources validées (US-227)
  # REQ-227 - critères couverts à ce niveau : AC-4
  # NON IMPLÉMENTÉ (code) : POST /api/generations (ADR 0133) est absent ; le job « generation_chanson » existe mais accepte tout corps sans contrat de paramètres ni statut 409 PARTITION_NON_VALIDEE.
  # Le scénario ci-dessous porte l'oracle de l'AC-4 (202 + job suivi) ; exclu du profil par @non-implemente.

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api @non-implemente
  Scénario: Génération asynchrone : 202 et job generation_chanson
    Quand j'envoie POST "/api/jobs/generation_chanson" avec le corps JSON :
      """
      {"parametres": {"sources": [], "random_seed": 1}}
      """
    Alors la réponse a le statut 202
    Et l'en-tête "Location" est présent
    Et le champ "type" vaut "generation_chanson"
