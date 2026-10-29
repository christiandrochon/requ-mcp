# language: fr
@US-307 @REQ-307 @api
Fonctionnalité: Appliquer des dispositifs compositionnels nommés (classique, électronique, film) (US-307)
  # REQ-307 - critères couverts à ce niveau : AC-1, AC-2, AC-3
  # RÉSOLU (code) : cryptogramme BACH = Si♭ (70), La (69), Do (60), Si (71) — hauteurs à confirmer à l'exécution ; leitmotiv-reseau { nom_racine, motif_racine } puis leitmotiv-derive { reseau, nom, parent, technique } puis leitmotiv-ancetres { reseau, nom }.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: BACH en motif de 4 notes
    Quand j'envoie POST "/api/generate/cryptogramme-motif" avec le corps JSON "{\"texte\": \"BACH\"}"
    Alors la réponse a le statut 200
    Et la liste "motif" contient 4 éléments

  @AC-1 @api
  Scénario: Lettre non musicale ignorée
    Quand j'envoie POST "/api/generate/cryptogramme-motif" avec le corps JSON "{\"texte\": \"BACHZ\"}"
    Alors la réponse a le statut 200
    Et la liste "lettres_ignorees" contient la valeur "Z"

  @AC-2 @api
  Scénario: Ancêtres d'un leitmotiv dérivé jusqu'au motif racine
    Quand j'envoie POST "/api/generate/leitmotiv-reseau" avec le corps JSON :
      """
      {"nom_racine": "heros", "motif_racine": "@notes:60,62,64,67"}
      """
    Alors la réponse a le statut 200
    Quand j'envoie POST "/api/generate/leitmotiv-derive" avec "$" de la réponse précédente sous la clé "reseau" et le corps JSON :
      """
      {"nom": "heros_sombre", "parent": "heros", "technique": "sequence"}
      """
    Alors la réponse a le statut 200
    Quand j'envoie POST "/api/analyze/leitmotiv-ancetres" avec "$" de la réponse précédente sous la clé "reseau" et le corps JSON :
      """
      {"nom": "heros_sombre"}
      """
    Alors la réponse a le statut 200
    Et le corps de la réponse contient "heros"

  @AC-3 @api
  Scénario: Mickey-mousing refusé par défaut
    Quand j'envoie POST "/api/arrange/mickey-mousing-autorise" avec le corps JSON "{\"tags_scene\": []}"
    Alors la réponse a le statut 200
    Et le champ "autorise" vaut false

  @AC-3 @api
  Scénario: Mickey-mousing autorisé pour une scène de dessin animé
    Quand j'envoie POST "/api/arrange/mickey-mousing-autorise" avec le corps JSON "{\"tags_scene\": [\"cartoon\"]}"
    Alors la réponse a le statut 200
    Et le champ "autorise" vaut true
