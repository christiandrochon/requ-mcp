# language: fr
@US-237 @REQ-237 @api
Fonctionnalité: Calculer un profil de style à partir des retours sur les décisions de génération (US-237)
  # REQ-237 - critères couverts à ce niveau : AC-4, AC-5, AC-6
  # RÉSOLU (code) : aucune route ne renvoie l'id d'une décision : il est lu en SQL (table generation_decision) après une génération. Suppression : DELETE /api/decisions/feedback/{feedbackId} (l'AC cite /api/decisions/{id}/feedback/{feedbackId} : écart d'URL, voir rapport).

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Un rejet incrémente le profil du couple (decision_type, rule_or_model)
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 4, "random_seed": 11}
      """
    Et je mémorise l'identifiant de la dernière décision journalisée sous le nom "decision"
    Et j'envoie GET "/api/decisions/profil-style"
    Et je mémorise le "rejete" du profil de style pour le couple de la décision "decision"
    Et j'envoie POST "/api/decisions/{decision}/feedback" avec le corps JSON "{\"feedback\": \"rejete\"}"
    Alors la réponse a le statut 201
    Quand j'envoie GET "/api/decisions/profil-style"
    Alors le profil de style du couple de la décision "decision" a "rejete" égal à celui mémorisé plus 1

  @AC-5 @api
  Scénario: Suppression d'un retour : profil recalculé
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 4, "random_seed": 12}
      """
    Et je mémorise l'identifiant de la dernière décision journalisée sous le nom "decision"
    Et j'envoie POST "/api/decisions/{decision}/feedback" avec le corps JSON "{\"feedback\": \"rejete\"}"
    Et je mémorise le champ "id" sous le nom "feedbackId"
    Et j'envoie GET "/api/decisions/profil-style"
    Et je mémorise le "rejete" du profil de style pour le couple de la décision "decision"
    Et j'envoie DELETE "/api/decisions/feedback/{feedbackId}"
    Alors la réponse a le statut 204
    Quand j'envoie GET "/api/decisions/profil-style"
    Alors le profil de style du couple de la décision "decision" a "rejete" égal à celui mémorisé plus -1

  @AC-6 @api
  Scénario: Décision inexistante : 404
    Quand j'envoie POST "/api/decisions/00000000-0000-0000-0000-000000000000/feedback" avec le corps JSON "{\"feedback\": \"accepte\"}"
    Alors la réponse a le statut 404

  @AC-6 @api
  Scénario: Valeur de retour invalide : 400
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 4, "random_seed": 13}
      """
    Et je mémorise l'identifiant de la dernière décision journalisée sous le nom "decision"
    Et j'envoie POST "/api/decisions/{decision}/feedback" avec le corps JSON "{\"feedback\": \"peut-etre\"}"
    Alors la réponse a le statut 400
