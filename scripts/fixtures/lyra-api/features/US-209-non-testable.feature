# language: fr
@US-209 @REQ-209 @non-testable
Fonctionnalité: Proposer des mots de registre d'une émotion depuis une source hors ligne (US-209)
  # Aucun scénario exécutable en l'état : voir lot2-3-rapport.md §4

  # AC-1 : Aucune route REST ni écran trouvés pour « mots de registre » (grep dans lyra-api, lyra-ml/app, lyra-ui, seul test_affect_emotions.py y fait référence) ; outil probablement MCP/CLI non localisé : à confirmer avant d'écrire les scénarios
  # AC-3 : Idem AC-1 + environnement sans réseau
  # AC-5 : Idem AC-1 (outil non localisé)
  # AC-6 : Idem AC-1 ; dépend de la source lexicale (étiquettes de registre)
