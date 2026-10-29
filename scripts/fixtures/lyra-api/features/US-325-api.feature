# language: fr
@US-325 @REQ-325 @api @non-implemente
Fonctionnalité: Transcrire un enregistrement audio en partition par instrument avec correction obligatoire (US-325)
  # NON IMPLÉMENTÉ (code) : le job audio_vers_partition est déclaré mais sans contrat de paramètres, GPU et workers absents.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @non-implemente @requiert-gpu @lent
  Scénario: Dépôt d'un enregistrement : tâche suivie
    Quand j'envoie POST "/api/jobs/audio_vers_partition" avec le corps JSON "{\"parametres\": {}}"
    Alors la réponse a le statut 202
