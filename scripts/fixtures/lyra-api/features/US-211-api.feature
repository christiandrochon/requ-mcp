# language: fr
@US-211 @REQ-211 @api
Fonctionnalité: Corriger la grammaire anglaise avec un modèle de langage (étage 2) (US-211)
  # REQ-211 - critères couverts à ce niveau : AC-4, AC-5
  # RÉSOLU (code) : le drapeau LYRA_GRAMMAIRE_LLM_ENABLED est un état de la pile (défaut : désactivé) ; l'état « activé + Ollama arrêté » exige de redémarrer lyra-api (hors périmètre).

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Étage 2 désactivé par défaut
    Quand j'envoie POST "/api/lyrics/grammaire/analyses" avec le corps JSON "{\"texte\": \"She dont know.\", \"langue\": \"anglais\", \"contexte_llm\": true}"
    Alors la réponse a le statut 200
    Et le champ "statut_llm" vaut "desactive"

  @AC-5 @api @requiert-profil-strict
  Scénario: Étage 2 activé, modèle injoignable : statut indisponible
    Quand j'envoie POST "/api/lyrics/grammaire/analyses" avec le corps JSON "{\"texte\": \"She dont know.\", \"langue\": \"anglais\", \"contexte_llm\": true}"
    Alors le champ "statut_llm" vaut "indisponible"
