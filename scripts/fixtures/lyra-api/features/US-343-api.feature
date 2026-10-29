# language: fr
@US-343 @REQ-343 @api
Fonctionnalité: N'écouter que sur la machine locale avec garde des hôtes et origines (US-343)
  # REQ-343 - critères couverts à ce niveau : AC-2, AC-3

  Contexte:
    Soit l'API Lyra joignable

  @AC-2 @api
  Scénario: Host non local : 403 sur /api/jobs
    Quand j'envoie GET "/api/jobs" avec l'en-tête "Host" "evil.example"
    Alors la réponse a le statut 403

  @AC-2 @api
  Scénario: Host non local : 403 sur /internal/jobs
    Quand j'envoie GET "/internal/jobs/00000000-0000-0000-0000-000000000000" avec l'en-tête "Host" "evil.example"
    Alors la réponse a le statut 403

  @AC-2 @api
  Scénario: Origin non local : 403
    Quand j'envoie GET "/api/jobs/00000000-0000-0000-0000-000000000000" avec l'en-tête "Origin" "http://evil.example"
    Alors la réponse a le statut 403

  # Exige de démarrer lyra-ml hors profil dev/test : hors périmètre de la pile en place.
  @AC-3 @api @requiert-profil-strict
  Scénario: lyra-ml sans jeton : 401 sauf /health
    Quand j'envoie POST "/analyze/mode" directement à lyra-ml avec le corps JSON :
      """
      {"accords": "@accords:I"}
      """
    Alors la réponse a le statut 401
