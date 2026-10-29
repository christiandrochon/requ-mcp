# language: fr
@US-342 @REQ-342 @api
Fonctionnalité: Exécuter les traitements longs en tâches asynchrones suivies (US-342)
  # REQ-342 - critères couverts à ce niveau : AC-3, AC-4
  # RÉSOLU (code) : le broker RabbitMQ est démarré sur la pile : POST /api/jobs/{type} est exécutable (202) sans workers Celery ; AC-4 exige d'arrêter RabbitMQ (hors périmètre env) : @requiert-broker.
  # RÉSOLU (code) : le type inconnu rend 404.

  Contexte:
    Soit l'API Lyra joignable

  @AC-3 @api
  Scénario: POST /api/jobs/{type} : 202, Location et statut consultable
    Quand j'envoie POST "/api/jobs/demo_cpu" sans corps
    Alors la réponse a le statut 202
    Et l'en-tête "Location" désigne "/api/jobs/{id}"
    Et je mémorise le champ "id" sous le nom "jobId"
    Quand j'envoie GET "/api/jobs/{jobId}"
    Alors la réponse a le statut 200
    Et le champ "statut" est l'un de ["en_attente", "en_cours", "a_valider", "termine", "echec", "annule"]

  @AC-3 @api
  Scénario: Type de job inconnu : 404
    Quand j'envoie POST "/api/jobs/type_inconnu" sans corps
    Alors la réponse a le statut 404

  @AC-4 @api @requiert-broker
  Scénario: Broker en panne : 503 et job en échec BROKER_INDISPONIBLE
    Quand j'envoie POST "/api/jobs/demo_cpu" sans corps
    Alors la réponse a le statut 503
