# language: fr
@US-232 @REQ-232 @non-testable
Fonctionnalité: Router une commande par tool-calling interne borné et mesuré (US-232)
  # Aucun scénario exécutable en l'état : voir lot2-3-rapport.md §4

  # AC-1 : Drapeau LYRA_NLU_MCP_ANALYZE_PILOT_ENABLED (application.yml:131, défaut false) : propriété de configuration vérifiable sans scénario métier ; test de config
  # AC-4 : Banc d'essai de précision : dépend d'un modèle, règle de gouvernance (seuil 95 %)
  # AC-5 : Dépend d'un modèle de langage non déterministe (réponse malformée à injecter)
