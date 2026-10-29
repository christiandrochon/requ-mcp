# language: fr
@US-200 @REQ-200 @api
Fonctionnalité: Générer des paroles à partir d'un thème (US-200)
  # REQ-200 - critères couverts à ce niveau : AC-2, AC-4, AC-5, AC-6
  # RÉSOLU (code) : le modèle de paroles passe par Ollama (lyra-ml/app/lyrics/generator.py) ; sans Ollama, scénarios exclus (@requiert-ollama, environnement).

  Contexte:
    Soit l'API Lyra joignable

  @AC-2 @api @requiert-ollama
  Scénario: Chaque vers généré porte son nombre de syllabes compté par Lyra
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"l'automne\", \"longueur\": 4, \"rimes\": true}"
    Alors la réponse a le statut 200
    Et chaque élément de la liste "vers" a un champ numérique "nombre_syllabes"
    Et chaque élément de la liste "vers" a un champ "texte" non vide

  # RÉSOLU (code) : le refus est un 400 { erreurs: [{champ, motif}] } rendu par SecuriteExceptionHandler avant tout appel à lyra-ml.
  @AC-4 @api
  Scénario: Un thème vide est refusé par l'API sans génération
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"\", \"longueur\": 4}"
    Alors la réponse a le statut 400
    Et la liste "erreurs" contient un élément dont "champ" vaut "sujet"
    # NON TESTÉ : « aucun appel au modèle de langage » n'est observable (aucun compteur d'appels Ollama exposé) ; seul le refus 400 avant génération est vérifié.

  @AC-5 @api @requiert-ollama
  Scénario: Longueur N demandée, N vers reçus
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"la mer\", \"longueur\": 6, \"rimes\": false}"
    Alors la réponse a le statut 200
    Et la liste "vers" contient 6 éléments

  # RÉSOLU (code) : rimes=false => mode_rimes "verification" (generator.py:1439) et schema_rimes_respecte None.
  @AC-6 @api @requiert-ollama
  Scénario: Rimes désactivées : pas de schéma de rimes vérifié
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"la mer\", \"longueur\": 4, \"rimes\": false}"
    Alors la réponse a le statut 200
    Et le champ "mode_rimes" vaut "verification"
    Et le champ "schema_rimes_respecte" est absent ou nul
