# language: fr
@US-207 @REQ-207 @api
Fonctionnalité: Choisir les mots-rimes avant la génération de paroles en français (US-207)
  # REQ-207 - critères couverts à ce niveau : AC-4, AC-5, AC-6
  # Tous ces scénarios appellent le modèle de langage (Ollama) : absent de la pile.

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api @requiert-ollama @requiert-corpus-indexe
  Scénario: Mode imposé : mots-rimes imposés par groupe
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"la mer\", \"longueur\": 4, \"rimes\": true, \"schema_rimes\": \"AABB\", \"langue\": \"francais\"}"
    Alors la réponse a le statut 200
    Et le champ "mode_rimes" vaut "impose"
    Et la liste "mots_rimes_imposes" contient 2 éléments

  @AC-5 @api @requiert-ollama @requiert-corpus-indexe
  Scénario: Schéma AAB : vers 3 libre
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"la mer\", \"longueur\": 3, \"rimes\": true, \"schema_rimes\": \"AAB\", \"langue\": \"francais\"}"
    Alors la réponse a le statut 200
    Et le champ "vers[0].mot_rime_impose" est non vide
    Et le champ "vers[1].mot_rime_impose" est non vide
    Et le champ "vers[2].mot_rime_impose" est absent ou nul

  @AC-6 @api @requiert-ollama
  Scénario: Retour à la voie de vérification avec avertissement
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"the sea\", \"longueur\": 4, \"rimes\": true, \"langue\": \"anglais\"}"
    Alors le champ "mode_rimes" vaut "verification"
    Et la liste "avertissements" n'est pas vide
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"la mer\", \"longueur\": 4, \"rimes\": false}"
    Alors le champ "mode_rimes" vaut "verification"
