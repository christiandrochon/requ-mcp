# language: fr
@US-215 @REQ-215 @api
Fonctionnalité: Vérifier une adaptation de paroles français ↔ anglais (syllabes, sens, rimes) (US-215)
  # REQ-215 - critères couverts à ce niveau : AC-4, AC-5, AC-6

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @AC-5 @api @depend-modele-ml @requiert-ollama
  Scénario: Écart de syllabes, similarité de sens, schémas de rimes d'une strophe de 4 vers
    Quand j'envoie POST "/api/lyrics/verifier-adaptation" avec le corps JSON "{\"texte_source\": [\"Une rose blanche\", \"Dans la nuit\", \"Le vent qui passe\", \"Et moi je chante\"], \"texte_adapte\": [\"A white rose\", \"In the night\", \"The wind goes by\", \"And I sing\"], \"langue_source\": \"francais\", \"langue_cible\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et chaque élément de la liste "lignes" a un champ numérique "ecart_syllabes"
    Et le champ "rimes_preservees" est booléen

  @AC-6 @api
  Scénario: Adaptation avec 4 vers sources et 3 vers adaptés refusée
    Quand j'envoie POST "/api/lyrics/verifier-adaptation" avec le corps JSON "{\"texte_source\": [\"a\", \"b\", \"c\", \"d\"], \"texte_adapte\": [\"a\", \"b\", \"c\"], \"langue_source\": \"francais\", \"langue_cible\": \"anglais\"}"
    Alors la requête est refusée par une erreur 4xx

  @AC-6 @api
  Scénario: Adaptation avec des textes vides refusée
    Quand j'envoie POST "/api/lyrics/verifier-adaptation" avec le corps JSON "{\"texte_source\": [], \"texte_adapte\": [], \"langue_source\": \"francais\", \"langue_cible\": \"anglais\"}"
    Alors la requête est refusée par une erreur 4xx
